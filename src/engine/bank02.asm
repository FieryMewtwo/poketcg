_OpenDuelCheckMenu: ; 8000 (2:4000)
	call ResetCheckMenuCursorPositionAndBlink
	xor a
	ld [wce5e], a
	call DrawWideTextBox

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld hl, CheckMenuData
	call PlaceTextItems
.loop
	call DoFrame
	call HandleCheckMenuInput
	jr nc, .loop
	cp $ff
	ret z ; B pressed

; A was pressed
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr _OpenDuelCheckMenu

.jump_table: ; 8031 (2:4031)
	dw DuelCheckMenu_InPlayArea
	dw DuelCheckMenu_Glossary
	dw DuelCheckMenu_YourPlayArea
	dw DuelCheckMenu_OppPlayArea

; opens the In Play Area submenu
DuelCheckMenu_InPlayArea: ; 8039 (2:4039)
	xor a
	ld [wInPlayAreaFromSelectButton], a
	farcall OpenInPlayAreaScreen
	ret

; opens the Glossary submenu
DuelCheckMenu_Glossary: ; 8042 (2:4042)
	farcall OpenGlossaryScreen
	ret

; opens the Your Play Area submenu
DuelCheckMenu_YourPlayArea: ; 8047 (2:4047)
	call ResetCheckMenuCursorPositionAndBlink
	xor a
	ld [wce5e], a
	ldh a, [hWhoseTurn]
.draw
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen

	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld [wYourOrOppPlayAreaLastCursorPosition], a
	ld b, $f8 ; black arrow tile
	call DrawYourOrOppPlayArea_DrawArrows

	call DrawWideTextBox

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld hl, YourPlayAreaMenuData
	call PlaceTextItems

.loop
	call DoFrame
	xor a
	call DrawYourOrOppPlayArea_RefreshArrows
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .loop

	call DrawYourOrOppPlayArea_EraseArrows
	cp $ff
	ret z

	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr .draw

.jump_table ; 8098 (2:4098)
	dw OpenYourOrOppPlayAreaScreen_TurnHolderPlayArea
	dw OpenYourOrOppPlayAreaScreen_TurnHolderHand
	dw OpenYourOrOppPlayAreaScreen_TurnHolderDiscardPile

OpenYourOrOppPlayAreaScreen_TurnHolderPlayArea: ; 809e (2:409e)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderPlayAreaScreen
	pop af
	ldh [hWhoseTurn], a
	ret

OpenYourOrOppPlayAreaScreen_NonTurnHolderPlayArea: ; 80a8 (2:40a8)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderPlayAreaScreen
	pop af
	ldh [hWhoseTurn], a
	ret

OpenYourOrOppPlayAreaScreen_TurnHolderHand: ; 80b2 (2:40b2)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderHandScreen_Simple
	pop af
	ldh [hWhoseTurn], a
	ret

OpenYourOrOppPlayAreaScreen_NonTurnHolderHand: ; 80bc (2:40bc)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderHandScreen_Simple
	pop af
	ldh [hWhoseTurn], a
	ret

OpenYourOrOppPlayAreaScreen_TurnHolderDiscardPile: ; 80c6 (2:40c6)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenTurnHolderDiscardPileScreen
	pop af
	ldh [hWhoseTurn], a
	ret

OpenYourOrOppPlayAreaScreen_NonTurnHolderDiscardPile: ; 80d0 (2:40d0)
	ldh a, [hWhoseTurn]
	push af
	bank1call OpenNonTurnHolderDiscardPileScreen
	pop af
	ldh [hWhoseTurn], a
	ret

; opens the Opp. Play Area submenu
; if clairvoyance is active, add the option to check
; opponent's hand
DuelCheckMenu_OppPlayArea: ; 80da (2:40da)
	call ResetCheckMenuCursorPositionAndBlink
	call IsClairvoyanceActive
	jr c, .clairvoyance1

	ld a, %10000000
	ld [wce5e], a
	jr .begin
.clairvoyance1
	xor a
	ld [wce5e], a

.begin
	ldh a, [hWhoseTurn]
.turns
	ld l, a
	cp PLAYER_TURN
	jr nz, .opponent
	ld a, OPPONENT_TURN
	ld h, a
	jr .cursor
.opponent
	ld a, PLAYER_TURN
	ld h, a

.cursor
	call DrawYourOrOppPlayAreaScreen

; convert cursor position and
; store it in wYourOrOppPlayAreaLastCursorPosition
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	add 3
	ld [wYourOrOppPlayAreaLastCursorPosition], a

; draw black arrows in the Play Area
	ld b, $f8 ; black arrow tile
	call DrawYourOrOppPlayArea_DrawArrows
	call DrawWideTextBox

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

; place text items depending on clairvoyance
; when active, allows to look at opp. hand
	call IsClairvoyanceActive
	jr c, .clairvoyance2
	ld hl, OppPlayAreaMenuData
	call PlaceTextItems
	jr .loop
.clairvoyance2
	ld hl, OppPlayAreaMenuData_WithClairvoyance
	call PlaceTextItems

; handle input
.loop
	call DoFrame
	ld a, 1
	call DrawYourOrOppPlayArea_RefreshArrows
	call HandleCheckMenuInput_YourOrOppPlayArea
	jr nc, .loop
	call DrawYourOrOppPlayArea_EraseArrows
	cp $ff
	ret z ; B was pressed

; A was pressed
; jump to function corresponding to cursor position
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	ld hl, .jump_table
	call JumpToFunctionInTable
	jr .turns

.jump_table
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderPlayArea
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderHand
	dw OpenYourOrOppPlayAreaScreen_NonTurnHolderDiscardPile

CheckMenuData: ; 8158 (2:4158)
	textitem  2, 14, InPlayAreaText
	textitem  2, 16, YourPlayAreaText
	textitem 12, 14, GlossaryText
	textitem 12, 16, OppPlayAreaText
	db $ff

YourPlayAreaMenuData: ; 8169 (2:4169)
	textitem  2, 14, YourPokemonText
	textitem 12, 14, YourHandText
	textitem  2, 16, YourDiscardPileText2
	db $ff

OppPlayAreaMenuData: ; 8176 (2:4176)
	textitem  2, 14, OpponentsPokemonText
	textitem  2, 16, OpponentsDiscardPileText2
	db $ff

OppPlayAreaMenuData_WithClairvoyance: ; 8176 (2:4176)
	textitem  2, 14, OpponentsPokemonText
	textitem 12, 14, OpponentsHandText
	textitem  2, 16, OpponentsDiscardPileText2
	db $ff

; checks if arrows need to be erased in Your Play Area or Opp. Play Area
; and draws new arrows upon cursor position change
; input:
; a = an initial offset applied to the cursor position (used to adjust
; for the different layouts of the Your Play Area and Opp. Play Area screens)
DrawYourOrOppPlayArea_RefreshArrows: ; 818c (2:418c)
	push af
	ld b, a
	add b
	add b
	ld c, a
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld b, a
	ld a, [wCheckMenuCursorXPosition]
	add b
	add c
; a = 2 * cursor ycoord + cursor xcoord + 3*a

; if cursor position is different than
; last position, then update arrows
	ld hl, wYourOrOppPlayAreaLastCursorPosition
	cp [hl]
	jr z, .unchanged

; erase and draw arrows
	call DrawYourOrOppPlayArea_EraseArrows
	ld [wYourOrOppPlayAreaLastCursorPosition], a
	ld b, $f8 ; black arrow tile byte
	call DrawYourOrOppPlayArea_DrawArrows

.unchanged
	pop af
	ret

; write SYM_SPACE to positions tabulated in
; YourOrOppPlayAreaArrowPositions, with offset calculated from the
; cursor x and y positions in [wYourOrOppPlayAreaLastCursorPosition]
; input:
; [wYourOrOppPlayAreaLastCursorPosition]: cursor position (2*y + x)
DrawYourOrOppPlayArea_EraseArrows: ; 81af (2:41af)
	push af
	ld a, [wYourOrOppPlayAreaLastCursorPosition]
	ld b, SYM_SPACE ; white tile
	call DrawYourOrOppPlayArea_DrawArrows
	pop af
	ret

; writes tile in b to positions tabulated in
; YourOrOppPlayAreaArrowPositions, with offset calculated from the
; cursor x and y positions in a
; input:
; a = cursor position (2*y + x)
; b = byte to draw
DrawYourOrOppPlayArea_DrawArrows: ; 81ba (2:41ba)
	push bc
	ld hl, YourOrOppPlayAreaArrowPositions
	sla a
	ld c, a
	ld b, $00
	add hl, bc
; hl points to YourOrOppPlayAreaArrowPositions
; plus offset corresponding to a

; load hl with draw position pointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop de

.loop
	ld a, [hli]
	cp $ff
	jr z, .done
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, d
	call WriteByteToBGMap0
	jr .loop
.done
	ret

YourOrOppPlayAreaArrowPositions: ; 81d7 (2:41d7)
	dw YourOrOppPlayAreaArrowPositions_PlayerPokemon
	dw YourOrOppPlayAreaArrowPositions_PlayerHand
	dw YourOrOppPlayAreaArrowPositions_PlayerDiscardPile
	dw YourOrOppPlayAreaArrowPositions_OpponentPokemon
	dw YourOrOppPlayAreaArrowPositions_OpponentHand
	dw YourOrOppPlayAreaArrowPositions_OpponentDiscardPile

YourOrOppPlayAreaArrowPositions_PlayerPokemon: ; 81e3 (2:41e3)
; x and y coordinates to draw byte
	db  5,  5
	db  0, 10
	db  4, 10
	db  8, 10
	db 12, 10
	db 16, 10
	db $ff

YourOrOppPlayAreaArrowPositions_PlayerHand:
	db 14, 7
	db $ff

YourOrOppPlayAreaArrowPositions_PlayerDiscardPile:
	db 14, 5
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentPokemon:
	db  5, 7
	db  0, 3
	db  4, 3
	db  8, 3
	db 12, 3
	db 16, 3
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentHand:
	db 0, 5
	db $ff

YourOrOppPlayAreaArrowPositions_OpponentDiscardPile:
	db 0, 8
	db $ff

; loads tiles and icons to display Your Play Area / Opp. Play Area screen,
; and draws the screen according to the turn player
; input: h -> [wCheckMenuPlayAreaWhichDuelist] and l -> [wCheckMenuPlayAreaWhichLayout]
DrawYourOrOppPlayAreaScreen: ; 8209 (2:4209)
; loads the turn holders
	ld a, h
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld a, l
	ld [wCheckMenuPlayAreaWhichLayout], a
; fallthrough

; loads tiles and icons to display Your Play Area / Opp. Play Area screen,
; and draws the screen according to the turn player
; input: [wCheckMenuPlayAreaWhichDuelist] and [wCheckMenuPlayAreaWhichLayout]
_DrawYourOrOppPlayAreaScreen: ; 8211 (2:4211)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions

	ld a, $01
	ld [wVBlankOAMCopyToggle], a

	call DoFrame
	call EmptyScreen
	call Set_OBJ_8x8
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp PLAYER_TURN
	jr nz, .opp_turn1

; print <RAMNAME>'s Play Area
	ld de, wDefaultText
	call CopyPlayerName
	jr .get_text_length
.opp_turn1
	ld de, wDefaultText
	call CopyOpponentName
.get_text_length
	ld hl, wDefaultText

	call GetTextLengthInTiles
	ld a, 6 ; max name size in tiles
	sub b
	srl a
	add 4
; a = (6 - name text in tiles) / 2 + 4
	ld d, a ; text horizontal alignment

	ld e, $00
	call InitTextPrinting
	ldtx hl, DuelistsPlayAreaText
	ldh a, [hWhoseTurn]
	cp PLAYER_TURN
	jr nz, .opp_turn2
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp PLAYER_TURN
	jr nz, .swap
.opp_turn2
	call PrintTextNoDelay
	jr .draw
.swap
	call SwapTurn
	call PrintTextNoDelay
	call SwapTurn

.draw
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichLayout]
	cp b
	jr nz, .not_equal

	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.player
	call DrawPlayArea_PrizeCards
	lb de, 6, 2 ; coordinates of player's active card
	call DrawYourOrOppPlayArea_ActiveCardGfx
	lb de, 1, 9 ; coordinates of player's bench cards
	ld c, 4 ; spacing
	call DrawPlayArea_BenchCards
	xor a
	call DrawYourOrOppPlayArea_Icons
	jr .done

.not_equal
	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.opponent
	call DrawPlayArea_PrizeCards
	lb de, 6, 5 ; coordinates of opponent's active card
	call DrawYourOrOppPlayArea_ActiveCardGfx
	lb de, 1, 2 ; coordinates of opponent's bench cards
	ld c, 4 ; spacing
	call DrawPlayArea_BenchCards
	ld a, $01
	call DrawYourOrOppPlayArea_Icons

.done
	call EnableLCD
	ret

Func_82b6: ; 82b6 (2:42b6)
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichLayout]
	cp b
	jr nz, .not_equal

	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.player
	call DrawPlayArea_PrizeCards
	ret

.not_equal
	ld hl, PrizeCardsCoordinateData_YourOrOppPlayArea.opponent
	call DrawPlayArea_PrizeCards
	ret

; loads tiles and icons to display the In Play Area screen,
; and draws the screen
DrawInPlayAreaScreen: ; 82ce (2:42ce)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions

	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call EmptyScreen

	ld a, $0a
	ld [wDuelDisplayedScreen], a
	call Set_OBJ_8x8
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

	lb de, $80, $9f
	call SetupText

; reset turn holders
	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld [wCheckMenuPlayAreaWhichLayout], a

; player prize cards
	ld hl, PrizeCardsCoordinateData_InPlayArea.player
	call DrawPlayArea_PrizeCards

; player bench cards
	lb de, 3, 15
	ld c, 3
	call DrawPlayArea_BenchCards

	ld hl, PlayAreaIconCoordinates.player2
	call DrawInPlayArea_Icons

	call SwapTurn
	ldh a, [hWhoseTurn]
	ld [wCheckMenuPlayAreaWhichDuelist], a
	call SwapTurn

; opponent prize cards
	ld hl, PrizeCardsCoordinateData_InPlayArea.opponent
	call DrawPlayArea_PrizeCards

; opponent bench cards
	lb de, 3, 0
	ld c, 3
	call DrawPlayArea_BenchCards

	call SwapTurn
	ld hl, PlayAreaIconCoordinates.opponent2
	call DrawInPlayArea_Icons

	call SwapTurn
	call DrawInPlayArea_ActiveCardGfx
	ret

; draws players prize cards and bench cards
_DrawPlayersPrizeAndBenchCards: ; 833c (2:433c)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call EmptyScreen
	call LoadSymbolsFont
	call LoadDeckAndDiscardPileIcons

; player cards
	ld a, PLAYER_TURN
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld [wCheckMenuPlayAreaWhichLayout], a
	ld hl, PrizeCardsCoordinateData_2.player
	call DrawPlayArea_PrizeCards
	lb de, 5, 10 ; coordinates
	ld c, 3 ; spacing
	call DrawPlayArea_BenchCards

; opponent cards
	ld a, OPPONENT_TURN
	ld [wCheckMenuPlayAreaWhichDuelist], a
	ld hl, PrizeCardsCoordinateData_2.opponent
	call DrawPlayArea_PrizeCards
	lb de, 1, 0 ; coordinates
	ld c, 3 ; spacing
	call DrawPlayArea_BenchCards
	ret

; draws the active card gfx at coordinates de
; of the player (or opponent) depending on wCheckMenuPlayAreaWhichDuelist
; input:
; de = coordinates
DrawYourOrOppPlayArea_ActiveCardGfx: ; 837e (2:437e)
	push de
	ld a, DUELVARS_ARENA_CARD
	ld l, a
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld a, [hl]
	cp -1
	jr z, .no_pokemon

	ld d, a
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr nz, .swap
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	jr .draw
.swap
	call SwapTurn
	ld a, d
	call LoadCardDataToBuffer1_FromDeckIndex
	call SwapTurn

.draw
	ld de, v0Tiles1 + $20 tiles ; destination offset of loaded gfx
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette
	bank1call FlushAllPalettesOrSendPal23Packet
	pop de

; draw card gfx
	ld a, $a0
	lb hl, 6, 1
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage
	ret

.no_pokemon
	pop de
	ret

; draws player and opponent arena card graphics
; in the "In Play Area" screen
DrawInPlayArea_ActiveCardGfx: ; 83cc (2:43cc)
	xor a
	ld [wArenaCardsInPlayArea], a

	ld a, DUELVARS_ARENA_CARD
	call GetTurnDuelistVariable
	cp -1 ; no pokemon
	jr z, .opponent1

	push af
	ld a, [wArenaCardsInPlayArea]
	or %00000001 ; set the player arena Pokemon bit
	ld [wArenaCardsInPlayArea], a
	pop af

; load card gfx
	call LoadCardDataToBuffer1_FromDeckIndex
	lb de, $8a, $00
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP6OrSGB3ToCardPalette

.opponent1
	ld a, DUELVARS_ARENA_CARD
	call GetNonTurnDuelistVariable
	cp -1 ; no pokemon
	jr z, .draw

	push af
	ld a, [wArenaCardsInPlayArea]
	or %00000010 ; set the opponent arena Pokemon bit
	ld [wArenaCardsInPlayArea], a
	pop af

; load card gfx
	call SwapTurn
	call LoadCardDataToBuffer1_FromDeckIndex
	lb de, $95, $00
	ld hl, wLoadedCard1Gfx
	ld a, [hli]
	ld h, [hl]
	ld l, a
	lb bc, $30, TILE_SIZE
	call LoadCardGfx
	bank1call SetBGP7OrSGB2ToCardPalette
	call SwapTurn

.draw
	ld a, [wArenaCardsInPlayArea]
	or a
	ret z ; no arena cards in play

	bank1call FlushAllPalettesOrSendPal23Packet
	ld a, [wArenaCardsInPlayArea]
	and %00000001 ; test player arena card bit
	jr z, .opponent2

; draw player arena card
	ld a, $a0
	lb de, 6, 9
	lb hl, 6, 1
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP6OrSGB3ToCardImage

.opponent2
	ld a, [wArenaCardsInPlayArea]
	and %00000010 ; test opponent arena card bit
	ret z

; draw opponent arena card
	call SwapTurn
	ld a, $50
	lb de, 6, 2
	lb hl, 6, 1
	lb bc, 8, 6
	call FillRectangle
	bank1call ApplyBGP7OrSGB2ToCardImage
	call SwapTurn
	ret

; draws prize cards depending on the turn
; loaded in wCheckMenuPlayAreaWhichDuelist
; input:
; hl = pointer to coordinates
DrawPlayArea_PrizeCards: ; 8464 (2:4464)
	push hl
	call GetDuelInitialPrizesUpperBitsSet
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld l, DUELVARS_PRIZES
	ld a, [hl]

	pop hl
	ld b, 0
	push af
; loop each prize card
.loop
	inc b
	ld a, [wDuelInitialPrizes]
	inc a
	cp b
	jr z, .done

	pop af
	srl a ; right shift prize cards left
	push af
	jr c, .not_taken
	ld a, $e0 ; tile byte for empty slot
	jr .draw
.not_taken
	ld a, $dc ; tile byte for card
.draw
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl

	push hl
	push bc
	lb hl, $01, $02 ; card tile gfx
	lb bc, 2, 2 ; rectangle size
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, $02 ; blue colour
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.not_cgb
	pop bc
	pop hl
	jr .loop
.done
	pop af
	ret

PrizeCardsCoordinateData_YourOrOppPlayArea: ; 84b4 (2:44b4)
; x and y coordinates for player prize cards
.player
	db 2, 1
	db 2, 3
	db 4, 1
	db 4, 3
	db 6, 1
	db 6, 3
; x and y coordinates for opponent prize cards
.opponent
	db 9, 17
	db 9, 15
	db 7, 17
	db 7, 15
	db 5, 17
	db 5, 15

; used by Func_833c
PrizeCardsCoordinateData_2: ; 84cc (2:44cc)
; x and y coordinates for player prize cards
.player
	db  6, 0
	db  6, 2
	db  8, 0
	db  8, 2
	db 10, 0
	db 10, 2
; x and y coordinates for opponent prize cards
.opponent
	db 4, 18
	db 4, 16
	db 2, 18
	db 2, 16
	db 0, 18
	db 0, 16

PrizeCardsCoordinateData_InPlayArea: ; 84e4 (2:44e4)
; x and y coordinates for player prize cards
.player
	db  9, 1
	db  9, 3
	db 11, 1
	db 11, 3
	db 13, 1
	db 13, 3
; x and y coordinates for opponent prize cards
.opponent
	db 6, 17
	db 6, 15
	db 4, 17
	db 4, 15
	db 2, 17
	db 2, 15

; calculates bits set up to the number of initial prizes, with upper 2 bits set, i.e:
; 6 prizes: a = %11111111
; 4 prizes: a = %11001111
; 3 prizes: a = %11000111
; 2 prizes: a = %11000011
GetDuelInitialPrizesUpperBitsSet: ; 84fc (2:44fc)
	ld a, [wDuelInitialPrizes]
	ld b, $01
.loop
	or a
	jr z, .done
	sla b
	dec a
	jr .loop
.done
	dec b
	ld a, b
	or %11000000
	ld [wDuelInitialPrizesUpperBitsSet], a
	ret

; draws filled and empty bench slots depending on the turn loaded in wCheckMenuPlayAreaWhichDuelist
; if wCheckMenuPlayAreaWhichDuelist is different from wCheckMenuPlayAreaWhichLayout adjusts coordinates of the bench slots
; input:
; de = coordinates to draw bench
; c  = spacing between slots
DrawPlayArea_BenchCards: ; 8511 (2:4511)
	ld a, [wCheckMenuPlayAreaWhichLayout]
	ld b, a
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	cp b
	jr z, .skip

; adjust the starting bench position for opponent
	ld a, d
	add c
	add c
	add c
	add c
	ld d, a
	; d = d + 4 * c

; have the spacing go to the left instead of right
	xor a
	sub c
	ld c, a
	; c = $ff - c + 1

	ld a, [wCheckMenuPlayAreaWhichDuelist]
.skip
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld l, DUELVARS_BENCH1_CARD_STAGE
.loop_1
	dec b ; num of Bench Pokemon left
	jr z, .done

	ld a, [hli]
	push hl
	push bc
	sla a
	sla a
	add $e4
; a holds the correct stage gfx tile
	ld b, a
	push bc

	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	pop bc
	jr nz, .next

	ld a, b
	cp $ec ; tile offset of 2 stage
	jr z, .two_stage
	cp $f0 ; tile offset of 2 stage with no 1 stage
	jr z, .two_stage

	ld a, $02 ; blue colour
	jr .palette
.two_stage
	ld a, $01 ; red colour
.palette
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.next ; adjust coordinates for next card
	pop bc
	pop hl
	ld a, d
	add c
	ld d, a
	; d = d + c
	jr .loop_1

.done
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld h, a
	ld l, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	ld b, [hl]
	ld a, MAX_PLAY_AREA_POKEMON
	sub b
	ret z ; return if already full

	ld b, a
	inc b
.loop_2
	dec b
	ret z

	push bc
	ld a, $f4 ; empty bench slot tile
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb

	ld a, $02 ; colour
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.not_cgb
	pop bc
	ld a, d
	add c
	ld d, a
	jr .loop_2

; draws Your/Opp Play Area icons depending on value in a
; the icons correspond to Deck, Discard Pile, and Hand
; the corresponding number of cards is printed alongside each icon
; for "Hand", text is displayed rather than an icon
; input:
; a = $00: draws player icons
; a = $01: draws opponent icons
DrawYourOrOppPlayArea_Icons: ; 85aa (2:45aa)
	or a
	jr nz, .opponent
	ld hl, PlayAreaIconCoordinates.player1
	jr .draw
.opponent
	ld hl, PlayAreaIconCoordinates.opponent1

.draw
; hand icon and value
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [de]
	ld b, a
	ld a, $d0 ; hand icon, unused?
	call DrawPlayArea_HandText

; deck icon and value
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	ld a, [de]
	ld b, a
	ld a, DECK_SIZE
	sub b
	ld b, a
	ld a, $d4 ; deck icon
	call DrawPlayArea_IconWithValue

; discard pile icon and value
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_DISCARD_PILE
	ld a, [de]
	ld b, a
	ld a, $d8 ; discard pile icon
	call DrawPlayArea_IconWithValue
	ret

; draws the interface icon corresponding to the gfx tile in a
; also prints the number in decimal corresponding to the value in b
; the coordinates in screen are given by [hl]
; input:
; a  = tile for the icon
; b  = value to print alongside icon
; hl = pointer to coordinates
DrawPlayArea_IconWithValue: ; 85e1 (2:45e1)
; drawing the icon
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	push hl
	push bc
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle

	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .skip

	ld a, $02
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0

.skip
; adjust coordinate to the lower right
	inc d
	inc d
	inc e
	call InitTextPrinting
	pop bc
	ld a, b
	call CalculateOnesAndTensDigits

	ld hl, wOnesAndTensPlace
	ld a, [hli]
	ld b, a
	ld a, [hl]

; loading numerical and cross symbols
	ld hl, wDefaultText
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a ; tens place
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a ; ones place
	ld [hl], TX_END

; printing the decimal value
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ret

PlayAreaIconCoordinates: ; 8635 (2:4635)
; used for "Your/Opp. Play Area" screen
.player1
	db 15,  7 ; hand
	db 15,  2 ; deck
	db 15,  4 ; discard pile
.opponent1
	db  1,  5 ; hand
	db  1,  9 ; deck
	db  1,  7 ; discard pile

; used for "In Play Area" screen
.player2
	db 15, 14
	db 15,  9
	db 15, 11
.opponent2
	db  0,  2
	db  0,  6
	db  0,  4

; draws In Play Area icons depending on value in a
; the icons correspond to Deck, Discard Pile, and Hand
; the corresponding number of cards is printed alongside each icon
; for "Hand", text is displayed rather than an icon
; input:
; a = $00: draws player icons
; a = $01: draws opponent icons
DrawInPlayArea_Icons: ; 864d (2:464d)
	ldh a, [hWhoseTurn]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_IN_HAND
	ld a, [de]
	ld b, a
	ld a, $d0 ; hand icon, unused?
	call DrawPlayArea_HandText

; deck
	ldh a, [hWhoseTurn]
	ld d, a
	ld e, DUELVARS_NUMBER_OF_CARDS_NOT_IN_DECK
	ld a, [de]
	ld b, a
	ld a, DECK_SIZE
	sub b
	ld b, a
	ld a, $d4 ; deck tile
	call DrawPlayArea_IconWithValue

; discard pile
	ldh a, [hWhoseTurn]
	ld d, a
	ld e, $ed
	ld a, [de]
	ld b, a
	ld a, $d8 ; discard pile tile
	call DrawPlayArea_IconWithValue
	ret

; prints text HandText_2 and a cross with decimal value of b
; input
; b = value to print alongside text
DrawPlayArea_HandText: ; 8676 (2:4676)
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl

; text
	push hl
	push bc
	call InitTextPrinting
	ldtx hl, HandText_2
	call ProcessTextFromID
	pop bc

; decimal value
	ld a, b
	call CalculateOnesAndTensDigits
	ld hl, wOnesAndTensPlace
	ld a, [hli]
	ld b, a
	ld a, [hl]

	ld hl, wDefaultText
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a
	ld [hl], TX_SYMBOL
	inc hl

; draw to screen
	ld a, b
	ld [hli], a
	ld [hl], TX_END
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ret

; handle player input in menu in Your or Opp. Play Area
; works out which cursor coordinate to go to
; and sets carry flag if A or B are pressed
; returns a =  $1 if A pressed
; returns a = $ff if B pressed
HandleCheckMenuInput_YourOrOppPlayArea: ; 86ac (2:46ac)
	xor a
	ld [wPlaysSfx], a
	ld a, [wCheckMenuCursorXPosition]
	ld d, a
	ld a, [wCheckMenuCursorYPosition]
	ld e, a

; d = cursor x position
; e = cursor y position

	ldh a, [hDPadHeld]
	or a
	jr z, .skip

; pad is pressed
	ld a, [wce5e]
	and %10000000
	ldh a, [hDPadHeld]
	jr nz, .check_vertical
	bit D_LEFT_F, a ; test left button
	jr nz, .horizontal
	bit D_RIGHT_F, a ; test right button
	jr z, .check_vertical

; handle horizontal input
.horizontal
	ld a, [wce5e]
	and %01111111
	or a
	jr nz, .asm_86dd ; jump if wce5e's lower 7 bits aren't set
	ld a, e
	or a
	jr z, .flip_x ; jump if y is 0

; wce5e = %10000000
; e = 1
	dec e ; change y position
	jr .flip_x

.asm_86dd
	ld a, e
	or a
	jr nz, .flip_x ; jump if y is not 0
	inc e ; change y position
.flip_x
	ld a, d
	xor $01 ; flip x position
	ld d, a
	jr .erase

.check_vertical
	bit D_UP_F, a
	jr nz, .vertical
	bit D_DOWN_F, a
	jr z, .skip

; handle vertical input
.vertical
	ld a, d
	or a
	jr z, .flip_y ; jump if x is 0
	dec d
.flip_y
	ld a, e
	xor $01 ; flip y position
	ld e, a

.erase
	ld a, $01
	ld [wPlaysSfx], a
	push de
	call EraseCheckMenuCursor_YourOrOppPlayArea
	pop de

; update x and y cursor positions
	ld a, d
	ld [wCheckMenuCursorXPosition], a
	ld a, e
	ld [wCheckMenuCursorYPosition], a

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a

.skip
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .sfx
	and A_BUTTON
	jr nz, .a_pressed

; B pressed
	ld a, $ff ; cancel
	call PlaySFXConfirmOrCancel
	scf
	ret

.a_pressed
	call DisplayCheckMenuCursor_YourOrOppPlayArea
	ld a, $01
	call PlaySFXConfirmOrCancel
	scf
	ret

.sfx
	ld a, [wPlaysSfx]
	or a
	jr z, .draw_cursor
	call PlaySFX

.draw_cursor
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and %00001111
	ret nz ; only update cursor if blink's lower nibble is 0

	ld a, SYM_CURSOR_R ; cursor byte
	bit 4, [hl] ; only draw cursor if blink counter's fourth bit is not set
	jr z, DrawCheckMenuCursor_YourOrOppPlayArea
; fallthrough

; transforms cursor position into coordinates
; in order to draw byte on menu cursor
EraseCheckMenuCursor_YourOrOppPlayArea: ; 8741 (2:4741)
	ld a, SYM_SPACE ; white tile
; fallthrough

; draws in the cursor position
; input:
; a = tile byte to draw
DrawCheckMenuCursor_YourOrOppPlayArea: ; 8743 (2:4743)
	ld e, a
	ld a, 10
	ld l, a
	ld a, [wCheckMenuCursorXPosition]
	ld h, a
	call HtimesL
; h = 10 * cursor x pos

	ld a, l
	add 1
	ld b, a
	ld a, [wCheckMenuCursorYPosition]
	sla a
	add 14
	ld c, a
; c = 11 + 2 * cursor y pos + 14

; draw tile loaded in e
	ld a, e
	call WriteByteToBGMap0
	or a
	ret

DisplayCheckMenuCursor_YourOrOppPlayArea: ; 8760 (2:4760)
	ld a, SYM_CURSOR_R ; load cursor byte
	jr DrawCheckMenuCursor_YourOrOppPlayArea

; seems to be function to deal with the Peek menu
; to select a prize card to view
Func_8764: ; 8764 (2:4764)
	call Set_OBJ_8x8
	call LoadCursorTile
; reset ce5c and ce56
	xor a
	ld [wce5c], a
	ld [wce56], a

; draw play area screen for the turn player
	ldh a, [hWhoseTurn]
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen

.swap
	ld a, [wce56]
	or a
	jr z, .draw_menu
; if ce56 != 0, swap turn
	call SwapTurn
	xor a
	ld [wce56], a

.draw_menu
	xor a
	ld hl, PlayAreaMenuParameters
	call InitializeMenuParameters
	call DrawWideTextBox

	ld hl, YourOrOppPlayAreaData
	call PlaceTextItems

.loop_1
	call DoFrame
	call HandleMenuInput ; await input
	jr nc, .loop_1
	cp $ff
	jr z, .loop_1

	call EraseCursor
	ldh a, [hCurMenuItem]
	or a
	jp nz, Func_8883 ; jump if not first option

; hCurMenuItem = 0
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr z, .text

; switch the play area to draw
	ld h, a
	ld l, a
	call DrawYourOrOppPlayAreaScreen
	xor a
	ld [wce56], a

.text
	call DrawWideTextBox
	lb de, 1, 14
	call InitTextPrinting
	ldtx hl, WhichCardWouldYouLikeToSeeText
	call ProcessTextFromID

	xor a
	ld [wPrizeCardCursorPosition], a
	ld de, Func_8764_TransitionTable
	ld hl, wce53
	ld [hl], e
	inc hl
	ld [hl], d

.loop_2
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call Func_89ae
	jr c, .asm_87e7
	jr .loop_2
.asm_87e7
	cp $ff
	jr nz, .asm_87f0
	call ZeroObjectPositionsWithCopyToggleOn
	jr .swap
.asm_87f0
	ld hl, .asm_87f8
	call JumpToFunctionInTable
	jr .loop_2

.asm_87f8
rept 6
	dw Func_8819
endr
	dw Func_883c
	dw Func_8849

YourOrOppPlayAreaData: ; 8808 (2:4808)
	textitem 2, 14, YourPlayAreaText
	textitem 2, 16, OppPlayAreaText
	db $ff

PlayAreaMenuParameters: ; 8811 (2:4811)
	db 1, 14 ; cursor x, cursor y
	db 2 ; y displacement between items
	db 2 ; number of items
	db SYM_CURSOR_R ; cursor tile number
	db SYM_SPACE ; tile behind cursor
	dw NULL ; function pointer if non-0

Func_8819: ; 8819 (2:4819)
	ld a, [wPrizeCardCursorPosition]
	ld c, a
	ld b, $01

; left-shift b a number of times
; corresponding to this prize card
.loop
	or a
	jr z, .asm_8827
	sla b
	dec a
	jr .loop

.asm_8827
	ld a, DUELVARS_PRIZES
	call GetTurnDuelistVariable
	and b
	ret z ; return if prize card taken

	ld a, c
	add $40
	ld [wce5c], a
	ld a, c
	add DUELVARS_PRIZE_CARDS
	call GetTurnDuelistVariable
	jr Func_8855

Func_883c: ; 883c (2:483c)
	call CreateHandCardList
	ret c
	ld hl, wDuelTempList
	call ShuffleCards
	ld a, [hl]
	jr Func_8855

Func_8849: ; 8849 (2:4849)
	call CreateDeckCardList
	ret c
	ld a, %01111111
	ld [wce5c], a
	ld a, [wDuelTempList]
; fallthrough

; input:
; a = deck index of card to be loaded
; output:
; a = ce5c
; with upper bit set if turn was swapped
Func_8855: ; 8855 (2:4855)
	ld b, a
	ld a, [wce5c]
	or a
	jr nz, .display
	ld a, b
	ld [wce5c], a
.display
	ld a, b
	call LoadCardDataToBuffer1_FromDeckIndex
	call Set_OBJ_8x16
	bank1call OpenCardPage_FromHand
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	pop af

; if ce56 != 0, swap turn
	ld a, [wce56]
	or a
	jr z, .dont_swap
	call SwapTurn
	ld a, [wce5c]
	or %10000000
	ret
.dont_swap
	ld a, [wce5c]
	ret

Func_8883: ; 8883 (2:4883)
	ld a, [wCheckMenuPlayAreaWhichDuelist]
	ld b, a
	ldh a, [hWhoseTurn]
	cp b
	jr nz, .text

	ld l, a
	cp PLAYER_TURN
	jr nz, .opponent
	ld a, OPPONENT_TURN
	jr .draw
.opponent
	ld a, PLAYER_TURN

.draw
	ld h, a
	call DrawYourOrOppPlayAreaScreen

.text
	call DrawWideTextBox
	lb de, 1, 14
	call InitTextPrinting
	ldtx hl, WhichCardWouldYouLikeToSeeText
	call ProcessTextFromID

	xor a
	ld [wPrizeCardCursorPosition], a
	ld de, Func_8883_TransitionTable
	ld hl, wce53
	ld [hl], e
	inc hl
	ld [hl], d

	call SwapTurn
	ld a, $01
	ld [wce56], a
	jp Func_8764.loop_2

Func_8764_TransitionTable: ; 88c2 (2:48c2)
	cursor_transition $08, $28, $00, $04, $02, $01, $07
	cursor_transition $30, $28, $20, $05, $03, $07, $00
	cursor_transition $08, $38, $00, $00, $04, $03, $07
	cursor_transition $30, $38, $20, $01, $05, $07, $02
	cursor_transition $08, $48, $00, $02, $00, $05, $07
	cursor_transition $30, $48, $20, $03, $01, $07, $04
	cursor_transition $78, $50, $00, $07, $07, $00, $01
	cursor_transition $78, $28, $00, $07, $07, $00, $01

Func_8883_TransitionTable: ; 88fa (2:48fa)
	cursor_transition $a0, $60, $20, $02, $04, $07, $01
	cursor_transition $78, $60, $00, $03, $05, $00, $07
	cursor_transition $a0, $50, $20, $04, $00, $06, $03
	cursor_transition $78, $50, $00, $05, $01, $02, $06
	cursor_transition $a0, $40, $20, $00, $02, $06, $05
	cursor_transition $78, $40, $00, $01, $03, $04, $06
	cursor_transition $08, $38, $00, $07, $07, $05, $04
	cursor_transition $08, $60, $00, $06, $06, $01, $00

Func_8932: ; 8932 (2:4932)
	INCROM $8932, $8992

LoadCursorTile: ; 8992 (2:4992)
	ld de, v0Tiles0
	ld hl, .tile_data
	ld b, 16
	call SafeCopyDataHLtoDE
	ret

.tile_data: ; 899e (2:499e)
	db $e0, $c0, $98, $b0, $84, $8c, $83, $82
	db $86, $8f, $9d, $be, $f4, $f8, $50, $60

; similar to OpenInPlayAreaScreen_HandleInput
Func_89ae: ; 89ae (2:49ae)
	xor a
	ld [wPlaysSfx], a

	ld hl, wce53
	ld e, [hl]
	inc hl
	ld d, [hl]

	ld a, [wPrizeCardCursorPosition]
	ld [wPrizeCardCursorTemporaryPosition], a
	ld l, a
	ld h, 7
	call HtimesL
	add hl, de
; hl = [wce53] + 7 * wce52

	ldh a, [hDPadHeld]
	or a
	jp z, .check_button
	inc hl
	inc hl
	inc hl

	bit D_UP_F, a
	jr z, .else_if_down

	; up
	ld a, [hl]
	jr .process_dpad

.else_if_down
	inc hl
	bit D_DOWN_F, a
	jr z, .else_if_right

	; down
	ld a, [hl]
	jr .process_dpad

.else_if_right
	inc hl
	bit D_RIGHT_F, a
	jr z, .else_if_left

	; right
	ld a, [hl]
	jr .process_dpad

.else_if_left
	inc hl
	bit D_LEFT_F, a
	jr z, .check_button

	; left
	ld a, [hl]
.process_dpad
	ld [wPrizeCardCursorPosition], a
	cp $08 ; if a >= 0x8
	jr nc, .next
	ld b, $01

; this loop equals to
; b = (1 << a)
.make_bitmask_loop
	or a
	jr z, .make_bitmask_done
	sla b
	dec a
	jr .make_bitmask_loop

.make_bitmask_done
; check if the moved cursor refers to an existing item.
; it's always true when this function was called from the glossary procedure.
	ld a, [wDuelInitialPrizesUpperBitsSet]
	and b
	jr nz, .next

; when no cards exist at the cursor,
	ld a, [wPrizeCardCursorTemporaryPosition]
	cp $06
	jr nz, Func_89ae
	; move once more in the direction (recursively) until it reaches an existing item.

; check if one of the dpad, left or right, is pressed.
; if not, just go back to the start.
	ldh a, [hDPadHeld]
	bit D_RIGHT_F, a
	jr nz, .left_or_right
	bit D_LEFT_F, a
	jr z, Func_89ae

.left_or_right
	ld a, [wDuelInitialPrizes]
	cp $05
	jr nc, .next
	ld a, [wPrizeCardCursorPosition]
	cp $05
	jr nz, .asm_8a28
	ld a, $03
	ld [wPrizeCardCursorPosition], a
	jr .asm_8a2d

.asm_8a28
	ld a, $02
	ld [wPrizeCardCursorPosition], a
.asm_8a2d
	ld a, [wDuelInitialPrizes]
	cp $03
	jr nc, .asm_8a3c
	ld a, [wPrizeCardCursorPosition]
	sub $02
	ld [wPrizeCardCursorPosition], a
.asm_8a3c
	ld a, [wPrizeCardCursorPosition]
	ld [wPrizeCardCursorTemporaryPosition], a
	ld b, $01
	jr .make_bitmask_loop

.next
	ld a, $01
	ld [wPlaysSfx], a

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
.check_button
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .return

	and A_BUTTON
	jr nz, .a_button

	ld a, -1 ; cancel
	call PlaySFXConfirmOrCancel
	scf
	ret

.a_button
	call .draw_cursor
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wPrizeCardCursorPosition]
	scf
	ret

.return
	ld a, [wPlaysSfx]
	or a
	jr z, .skip_sfx
	call PlaySFX
.skip_sfx
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and (1 << 4) - 1
	ret nz
	bit 4, [hl]
	jr nz, ZeroObjectPositionsWithCopyToggleOn

.draw_cursor
	call ZeroObjectPositions
	ld hl, wce53
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [wPrizeCardCursorPosition]
	ld l, a
	ld h, 7
	call HtimesL
	add hl, de
; hl = [wce53] + 7 * wce52

	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
	ld b, [hl]
	ld c, $00
	call SetOneObjectAttributes
	or a
	ret

ZeroObjectPositionsWithCopyToggleOn: ; 8aa1 (2:4aa1)
	call ZeroObjectPositions

	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	ret

Func_8aaa: ; 8aaa (2:4aaa)
	INCROM $8aaa, $8b85

Func_8b85: ; 8b85 (2:4b85)
	INCROM $8b85, $8c8e

OpenGlossaryScreen_TransitionTable:
	cursor_transition $08, $28, $00, $04, $01, $05, $05
	cursor_transition $08, $38, $00, $00, $02, $06, $06
	cursor_transition $08, $48, $00, $01, $03, $07, $07
	cursor_transition $08, $58, $00, $02, $04, $08, $08
	cursor_transition $08, $68, $00, $03, $00, $09, $09
	cursor_transition $58, $28, $00, $09, $06, $00, $00
	cursor_transition $58, $38, $00, $05, $07, $01, $01
	cursor_transition $58, $48, $00, $06, $08, $02, $02
	cursor_transition $58, $58, $00, $07, $09, $03, $03
	cursor_transition $58, $68, $00, $08, $05, $04, $04

; copies DECK_SIZE number of cards from de to hl in SRAM
Func_8cd4: ; 8cd4 (2:4cd4)
	push bc
	call EnableSRAM
	ld b, DECK_SIZE
.loop
	ld a, [de]
	inc de
	ld [hli], a
	dec b
	jr nz, .loop
	xor a
	ld [hl], a
	call DisableSRAM
	pop bc
	ret
; 0x8ce7

Func_8ce7: ; 8ce7 (2:4ce7)
	xor a
	ld hl, wceda
	ld bc, DECK_SIZE
	add hl, bc
	ld [hl], a ; wcf16
	ld hl, wcf17
	ld bc, $50
	add hl, bc
	ld [hl], a
	ret
; 0x8cf9

Func_8cf9: ; 8cf9 (2:4cf9)
	call EnableSRAM
	xor a
	ld hl, sb703
	ld [hli], a
	inc a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [sb701], a
	call DisableSRAM
;	fallthrough

; loads the Hard Cards icon gfx to v0Tiles2
LoadHandCardsIcon: ; 8d0b (2:4d0b)
	ld hl, HandCardsGfx
	ld de, v0Tiles2 + $38 tiles
	call CopyListFromHLToDE
	ret

HandCardsGfx: ; 8d15 (2:4d15)
	INCBIN "gfx/hand_cards.2bpp"
	db $00 ; end of data

Func_8d56: ; 8d56 (2:4d56)
	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	call ZeroObjectPositions
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call LoadHandCardsIcon
	bank1call SetDefaultPalettes
	lb de, $3c, $bf
	call SetupText
	ret
; 0x8d78

; empties screen, zeroes object positions,
; loads cursor tile, symbol fonts, duel card symbols
; hand card icon and sets default palettes
Func_8d78: ; 8d78 (2:4d78)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call LoadCursorTile
	call LoadSymbolsFont
	call LoadDuelCardSymbolTiles
	call LoadHandCardsIcon
	bank1call SetDefaultPalettes
	lb de, $3c, $bf
	call SetupText
	ret
; 0x8d9d

; copies 7 bytes from hl to wcfd1
Func_8d9d: ; 8d9d (2:4d9d)
	ld de, wcfd1
	ld b, $7
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	ret

Data_8da9: ; 8da9 (2:4da9)
	db $50, $04, $01
	dw HandleDeckConfigurationMenu
	dw DeckConfigurationMenu_TransitionTable

	INCROM $8db0, $8db0

Func_8db0: ; 8db0 (2:4db0)
	ld hl, Data_8da9
	call Func_8d9d
	ld a, $ff
	call Func_9168
	xor a

Func_8dbc: ; 8dbc (2:4dbc)
	ld hl, Unknown_8de2
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
.asm_8dc8
	call DoFrame
	jr c, Func_8dbc
	call Func_8dea
	jr c, Func_8dbc
	call HandleMenuInput
	jr nc, .asm_8dc8
	ldh a, [hCurMenuItem]
	cp $ff
	ret z
	ld [wceb1], a
	jp Func_8e42

Unknown_8de2: ; 8de2 (2:4de2)
	INCROM $8de2, $8dea

Func_8dea: ; 8dea (2:4dea)
	ldh a, [hDPadHeld]
	and START
	ret z
	ld a, [wCurMenuItem]
	ld [wceb1], a
	call Func_8ff2
	jp nc, Func_8e05
	ld a, $ff ; cancel
	call PlaySFXConfirmOrCancel
	call Func_8fe8
	scf
	ret

Func_8e05: ; 8e05 (2:4e05)
	ld a, $1
	call PlaySFXConfirmOrCancel
	call GetPointerToDeckCards
	push hl
	call GetPointerToDeckName
	pop de
	call Func_8e1f
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	scf
	ret

; copies deck in hl to wcfb9
; copies deck in de to wcf17
Func_8e1f: ; 8e1f (2:4e1f)
	push de
	ld de, wcfb9
	call CopyListFromHLToDEInSRAM
	pop de
	ld hl, wcf17
	call Func_8cd4
	ld a, 9
	ld hl, wcebb
	call ClearNBytesFromHL
	ld a, DECK_SIZE
	ld [wcecc], a
	ld hl, wcebb
	ld [hl], a
	call Func_9e41
	ret

Func_8e42: ; 8e42 (2:4e42)
	call DrawWideTextBox
	ld hl, Unknown_9027
	call PlaceTextItems
	call ResetCheckMenuCursorPositionAndBlink
.asm_8e4e
	call DoFrame
	call HandleCheckMenuInput
	jp nc, .asm_8e4e
	cp $ff
	jr nz, .asm_8e64
	call EraseCheckMenuCursor
	ld a, [wceb1]
	jp Func_8dbc
.asm_8e64
	ld a, [wCheckMenuCursorXPosition]
	or a
	jp nz, Func_8f8a
	ld a, [wCheckMenuCursorYPosition]
	or a
	jp nz, .asm_8ecf
	call GetPointerToDeckCards
	ld e, l
	ld d, h
	ld hl, wcf17
	call Func_8cd4
	ld a, 20
	ld hl, wcfb9
	call ClearNBytesFromHL
	ld de, wcfb9
	call GetPointerToDeckName
	call CopyListFromHLToDEInSRAM
	call Func_9345
	jr nc, .asm_8ec4
	call EnableSRAM
	ld hl, wcf17
	call Func_910a
	call GetPointerToDeckCards
	call Func_9152
	ld e, l
	ld d, h
	ld hl, wcf17
	ld b, $3c
.asm_8ea9
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .asm_8ea9
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wcfb9
	call CopyListFromHLToDE
	call GetPointerToDeckName
	ld a, [hl]
	call DisableSRAM
	or a
	jr z, .asm_8edb
.asm_8ec4
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	jp Func_8dbc
.asm_8ecf
	call Func_8ff2
	jp nc, .asm_8edb
	call Func_8fe8
	jp Func_8dbc
.asm_8edb
	ld a, 20
	ld hl, wcfb9
	call ClearNBytesFromHL
	ld de, wcfb9
	call GetPointerToDeckName
	call CopyListFromHLToDEInSRAM
	call Func_8f05
	call GetPointerToDeckName
	ld d, h
	ld e, l
	ld hl, wcfb9
	call CopyListFromHLToDEInSRAM
	ld a, $ff
	call Func_9168
	ld a, [wceb1]
	jp Func_8dbc

Func_8f05: ; 8f05 (2:4f05)
	ld a, [wceb1]
	or a
	jr nz, .asm_8f10
	; it refers to a data in the other bank without any bank desc.
	ld hl, Deck1Data
	jr .asm_8f23
.asm_8f10
	dec a
	jr nz, .asm_8f18
	ld hl, Deck2Data
	jr .asm_8f23
.asm_8f18
	dec a
	jr nz, .asm_8f20
	ld hl, Deck3Data
	jr .asm_8f23
.asm_8f20
	ld hl, Deck4Data
.asm_8f23
	ld a, MAX_DECK_NAME_LENGTH
	lb bc, 4, 1
	ld de, wcfb9
	farcall InputDeckName
	ld a, [wcfb9]
	or a
	ret nz
	call Func_8f38
	ret

Func_8f38: ; 8f38 (2:4f38)
	ld hl, sb701
	call EnableSRAM
	ld a, [hli]
	ld h, [hl]
	call DisableSRAM
	ld l, a
	ld de, wDefaultText
	call TwoByteNumberToText
	ld hl, wcfb9
	ld [hl], $6
	inc hl
	ld [hl], $44
	inc hl
	ld [hl], $65
	inc hl
	ld [hl], $63
	inc hl
	ld [hl], $6b
	inc hl
	ld [hl], $20
	inc hl
	ld de, wc592
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hli], a
	xor a
	ld [hl], a
	ld hl, sb701
	call EnableSRAM
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, $3
	cp d
	jr nz, .asm_8f82
	ld a, $e7
	cp e
	jr nz, .asm_8f82
	ld de, $0000
.asm_8f82
	inc de
	ld [hl], d
	dec hl
	ld [hl], e
	call DisableSRAM
	ret

Func_8f8a: ; 8f8a (2:4f8a)
	ld a, [wCheckMenuCursorYPosition]
	or a
	jp nz, Func_9026
	call Func_8ff2
	jp nc, Func_8f9d
	call Func_8fe8
	jp Func_8dbc

Func_8f9d: ; 8f9d (2:4f9d)
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM
	ld h, $3
	ld l, a
	call HtimesL
	ld e, l
	inc e
	ld d, 2
	xor a
	lb hl, 0, 0
	lb bc, 2, 2
	call FillRectangle
	ld a, [wceb1]
	call EnableSRAM
	ld [sCurrentlySelectedDeck], a
	call DisableSRAM
	call DrawHandCardsTileOnSelectedDeck
	call GetPointerToDeckName
	call EnableSRAM
	call Func_9253
	call DisableSRAM
	xor a
	ld [wTxRam2], a
	ld [wTxRam2 + 1], a
	ldtx hl, ChosenAsDuelingDeckText
	call DrawWideTextBox_WaitForInput
	ld a, [wceb1]
	jp Func_8dbc

Func_8fe8: ; 8fe8 (2:4fe8)
	ldtx hl, ThereIsNoDeckHereText
	call DrawWideTextBox_WaitForInput
	ld a, [wceb1]
	ret

Func_8ff2: ; 8ff2 (2:4ff2)
	ld a, [wceb1]
	ld hl, wceb2
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	or a
	ret nz
	scf
	ret
; 0x9001

	INCROM $9001, $9026

Func_9026: ; 9026 (2:5026)
	ret

Unknown_9027: ; 9027 (2:5027)
	INCROM $9027, $9038

; return, in hl, the pointer to sDeckXName where X is [wceb1] + 1
GetPointerToDeckName: ; 9038 (2:5038)
	ld a, [wceb1]
	ld h, a
	ld l, sDeck2Name - sDeck1Name
	call HtimesL
	push de
	ld de, sDeck1Name
	add hl, de
	pop de
	ret

; return, in hl, the pointer to sDeckXCards where X is [wceb1] + 1
GetPointerToDeckCards: ; 9048 (2:5048)
	push af
	ld a, [wceb1]
	ld h, a
	ld l, sDeck2Cards - sDeck1Cards
	call HtimesL
	push de
	ld de, sDeck1Cards
	add hl, de
	pop de
	pop af
	ret

ResetCheckMenuCursorPositionAndBlink: ; 905a (2:505a)
	xor a
	ld [wCheckMenuCursorXPosition], a
	ld [wCheckMenuCursorYPosition], a
	ld [wCheckMenuCursorBlinkCounter], a
	ret

; handle player input in check menu
; works out which cursor coordinate to go to
; and sets carry flag if A or B are pressed
; returns a =  $1 if A pressed
; returns a = $ff if B pressed
HandleCheckMenuInput: ; 9065 (2:5065)
	xor a
	ld [wPlaysSfx], a
	ld a, [wCheckMenuCursorXPosition]
	ld d, a
	ld a, [wCheckMenuCursorYPosition]
	ld e, a

; d = cursor x position
; e = cursor y position

	ldh a, [hDPadHeld]
	or a
	jr z, .no_pad
	bit D_LEFT_F, a
	jr nz, .horizontal
	bit D_RIGHT_F, a
	jr z, .check_vertical

; handle horizontal input
.horizontal
	ld a, d
	xor $1 ; flips x coordinate
	ld d, a
	jr .okay
.check_vertical
	bit D_UP_F, a
	jr nz, .vertical
	bit D_DOWN_F, a
	jr z, .no_pad

; handle vertical input
.vertical
	ld a, e
	xor $01 ; flips y coordinate
	ld e, a

.okay
	ld a, $01
	ld [wPlaysSfx], a
	push de
	call EraseCheckMenuCursor
	pop de

; update x and y cursor positions
	ld a, d
	ld [wCheckMenuCursorXPosition], a
	ld a, e
	ld [wCheckMenuCursorYPosition], a

; reset cursor blink
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
.no_pad
	ldh a, [hKeysPressed]
	and A_BUTTON | B_BUTTON
	jr z, .no_input
	and A_BUTTON
	jr nz, .a_press
	ld a, $ff ; cancel
	call PlaySFXConfirmOrCancel
	scf
	ret

.a_press
	call DisplayCheckMenuCursor
	ld a, $01
	call PlaySFXConfirmOrCancel
	scf
	ret

.no_input
	ld a, [wPlaysSfx]
	or a
	jr z, .check_blink
	call PlaySFX

.check_blink
	ld hl, wCheckMenuCursorBlinkCounter
	ld a, [hl]
	inc [hl]
	and %00001111
	ret nz  ; only update cursor if blink's lower nibble is 0

	ld a, SYM_CURSOR_R ; cursor byte
	bit 4, [hl] ; only draw cursor if blink counter's fourth bit is not set
	jr z, DrawCheckMenuCursor

; draws in the cursor position
EraseCheckMenuCursor: ; 90d8 (2:50d8)
	ld a, SYM_SPACE ; empty cursor
; fallthrough

; draws in the cursor position
; input:
; a = tile byte to draw
DrawCheckMenuCursor: ; 90da (2:50da)
	ld e, a
	ld a, 10
	ld l, a
	ld a, [wCheckMenuCursorXPosition]
	ld h, a
	call HtimesL

	ld a, l
	add 1
	ld b, a
	ld a, [wCheckMenuCursorYPosition]
	sla a
	add 14
	ld c, a

	ld a, e
	call WriteByteToBGMap0
	or a
	ret

DisplayCheckMenuCursor: ; 90f7 (2:50f7)
	ld a, SYM_CURSOR_R
	jr DrawCheckMenuCursor

; plays sound depending on value in a
; input:
; a  = $ff: play cancel sound
; a != $ff: play confirm sound
PlaySFXConfirmOrCancel: ; 90fb (2:50fb)
	push af
	inc a
	jr z, .asm_9103
	ld a, SFX_02 ; confirmation sfx
	jr .asm_9105
.asm_9103
	ld a, SFX_03 ; cancellation sfx
.asm_9105
	call PlaySFX
	pop af
	ret

Func_910a: ; 910a (2:510a)
	push hl
	ld b, $0
	ld d, $3c
.asm_910f
	ld a, [hli]
	or a
	jr z, .asm_911e
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	dec [hl]
	pop hl
	dec d
	jr nz, .asm_910f
.asm_911e
	pop hl
	ret
; 0x9120

Func_9120: ; 9120 (2:5120)
	push hl
	ld b, $00
	ld d, DECK_SIZE
.asm_9125
	ld a, [hli]
	or a
	jr z, .done
	ld c, a
	push hl
	push de
	push bc
	ld a, $ff
	call Func_a3ca
	pop bc
	pop de
	ld hl, wTempCardCollection
	add hl, bc
	ld a, [hl]
	cp $63
	jr z, .asm_914c
	call EnableSRAM
	ld hl, sCardCollection
	add hl, bc
	ld a, [hl]
	cp $80
	jr nz, .asm_914b
	xor a
	ld [hl], a
.asm_914b
	inc [hl]
.asm_914c
	pop hl
	dec d
	jr nz, .asm_9125
.done
	pop hl
	ret
; 0x9152

Func_9152: ; 9152 (2:5152)
	push hl
	ld b, $0
	ld d, DECK_SIZE
.asm_9157
	ld a, [hli]
	or a
	jr z, .asm_9166
	ld c, a
	push hl
	ld hl, sCardCollection
	add hl, bc
	inc [hl]
	pop hl
	dec d
	jr nz, .asm_9157
.asm_9166
	pop hl
	ret

Func_9168: ; 9168 (2:5168)
	ld [hffb5], a
	call Func_8d56
	lb de, 0,  0
	lb bc, 20, 4
	call DrawRegularTextBox
	lb de, 0,  3
	lb bc, 20, 4
	call DrawRegularTextBox
	lb de, 0,  6
	lb bc, 20, 4
	call DrawRegularTextBox
	lb de, 0,  9
	lb bc, 20, 4
	call DrawRegularTextBox
	ld hl, Unknown_9242
	call PlaceTextItems
	ld a, 4
	ld hl, wceb2
	call ClearNBytesFromHL
	ld a, [hffb5] ; should be ldh
	bit 0, a
	jr z, .asm_91b0
	ld hl, sDeck1Name
	lb de, 6, 2
	call Func_926e
.asm_91b0
	ld hl, sDeck1Cards
	call Func_9314
	jr c, .asm_91bd
	ld a, $1
	ld [wceb2], a
.asm_91bd
	ld a, [hffb5] ; should be ldh
	bit 1, a
	jr z, .asm_91cd
	ld hl, sDeck2Name
	lb de, 6, 5
	call Func_926e
.asm_91cd
	ld hl, sDeck2Cards
	call Func_9314
	jr c, .asm_91da
	ld a, $1
	ld [wceb3], a
.asm_91da
	ld a, [hffb5] ; should be ldh
	bit 2, a
	jr z, .asm_91ea
	ld hl, sDeck3Name
	lb de, 6, 8
	call Func_926e
.asm_91ea
	ld hl, sDeck3Cards
	call Func_9314
	jr c, .asm_91f7
	ld a, $1
	ld [wceb4], a
.asm_91f7
	ld a, [hffb5] ; should be ldh
	bit 3, a
	jr z, .asm_9207
	ld hl, sDeck4Name
	lb de, 6, 11
	call Func_926e
.asm_9207
	ld hl, sDeck4Cards
	call Func_9314
	jr c, .asm_9214
	ld a, $1
	ld [wceb5], a
.asm_9214
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	ld c, a
	ld b, $0
	ld d, $2
.asm_921f
	ld hl, wceb2
	add hl, bc
	ld a, [hl]
	or a
	jr nz, .asm_9234
	inc c
	ld a, $4
	cp c
	jr nz, .asm_921f
	ld c, $0
	dec d
	jr z, .asm_9234
	jr .asm_921f
.asm_9234
	ld a, c
	ld [sCurrentlySelectedDeck], a
	call DisableSRAM
	call DrawHandCardsTileOnSelectedDeck
	call EnableLCD
	ret

Unknown_9242: ; 9242 (2:5242)
	INCROM $9242, $9253

Func_9253: ; 9253 (2:5253)
	ld de, wDefaultText
	call CopyListFromHLToDE
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, Data_92a7
	call CopyListFromHLToDE
	ret

; de = coordinates to print text
Func_926e: ; 926e (2:526e)
	push hl
	call Func_9314
	pop hl
	jr c, .asm_929c
	push de
	ld de, wDefaultText
	call CopyListFromHLToDEInSRAM
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, Data_92a7
	call CopyListFromHLToDE
	pop de
	ld hl, wDefaultText
	call InitTextPrinting
	call ProcessText
	or a
	ret
.asm_929c
	call InitTextPrinting
	ldtx hl, NewDeckText
	call ProcessTextFromID
	scf
	ret

Data_92a7: ; 92a7 (2:52a7)
	db " deck"
	db TX_END

; copies a $00-terminated list from hl to de
CopyListFromHLToDE: ; 92ad (2:52ad)
	ld a, [hli]
	ld [de], a
	or a
	ret z
	inc de
	jr CopyListFromHLToDE

; same as CopyListFromHLToDE, but for SRAM copying
CopyListFromHLToDEInSRAM: ; 92b4 (2:52b4)
	call EnableSRAM
	call CopyListFromHLToDE
	call DisableSRAM
	ret
; 0x92be

Func_92be: ; 92be (2:52be)
	push hl
	call Func_9314
	pop hl
	ret c
	push de
	ld de, wDefaultText
	call CopyListFromHLToDEInSRAM
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld a, c
	cp 21
	jr c, .asm_92d8
	ld c, 21
.asm_92d8
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, .text_start
	ld b, .text_end - .text_start
	call CopyNBytesFromHLToDE
	xor a
	ld [wc5aa], a
	pop de
	ld hl, wDefaultText
	call InitTextPrinting
	call ProcessText
	or a
	ret

.text_start
	db " deck                       "
.text_end
; 0x9314

Func_9314: ; 9314 (2:5314)
	ld bc, $0018
	add hl, bc
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	jr nz, .asm_9324
	scf
	ret
.asm_9324
	or a
	ret

; calculates the y coordinate of the currently selected deck
; and draws the hands card tile at that position
DrawHandCardsTileOnSelectedDeck: ; 9326 (2:5326)
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM
	ld h, 3
	ld l, a
	call HtimesL
	ld e, l
	inc e ; (sCurrentlySelectedDeck * 3) + 1
	ld d, 2
;	fallthrough

; de = coordinates to draw rectangle
DrawHandCardsTileAtDE: ; 9339 (2:5339)
	ld a, $38 ; hand cards tile
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	ret

Func_9345: ; 9345 (2:5345)
	call Func_8ce7
	call CountNumberOfCardsForEachCardType
.skip_count
	call DrawCardTypeIconsAndPrintCardCounts

	xor a
	ld [wcea1], a
	ld [wced3], a
	call Func_993d

.skip_draw
	ld hl, Data_9667
	call Func_9a6d
.wait_input
	call DoFrame
	ldh a, [hDPadHeld]
	and START
	jr z, .no_start_btn
	ld a, $01
	call PlaySFXConfirmOrCancel
	call ConfirmDeckConfiguration
	ld a, [wced3]
	ld [wNamingScreenCursorY], a
	jr .wait_input
.no_start_btn
	ld a, [wced3]
	ld b, a
	ld a, [wNamingScreenCursorY]
	cp b
	jr z, .check_down_btn
	ld [wced3], a
	ld hl, wcea1
	ld [hl], $00
	call Func_993d
	ld a, $09
	ld [wNamingScreenKeyboardHeight], a

.check_down_btn
	ldh a, [hDPadHeld]
	and D_DOWN
	jr z, .no_down_btn
	call Func_9ad7
	jr .asm_93a9
.no_down_btn
	call Func_9a83
	jr nc, .wait_input
	ld a, [hffb3]
	cp $ff
	jp z, Func_9461
.asm_93a9
	ld a, [wceab + 3]
	or a
	jr z, .wait_input
	xor a
.asm_93b0
	ld hl, Data_9670
	call Func_9a6d
	ld a, [wceab + 3]
	ld [wcfe4 + 2], a
	ld hl, wcecb
	cp [hl]
	jr nc, .asm_93c5
	ld [wNamingScreenKeyboardHeight], a
.asm_93c5
	ld hl, PrintDeckBuildingCardList
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d

	ld a, $01
	ld [wced2], a
.asm_93d4
	call DoFrame
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_93f0
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wNamingScreenCursorY]
	ld [wced5], a
	call ConfirmDeckConfiguration
	ld a, [wced5]
	jr .asm_93b0
.asm_93f0
	call Func_9efc
	jr c, .asm_93d4
	call Func_9b25
	jr c, .asm_9442
	jr .asm_93d4
.asm_93fc
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wNamingScreenKeyboardHeight]
	ld [wcfdf], a
	ld a, [wNamingScreenCursorY]
	ld [wced4], a
	ld de, wceda
	ld hl, wcfd8
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_9c3f
	call DrawCardTypeIconsAndPrintCardCounts
	ld hl, Data_9667
	call Func_9a6d
	ld a, [wced3]
	ld [wNamingScreenCursorY], a
	call Func_9b20
	call PrintDeckBuildingCardList
	ld hl, Data_9670
	call Func_9a6d
	ld a, [wcfdf]
	ld [wNamingScreenKeyboardHeight], a
	ld a, [wced4]
	ld [wNamingScreenCursorY], a
	jr .asm_93d4
.asm_9442
	call Func_9c0e
	ld a, [wNamingScreenCursorY]
	ld [wced4], a
	ld a, [hffb3]
	cp $ff
	jr nz, .asm_93fc
	ld hl, Data_9667
	call Func_9a6d
	ld a, [wced3]
	ld [wNamingScreenCursorY], a
	jp .wait_input
; 0x9461

Func_9461: ; 9461 (2:5461)
	xor a
	ld [wPrizeCardCursorPosition], a
	ld de, wcfd1 + 5
	ld hl, wMenuInputTablePointer
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
.asm_9475
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ld hl, wcfd1 + 3
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl
; 0x9480

HandleDeckConfigurationMenu: ; 9480 (2:5480)
	lb de, 0, 0
	lb bc, 20, 6
	call DrawRegularTextBox
	ld hl, DeckBuildMenuData
	call PlaceTextItems

.do_frame
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call Func_89ae
	jr nc, .do_frame
	ld [wced6], a
	cp $ff
	jr nz, .asm_94b5
.draw_icons
	call DrawCardTypeIconsAndPrintCardCounts
	ld a, [wced4]
	ld [wNamingScreenCursorY], a
	ld a, [wced3]
	call Func_993d
	jp Func_9345.skip_draw

.asm_94b5
	push af
	call Func_89ae.draw_cursor
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	pop af
	ld hl, .func_table
	call JumpToFunctionInTable
	jr Func_9461.asm_9475

.func_table
	dw ConfirmDeckConfiguration ; Confirm
	dw ModifyDeckConfiguration  ; Modify
	dw ChangeDeckName           ; Name
	dw SaveDeckConfiguration    ; Save
	dw DismantleDeck            ; Dismantle
	dw CancelDeckModifications  ; Cancel
; 0x94d3

ConfirmDeckConfiguration: ; 94d3 (2:54d3)
	ld hl, wcea1
	ld a, [hl]
	ld hl, wced8
	ld [hl], a
	call Func_9e41
	ld hl, wced8
	ld a, [hl]
	ld hl, wcea1
	ld [hl], a
	call DrawCardTypeIconsAndPrintCardCounts
	ld hl, Data_9667
	call Func_9a6d
	ld a, [wced3]
	ld [wNamingScreenCursorY], a
	call Func_9b20
	ld a, [wced3]
	call Func_993d
	ld a, [wced6]
	ld [wNamingScreenCursorY], a
	ret
; 0x9505

ModifyDeckConfiguration: ; 9505 (2:5505)
	add sp, $2
	jr HandleDeckConfigurationMenu.draw_icons
; 0x9509

; returns carry set if player chose to save deck
CancelDeckModifications: ; 9509 (2:5509)
	call Func_95c1
	jr nc, .asm_9516
	ldtx hl, QuitModifyingTheDeckText
	call YesOrNoMenuWithText
	jr c, SaveDeckConfiguration.go_back
.asm_9516
	add sp, $2
	or a
	ret

SaveDeckConfiguration: ; 951a (2:551a)
; handle deck configuration size
	ld a, [wcecc]
	cp DECK_SIZE
	jp z, .ask_to_save_deck ; should be jr
	ldtx hl, ThisIsntA60CardDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, ReturnToOriginalConfigurationText
	call YesOrNoMenuWithText
	jr c, .print_deck_size_warning
; return no carry
	add sp, $2
	or a
	ret
.print_deck_size_warning
	ldtx hl, TheDeckMustInclude60CardsText
	call DrawWideTextBox_WaitForInput
	jr .go_back

.ask_to_save_deck
	ldtx hl, SaveThisDeckText
	call YesOrNoMenuWithText
	jr c, .go_back
	call Func_9649
	jr c, .set_carry
	ldtx hl, ThereAreNoBasicPokemonInThisDeckText
	call DrawWideTextBox_WaitForInput
	ldtx hl, YouMustIncludeABasicPokemonInTheDeckText
	call DrawWideTextBox_WaitForInput

.go_back
	call DrawCardTypeIconsAndPrintCardCounts
	call PrintDeckBuildingCardList
	ld a, [wced6]
	ld [wNamingScreenCursorY], a
	ret

.set_carry
	add sp, $2
	scf
	ret
; 0x9566

DismantleDeck: ; 9566 (2:5566)
	ldtx hl, DismantleThisDeckText
	call YesOrNoMenuWithText
	jr c, SaveDeckConfiguration.go_back
	call Func_9622
	jp nc, .Dismantle ; should be jr
	ldtx hl, ThereIsOnly1DeckSoCannotBeDismantledText
	call DrawWideTextBox_WaitForInput
	call EmptyScreen
	ld hl, Data_9667
	call Func_9a6d
	ld a, [wced3]
	ld [wNamingScreenCursorY], a
	call Func_9b20
	call PrintDeckBuildingCardList
	call EnableLCD
	ld a, [wced6]
	ld [wNamingScreenCursorY], a
	ret

.Dismantle
	call EnableSRAM
	call GetPointerToDeckName
	ld a, [hl]
	or a
	jr z, .done_dismantle
	ld a, NAME_BUFFER_LENGTH
	call ClearNBytesFromHL
	call GetPointerToDeckCards
	call Func_9152
	ld a, DECK_SIZE
	call ClearNBytesFromHL
.done_dismantle
	call DisableSRAM
	add sp, $2
	ret
; 0x95b9

ChangeDeckName: ; 95b9 (2:55b9)
	call Func_8f05
	add sp, $2
	jp Func_9345.skip_count
; 0x95c1

Func_95c1: ; 95c1 (2:55c1)
	ld a, [wcecc]
	or a
	jr z, .skip_size_check
	cp DECK_SIZE
	jr nz, .done
.skip_size_check

; copy the selected deck to wc590
	call GetPointerToDeckCards
	ld de, wc590
	ld b, DECK_SIZE
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM

; loops through cards in wcf17
; then if that card is found in wc590
; overwrite it by $0
	ld a, $ff
	ld [wc5cc], a
	ld de, wcf17
.loop_outer
	ld a, [de]
	or a
	jr z, .check_empty
	ld b, a
	inc de
	ld hl, wc590
.loop_inner
	ld a, [hli]
	cp $ff
	jr z, .loop_outer
	cp b
	jr nz, .loop_inner
	; found
	dec hl
	xor a
	ld [hli], a ; remove
	jr .loop_outer

.check_empty
	ld hl, wc590
.loop_check_empty
	ld a, [hli]
	cp $ff
	jr z, .is_empty
	or a
	jr nz, .done
	jr .loop_check_empty

; wc590 is empty (all $0)
.is_empty
	call GetPointerToDeckName
	ld de, wcfb9
	call EnableSRAM
.asm_9610
	ld a, [de]
	cp [hl]
	jr nz, .done
	inc de
	inc hl
	or a
	jr nz, .asm_9610
	call DisableSRAM
	ret
.done
	call DisableSRAM
	scf
	ret
; 0x9622

Func_9622: ; 9622 (2:5622)
	ld hl, wceb2
	ld bc, $0
.loop
	inc b
	ld a, $04
	cp b
	jr c, .asm_963a
	ld a, [hli]
	or a
	jr z, .loop
	inc c
	ld a, $01
	cp c
	jr nc, .loop
.no_carry
	or a
	ret
.asm_963a
	call GetPointerToDeckCards
	call EnableSRAM
	ld a, [hl]
	call DisableSRAM
	or a
	jr z, .no_carry
	scf
	ret
; 0x9649

; checks if wcf17 has any basics
; returns carry set if there is at least
; 1 Basic Pokemon card
Func_9649: ; 9649 (2:5649)
	ld hl, wcf17
.loop_cards
	ld a, [hli]
	ld e, a
	or a
	jr z, .no_carry
	call LoadCardDataToBuffer1_FromCardID
	jr c, .no_carry
	ld a, [wLoadedCard1Type]
	and TYPE_ENERGY
	jr nz, .loop_cards
	ld a, [wLoadedCard1Stage]
	or a
	jr nz, .loop_cards
	; is basic card
	scf
	ret
.no_carry
	or a
	ret
; 0x9667

Data_9667: ; 9667 (2:5667)
	db $01, $01, $00, $02, $09, $2f, $00, $00, $00

Data_9670: ; 9670 (2:5670)
	db $00, $07, $02, $00, $06, $0f, $00, $00, $00

DeckConfigurationMenu_TransitionTable: ; 9679 (2:5679)
	cursor_transition $10, $20, $00, $03, $03, $01, $02
	cursor_transition $48, $20, $00, $04, $04, $02, $00
	cursor_transition $80, $20, $00, $05, $05, $00, $01
	cursor_transition $10, $30, $00, $00, $00, $04, $05
	cursor_transition $48, $30, $00, $01, $01, $05, $03
	cursor_transition $80, $30, $00, $02, $02, $03, $04

; draws each card type icon in a line
; the respective card counts underneath each icon
; and prints"X/60" in the upper-right corner,
; where X is the total card count
DrawCardTypeIconsAndPrintCardCounts: ; 96a3 (2:56a3)
	call Set_OBJ_8x8
	call Func_8d78
	lb bc, 0, 5
	ld a, SYM_BOX_TOP
	call FillBGMapLineWithA
	call DrawCardTypeIcons
	call PrintCardTypeCounts
	lb de, 15, 0
	call PrintTotalCardCount
	lb de, 17, 0
	call PrintSlashSixty
	call EnableLCD
	ret
; 0x96c7

; fills one line at coordinate bc in BG Map
; with the byte in register a
; fills the same line with $04 in VRAM1 if in CGB
; bc = coordinates
FillBGMapLineWithA: ; 96c7 (2:56c7)
	call BCCoordToBGMap0Address
	ld b, SCREEN_WIDTH
	call FillDEWithA
	ld a, [wConsole]
	cp CONSOLE_CGB
	ret nz ; return if not CGB
	ld a, $04
	ld b, SCREEN_WIDTH
	call BankswitchVRAM1
	call FillDEWithA
	call BankswitchVRAM0
	ret
; 0x96e3

; saves the count of each type of card that is in wcf17
; stores these values in wcebb
CountNumberOfCardsForEachCardType: ; 96e3 (2:56e3)
	ld hl, wcebb
	ld de, CardTypeFilters
.loop
	ld a, [de]
	cp -1
	ret z
	inc de
	call CountNumberOfCardsOfType
	ld [hli], a
	jr .loop
; 0x96f4

; fills de with b bytes of the value in register a
FillDEWithA: ; 96f4 (2:56f4)
	push hl
	ld l, e
	ld h, d
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop hl
	ret
; 0x96fd

; draws all the card type icons
; in a line specified by .CardTypeIcons
DrawCardTypeIcons: ; 96fd (2:56fd)
	ld hl, .CardTypeIcons
.loop
	ld a, [hli]
	or a
	ret z ; done
	ld d, [hl] ; x coord
	inc hl
	ld e, [hl] ; y coord
	inc hl
	call .DrawIcon
	jr .loop

; input:
; de = coordinates
.DrawIcon
	push hl
	push af
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	pop af
	call GetCardTypeIconPalette
	ld b, a
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .not_cgb
	ld a, b
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.not_cgb
	pop hl
	ret

.CardTypeIcons
; icon tile, x coord, y coord
	db ICON_TILE_GRASS,      1, 2
	db ICON_TILE_FIRE,       3, 2
	db ICON_TILE_WATER,      5, 2
	db ICON_TILE_LIGHTNING,  7, 2
	db ICON_TILE_FIGHTING,   9, 2
	db ICON_TILE_PSYCHIC,   11, 2
	db ICON_TILE_COLORLESS, 13, 2
	db ICON_TILE_TRAINER,   15, 2
	db ICON_TILE_ENERGY,    17, 2
	db $00
; 0x9751

DeckBuildMenuData: ; 9751 (1:5751)
	; x, y, text id
	textitem  2, 2, ConfirmText
	textitem  9, 2, ModifyText
	textitem 16, 2, NameText
	textitem  2, 4, SaveText
	textitem  9, 4, DismantleText
	textitem 16, 4, CancelText
	db $ff

; prints "/60" to the coordinates given in de
PrintSlashSixty: ; 976a (2:576a)
	ld hl, wDefaultText
	ld a, TX_SYMBOL
	ld [hli], a
	ld a, SYM_SLASH
	ld [hli], a
	ld a, TX_SYMBOL
	ld [hli], a
	ld a, SYM_6
	ld [hli], a
	ld a, TX_SYMBOL
	ld [hli], a
	ld a, SYM_0
	ld [hli], a
	ld [hl], TX_END
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText
	ret
; 0x978b

; creates two separate lists given the card type in register a
; if a card matches the card type given, then it's added to wFilteredCardList
; if a card has been owned by the player, and its card count is at least 1,
; (or in case it's 0 if it's in any deck configurations saved)
; then its collection count is also added to wOwnedCardsCountList
; if input a is $ff, then all card types are included
CreateFilteredCardList: ; 978b (2:578b)
	push af
	push bc
	push de
	push hl

; clear wOwnedCardsCountList and wFilteredCardList
	push af
	ld a, DECK_SIZE
	ld hl, wOwnedCardsCountList
	call ClearNBytesFromHL
	ld a, DECK_SIZE
	ld hl, wFilteredCardList
	call ClearNBytesFromHL
	pop af

; loops all cards in collection
	ld hl, $0
	ld de, $0
	ld b, a ; input card type
.loop_card_ids
	inc e
	call GetCardType
	jr c, .add_terminator_byte
	ld c, a
	ld a, b
	cp $ff
	jr z, .add_card
	and $20
	cp $20
	jr z, .check_energy
	ld a, c
	cp b
	jr nz, .loop_card_ids
	jr .add_card
.check_energy
	ld a, c
	and TYPE_ENERGY
	cp TYPE_ENERGY
	jr nz, .loop_card_ids

.add_card
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	pop hl
	cp CARD_NOT_OWNED
	jr z, .next_card ; jump if never seen card
	or a
	jr nz, .ok ; has at least 1
	call IsCardInAnyDeck
	jr c, .next_card ; jump if not in any deck
.ok
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	inc l
.next_card
	pop bc
	jr .loop_card_ids

.add_terminator_byte
	ld a, l
	ld [wceab + 3], a
; add terminator bytes in both lists
	xor a
	ld c, l
	ld b, h
	ld hl, wFilteredCardList
	add hl, bc
	ld [hl], a ; $00
	ld a, $ff
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld [hl], a ; $ff
	pop hl
	pop de
	pop bc
	pop af
	ret
; 0x9803

; returns carry if card ID in register e is not
; found in any of the decks saved in SRAM
IsCardInAnyDeck: ; 9803 (2:5803)
	push af
	push hl
	ld hl, sDeck1Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck2Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck3Cards
	call .FindCardInDeck
	jr nc, .found_card
	ld hl, sDeck4Cards
	call .FindCardInDeck
	jr nc, .found_card
	pop hl
	pop af
	scf
	ret
.found_card
	pop hl
	pop af
	or a
	ret

; returns carry if input card ID in register e
; is not found in deck given by hl
.FindCardInDeck
	call EnableSRAM
	ld b, DECK_SIZE
.loop
	ld a, [hli]
	cp e
	jr z, .not_found
	dec b
	jr nz, .loop
; not found
	call DisableSRAM
	scf
	ret
.not_found
	call DisableSRAM
	or a
	ret
; 0x9843

; preserves all registers
; hl = start of bytes to set to $0
; a = number of bytes to set to $0
ClearNBytesFromHL: ; 9843 (2:5843)
	push af
	push bc
	push hl
	ld b, a
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	pop hl
	pop bc
	pop af
	ret
; 0x9850

; finds instance of e in list wcf17
; returns the position in the list that it was found
; if not found, returns last position + 1
Func_9850: ; 9850 (2:5850)
	push hl
	ld hl, wcf17
	ld d, $00
.loop
	ld a, [hli]
	or a
	jr z, .done
	cp e
	jr nz, .loop
	inc d
	jr .loop
.done
	ld a, d
	pop hl
	ret
; 0x9863

; returns total count of card ID e
; looks it up in wFilteredCardList
; then uses the index to retrieve the count
; value from wOwnedCardsCountList
GetOwnedCardCount: ; 9863 (2:5863)
	push hl
	ld hl, wFilteredCardList
	ld d, -1
.loop
	inc d
	ld a, [hli]
	or a
	jr z, .not_found
	cp e
	jr nz, .loop
	ld hl, wOwnedCardsCountList
	push de
	ld e, d
	ld d, $00
	add hl, de
	pop de
	ld a, [hl]
	pop hl
	ret
.not_found
	xor a
	pop hl
	ret
; 0x9880

; appends text "X/Y", where X is the number of included cards
; and Y is the total number of cards in storage of a given card ID
; input:
; e = card ID
AppendOwnedCardCountAndStorageCountNumbers: ; 9880 (2:5880)
	push af
	push bc
	push de
	push hl
; count how many bytes untill $00
.loop
	ld a, [hl]
	or a
	jr z, .print
	inc hl
	jr .loop
.print
	push de
	call Func_9850
	call ConvertToNumericalDigits
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_SLASH
	inc hl
	pop de
	call GetOwnedCardCount
	call ConvertToNumericalDigits
	ld [hl], TX_END
	pop hl
	pop de
	pop bc
	pop af
	ret
; 0x98a6

; determines the ones and tens digits in a for printing
; the ones place is added $20 (SYM_0) so that it maps to a numerical character
; if the tens is 0, it maps to an empty character
; a = value to calculate digits
CalculateOnesAndTensDigits: ; 98a6 (2:58a6)
	push af
	push bc
	push de
	push hl
	ld c, -1
.loop
	inc c
	sub 10
	jr nc, .loop
	jr z, .zero1
	add 10
	; a = a mod 10
	; c = floor(a / 10)
.zero1
; ones digit
	add SYM_0
	ld hl, wOnesAndTensPlace
	ld [hli], a

; tens digit
	ld a, c
	or a
	jr z, .zero2
	add SYM_0
.zero2
	ld [hl], a

	pop hl
	pop de
	pop bc
	pop af
	ret

; converts value in register a to
; numerical symbols for ProcessText
; places the symbols in hl
ConvertToNumericalDigits: ; 98c7 (2:58c7)
	call CalculateOnesAndTensDigits
	push hl
	ld hl, wOnesAndTensPlace
	ld a, [hli]
	ld b, a
	ld a, [hl]
	pop hl
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a
	ret
; 0x98dc

; counts the number of cards in wcf17
; that are the same type as input in register a
; if input is $20, counts all energy cards instead
; input:
; - a = card type
; output:
; - a = number of cards of same type
CountNumberOfCardsOfType: ; 98dc (2:58dc)
	push de
	push hl
	ld hl, $0
	ld b, a
	ld c, 0
.loop_cards
	push hl
	push bc
	ld bc, wcf17
	add hl, bc
	ld a, [hl]
	pop bc
	pop hl
	inc l
	or a
	jr z, .done ; end of card list

; get card type and compare it with input type
; if input is $20, run a separate comparison
; if it's the same type, increase the count
	ld e, a
	call GetCardType
	jr c, .done
	push hl
	ld l, a
	ld a, b
	and $20
	cp $20
	jr z, .check_energy
	ld a, l
	pop hl
	cp b
	jr nz, .loop_cards
	jr .incr_count

; counts all energy cards as the same
.check_energy
	ld a, l
	pop hl
	and TYPE_ENERGY
	cp TYPE_ENERGY
	jr nz, .loop_cards
.incr_count
	inc c
	jr .loop_cards
.done
	ld a, c
	pop hl
	pop de
	ret
; 0x9916

; prints the card count of each individual card type
; assumes CountNumberOfCardsForEachCardType was already called
; this is done by processing text in a single line
; and concatenating all digits
PrintCardTypeCounts: ; 9916 (2:5916)
	ld bc, $0
	ld hl, wDefaultText
.loop
	push hl
	ld hl, wcebb
	add hl, bc
	ld a, [hl]
	pop hl
	push bc
	call ConvertToNumericalDigits
	pop bc
	inc c
	ld a, $9
	cp c
	jr nz, .loop
	ld [hl], TX_END
	lb de, 1, 4
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText
	ret
; 0x993d

Func_993d: ; 993d (2:593d)
	push af
	ld hl, CardTypeFilters
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [hl]
	push af

; copy sCardCollection to wTempCardCollection
	call EnableSRAM
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld b, $ff
	call CopyNBytesFromHLToDE
	call DisableSRAM

	ld a, [wcfd1 + 2]
	or a
	jr z, .ok
	call GetPointerToDeckCards
	ld d, h
	ld e, l
	call GetDeckCardCounts
.ok
	pop af
	call CreateFilteredCardList
	ld a, $06
	ld [wcecb], a
	lb de, 1 ,7
	ld hl, wced0
	ld [hl], e
	inc hl
	ld [hl], d
	call PrintDeckBuildingCardList
	pop af
	ret
; 0x997d

; used to filter the cards in the deck building/card selection screen
CardTypeFilters: ; 997d (2:597d)
	db TYPE_PKMN_GRASS
	db TYPE_PKMN_FIRE
	db TYPE_PKMN_WATER
	db TYPE_PKMN_LIGHTNING
	db TYPE_PKMN_FIGHTING
	db TYPE_PKMN_PSYCHIC
	db TYPE_PKMN_COLORLESS
	db TYPE_TRAINER
	db $20
	db -1 ; end of list
; 0x9987

; counts all the cards from each card type
; (stored in wcebb) and store it in wcecc
; also prints it in coordinates de
PrintTotalCardCount: ; 9987 (2:5987)
	push de
	ld bc, $0
	ld hl, wcebb
.loop
	ld a, [hli]
	add b
	ld b, a
	inc c
	ld a, $9
	cp c
	jr nz, .loop
	ld hl, wDefaultText
	ld a, b
	ld [wcecc], a
	push bc
	call ConvertToNumericalDigits
	pop bc
	ld [hl], TX_END
	pop de
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText
	ret
; 0x99b0

; prints the name, level and storage count of the cards
; that are visible in the list window
; in the form:
; CARD NAME/LEVEL X/Y
; where X is the current count of that card
; and Y is the storage count of that card
PrintDeckBuildingCardList: ; 99b0 (2:59b0)
	push bc
	ld hl, wced0
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coord
	ld c, e
	dec c
	ld a, [wcea1]
	or a
	jr z, .no_cursor
	ld a, SYM_CURSOR_U
	jr .got_cursor_tile
.no_cursor
	ld a, SYM_SPACE
.got_cursor_tile
	call WriteByteToBGMap0

; iterates by decreasing value in wcecb
; by 1 until it reaches 0
	ld a, [wcea1]
	ld c, a
	ld b, $0
	ld hl, wFilteredCardList
	add hl, bc
	ld a, [wcecb]
.loop_filtered_cards
	push de
	or a
	jr z, .exit_loop
	ld b, a
	ld a, [hli]
	or a
	jr z, .invalid_card ; card ID of 0
	ld e, a
	call Func_9a59
	call LoadCardDataToBuffer1_FromCardID
	ld a, 13
	push bc
	push hl
	push de
	call CopyCardNameAndLevel
	pop de
	call AppendOwnedCardCountAndStorageCountNumbers
	pop hl
	pop bc
	pop de
	push hl
	call InitTextPrinting
	ld hl, wDefaultText
	jr .process_text

.invalid_card
	pop de
	push hl
	call InitTextPrinting
	ld hl, Text_9a30
.process_text
	call ProcessText
	pop hl

	ld a, b
	dec a
	inc e
	inc e
	jr .loop_filtered_cards

.exit_loop
	ld a, [hli]
	or a
	jr z, .cannot_scroll
	pop de
; draw down cursor because
; there are still more cards
; to be scrolled down
	xor a
	ld [wcecd], a
	ld a, SYM_CURSOR_D
	jr .draw_cursor
.cannot_scroll
	pop de
	ld a, $01
	ld [wcecd], a
	ld a, SYM_SPACE
.draw_cursor
	ld b, 19 ; x coord
	ld c, e
	dec c
	dec c
	call WriteByteToBGMap0
	pop bc
	ret

Text_9a30:
	db TX_SYMBOL, TX_END

Text_9a32:
	db TX_SYMBOL, TX_END

Text_9a34:
	db TX_SYMBOL, TX_END

Text_9a36:
	db TX_SYMBOL, TX_END

Text_9a38:
	db TX_SYMBOL, TX_END

Text_9a3a:
	db TX_SYMBOL, TX_END

Text_9a3c:
	db TX_SYMBOL, TX_END

Text_9a3e:
	db TX_SYMBOL, TX_END

Text_9a40:
	db TX_SYMBOL, TX_END

Text_9a42:
	db TX_SYMBOL, TX_END

Text_9a44:
	db TX_SYMBOL, TX_END

Text_9a46:
	db TX_SYMBOL, TX_END

Text_9a48:
	db TX_SYMBOL, TX_END

Text_9a4a:
	db TX_SYMBOL, TX_END

Text_9a4c:
	db TX_SYMBOL, TX_END

Text_9a4e:
	db TX_SYMBOL, TX_END

Text_9a50:
	db TX_SYMBOL, TX_END

Text_9a52:
	db TX_SYMBOL, TX_END

Text_9a54:
	db TX_SYMBOL, TX_END

Text_9a56:
	db TX_SYMBOL, TX_END

Text_9a58:
	db TX_END

; input:
; b = ?
; e = card ID
Func_9a59: ; 9a59 (2:5a59)
	push af
	push bc
	push hl
	ld hl, wcec4
	ld c, b
	ld a, [wcecb]
	sub c
	ld c, a
	ld b, $00
	add hl, bc ; = wcec4 + (wcecb - b)
	ld [hl], e
	pop hl
	pop bc
	pop af
	ret
; 0x9a6d

; copies 9 bytes from hl to wcea5
Func_9a6d: ; 9a6d (2:5a6d)
	ld [wNamingScreenCursorY], a
	ld [hffb3], a
	ld de, wcea5
	ld b, $9
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	xor a
	ld [wCheckMenuCursorBlinkCounter], a
	ret
; 0x9a83

Func_9a83: ; 9a83 (2:5a83)
	INCROM $9a83, $9ad7

Func_9ad7: ; 9ad7 (2:5ad7)
	call Func_9b20
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wNamingScreenCursorY]
	ld e, a
	ld a, [hffb3]
	scf
	ret
; 0x9ae8

	INCROM $9ae8, $9b03

Func_9b03: ; 9b03 (2:5b03)
	ld e, a
	ld a, [wcea5 + 3]
	ld l, a
	ld a, [wNamingScreenCursorY]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wcea5
	add [hl]
	ld b, a
	ld hl, wcea5 + 1
	ld a, [hl]
	ld c, a
	ld a, e
	call WriteByteToBGMap0
	or a
	ret
; 0x9b20

Func_9b20: ; 9b20 (2:5b20)
	ld a, [wceaa]
	jr Func_9b03
; 0x9b25

Func_9b25: ; 9b25 (2:5b25)
	INCROM $9b25, $9c0e

Func_9c0e: ; 9c0e (2:5c0e)
	INCROM $9c0e, $9c11

; a = tile to write
Func_9c11: ; 9c11 (2:5c11)
	ld e, a
	ld a, [wcea5 + 3]
	ld l, a
	ld a, [wNamingScreenCursorY]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wcea5
	add [hl]
	ld b, a
	ld a, [wcea5 + 2]
	ld l, a
	ld a, [wNamingScreenCursorY]
	ld h, a
	call HtimesL
	ld a, l
	ld hl, wcea5 + 1
	add [hl]
	ld c, a
	ld a, e
	call WriteByteToBGMap0
	or a
	ret
; 0x9c3a

Func_9c3a: ; 9c3a (2:5c3a)
	ld a, [wceaa]
	jr Func_9c11
; 0x9c3f

Func_9c3f: ; 9c3f (2:5c3f)
	INCROM $9c3f, $9e31

Func_9e31: ; 9e31 (2:5e31)
	ld hl, hffb0
	ld [hl], $01
	call Func_9fc0
	ld hl, hffb0
	ld [hl], $00
	jp PrintConfirmationCardList
; 0x9e41

Func_9e41: ; 9e41 (2:5e41)
	ld a, [wcecc]
	or a
	jp z, Func_9f40
	call Func_a028
	call Func_a06e

	xor a
	ld [wcea1], a
.asm_9e52
	ld hl, Data_9eaf
	call Func_9a6d
	ld a, [wced9]
	ld [wcfe4+ 2], a
	cp $07
	jr c, .asm_9e64
	ld a, $07
.asm_9e64
	ld [wNamingScreenKeyboardHeight], a
	ld [wcecb], a
	call Func_9f52
	ld hl, Func_9e31
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d
	xor a
	ld [wced2], a
.asm_9e7b
	call DoFrame
	call Func_9b25
	jr c, .asm_9ea7
	call Func_9eb8
	jr c, .asm_9e7b
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_9e7b

.asm_9e8e
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wNamingScreenCursorY]
	ld [wced7], a
	ld de, wOwnedCardsCountList
	ld hl, wcfd8
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_9c3f
	jr .asm_9e52

.asm_9ea7
	ld a, [hffb3]
	cp $ff
	ret z
	jr .asm_9e8e
; 0x9eaf

Data_9eaf:
	db $00, $05, $02, $00, $07, $0f, $00, $00, $00

Func_9eb8: ; 9eb8 (2:5eb8)
	ld a, [wNamingScreenKeyboardHeight]
	ld d, a
	ld a, [wcea1]
	ld c, a
	ldh a, [hDPadHeld]
	cp D_RIGHT
	jr z, .right
	cp D_LEFT
	jr z, .left
	or a
	ret

.right
	ld a, [wcea1]
	add d
	ld b, a
	add d
	ld hl, wcfe4 + 2
	cp [hl]
	jr c, .asm_9ee8
	ld a, [wcfe4 + 2]
	sub d
	ld b, a
	jr .asm_9ee8

.left
	ld a, [wcea1]
	sub d
	ld b, a
	jr nc, .asm_9ee8
	ld b, $00
.asm_9ee8
	ld a, b
	ld [wcea1], a
	cp c
	jr z, .asm_9efa
	ld a, SFX_01
	call PlaySFX
	ld hl, wcece
	call CallIndirect
.asm_9efa
	scf
	ret
; 0x9efc

Func_9efc: ; 9efc (2:5efc)
	INCROM $9efc, $9f40

Func_9f40: ; 9f40 (2:5f40)
	call Func_9f81
.wait_input
	call DoFrame
	ldh a, [hKeysPressed]
	and B_BUTTON
	jr z, .wait_input
	ld a, $ff
	call PlaySFXConfirmOrCancel
	ret
; 0x9f52

Func_9f52: ; 9f52 (2:5f52)
	call Func_9f81
	lb de, 3, 5
	ld hl, wced0
	ld [hl], e
	inc hl
	ld [hl], d
	call PrintConfirmationCardList
	ret
; 0x9f62

; counts all values stored in wcebb
; if the total count is 0, then
; prints "No cards chosen."
Func_9f62: ; 9f62 (2:5f62)
	lb bc, 0, 0
	ld hl, wcebb
.loop
	ld a, [hli]
	add b
	ld b, a
	inc c
	ld a, $9
	cp c
	jr nz, .loop
	ld a, b
	or a
	ret nz
	lb de, 11, 1
	call InitTextPrinting
	ldtx hl, NoCardsChosenText
	call ProcessTextFromID
	ret
; 0x9f81

Func_9f81: ; 9f81 (2:5f81)
	call Func_8d56
	lb de, 0, 0
	lb bc, 20, 4
	call DrawRegularTextBox
	ld a, [wcfb9]
	or a
	jp z, .print_card_count ; should be jr
	call Func_9fc0
	ld a, [wceb1]
	ld b, a
	call EnableSRAM
	ld a, [sCurrentlySelectedDeck]
	call DisableSRAM
	cp b
	jr nz, .print_card_count
	lb de, 2, 1
	call DrawHandCardsTileAtDE

.print_card_count
	lb de, 14, 1
	call PrintTotalCardCount
	lb de, 16, 1
	call PrintSlashSixty
	call Func_9f62
	call EnableLCD
	ret
; 0x9fc0

Func_9fc0: ; 9fc0 (2:5fc0)
	ld a, [wceb1]
	cp $ff
	jr z, .asm_9fea
	lb de, 3, 2
	call InitTextPrinting
	ld a, [wceb1]
	bit 7, a
	jr z, .asm_9fd8
	and $7f
	jr .asm_9fd9
.asm_9fd8
	inc a
.asm_9fd9
	ld hl, wDefaultText
	call ConvertToNumericalDigits
	ld [hl], $77
	inc hl
	ld [hl], TX_END
	ld hl, wDefaultText
	call ProcessText

.asm_9fea
	ld hl, wcfb9
	ld de, wDefaultText
	call CopyListFromHLToDE
	ld a, [wceb1]
	cp $ff
	jr z, .asm_a01b
	ld hl, wDefaultText
	call GetTextLengthInTiles
	ld b, $0
	ld hl, wDefaultText
	add hl, bc
	ld d, h
	ld e, l
	ld hl, Data_92a7
	call CopyListFromHLToDE
	lb de, 6, 2
	ld hl, wDefaultText
	call InitTextPrinting
	call ProcessText
	ret

.asm_a01b
	lb de, 2, 2
	ld hl, wDefaultText
	call InitTextPrinting
	call ProcessText
	ret
; 0xa028

Func_a028: ; a028 (2:6028)
	ld hl, wcf17
	ld de, wOpponentDeck
	ld bc, wDuelTempList
	ld a, -1
	ld [bc], a
.loop_copy
	inc a
	push af
	ld a, [hli]
	ld [de], a
	inc de
	or a
	jr z, .sort_cards
	pop af
	ld [bc], a
	inc bc
	jr .loop_copy

.sort_cards
	pop af
	ld a, $ff
	ld [bc], a
	ldh a, [hWhoseTurn]
	push af
	ld a, OPPONENT_TURN
	ldh [hWhoseTurn], a
	call SortCardsInDuelTempListByID
	pop af
	ldh [hWhoseTurn], a

	ld hl, wcf17
	ld de, wDuelTempList
.asm_a058
	ld a, [de]
	cp $ff
	jr z, .done
	ld c, a
	ld b, $0
	push hl
	ld hl, wOpponentDeck
	add hl, bc
	ld a, [hl]
	pop hl
	ld [hli], a
	inc de
	jr .asm_a058

.done
	xor a
	ld [hl], a
	ret
; 0xa06e

; goes through list in wcf17, and for each card in it
; creates list in wTempHandCardList of all unique cards
; it finds (assuming wcf17 is sorted by ID)
; also counts the number of the different cards
Func_a06e: ; a06e (2:606e)
	ld b, 0
	ld c, $0
	ld hl, wcf17
	ld de, wTempHandCardList
.loop
	ld a, [hli]
	cp c
	jr z, .loop
	ld c, a
	ld [de], a
	inc de
	or a
	jr z, .done
	inc b
	jr .loop
.done
	ld a, b
	ld [wced9], a
	ret
; 0xa08a

; prints the list of cards visible in the window
; of the confirmation screen
; card info is presented with name, level and
; its count preceded by "x"
PrintConfirmationCardList: ; a08a (2:608a)
	push bc
	ld hl, wced0
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coord
	ld c, e
	dec c
	ld a, [wcea1]
	or a
	jr z, .no_cursor
	ld a, SYM_CURSOR_U
	jr .got_cursor_tile_1
.no_cursor
	ld a, SYM_SPACE
.got_cursor_tile_1
	call WriteByteToBGMap0

; iterates by decreasing value in wcecb
; by 1 until it reaches 0
	ld a, [wcea1]
	ld c, a
	ld b, $0
	ld hl, wTempHandCardList
	add hl, bc
	ld a, [wcecb]
.loop_cards
	push de
	or a
	jr z, .exit_loop
	ld b, a
	ld a, [hli]
	or a
	jr z, .no_more_cards
	ld e, a
	call Func_9a59
	call LoadCardDataToBuffer1_FromCardID
	; places in wDefaultText the card's name and level
	; then appends at the end "x" with the count of that card
	; draws the card's type icon as well
	ld a, 13
	push bc
	push hl
	push de
	call CopyCardNameAndLevel
	pop de
	call .PrintCardCount
	pop hl
	pop bc
	pop de
	call .DrawCardTypeIcon
	push hl
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText
	pop hl
	ld a, b
	dec a
	inc e
	inc e
	jr .loop_cards

.exit_loop
	ld a, [hli]
	or a
	jr z, .no_more_cards
	pop de
	xor a
	ld [wcecd], a
	ld a, SYM_CURSOR_D
	jr .got_cursor_tile_2

.no_more_cards
	pop de
	ld a, $01
	ld [wcecd], a
	ld a, SYM_SPACE
.got_cursor_tile_2
	ld b, 19 ; x coord
	ld c, e
	dec c
	dec c
	call WriteByteToBGMap0
	pop bc
	ret

; prints the card count preceded by a cross
; for example "x42"
.PrintCardCount
	push af
	push bc
	push de
	push hl
.loop_search
	ld a, [hl]
	or a
	jr z, .found_card_id
	inc hl
	jr .loop_search
.found_card_id
	call Func_9850
	ld [hl], TX_SYMBOL
	inc hl
	ld [hl], SYM_CROSS
	inc hl
	call ConvertToNumericalDigits
	ld [hl], TX_END
	pop hl
	pop de
	pop bc
	pop af
	ret

; draws the icon corresponding to the loaded card's type
; can be any of Pokemon stages (basic, 1st and 2nd stage)
; Energy or Trainer
; draws it 2 tiles to the left and 1 up to
; the current coordinate in de
.DrawCardTypeIcon
	push hl
	push de
	push bc
	ld a, [wLoadedCard1Type]
	cp TYPE_ENERGY
	jr nc, .not_pkmn_card

; pokemon card
	ld a, [wLoadedCard1Stage]
	ld b, a
	add b
	add b
	add b ; *4
	add ICON_TILE_BASIC_POKEMON
	jr .got_tile

.not_pkmn_card
	cp TYPE_TRAINER
	jr nc, .trainer_card

; energy card
	sub TYPE_ENERGY
	ld b, a
	add b
	add b
	add b ; *4
	add ICON_TILE_FIRE
	jr .got_tile

.trainer_card
	ld a, ICON_TILE_TRAINER
.got_tile
	dec d
	dec d
	dec e
	push af
	lb hl, 1, 2
	lb bc, 2, 2
	call FillRectangle
	pop af

	call GetCardTypeIconPalette
	ld b, a
	ld a, [wConsole]
	cp CONSOLE_CGB
	jr nz, .skip_pal
	ld a, b
	lb bc, 2, 2
	lb hl, 0, 0
	call BankswitchVRAM1
	call FillRectangle
	call BankswitchVRAM0
.skip_pal
	pop bc
	pop de
	pop hl
	ret
; 0xa173

; returns in a the BG Pal corresponding to the
; card type icon in input register a
; if not found, returns $00
GetCardTypeIconPalette: ; a173 (2:6173)
	push bc
	push hl
	ld b, a
	ld hl, .CardTypeIconPalettes
.loop
	ld a, [hli]
	or a
	jr z, .done
	cp b
	jr z, .done
	inc hl
	jp .loop ; should be jr
.done
	ld a, [hl]
	pop hl
	pop bc
	ret

.CardTypeIconPalettes
; icon tile, BG pal
	db ICON_TILE_FIRE,            1
	db ICON_TILE_GRASS,           2
	db ICON_TILE_LIGHTNING,       1
	db ICON_TILE_WATER,           2
	db ICON_TILE_FIGHTING,        3
	db ICON_TILE_PSYCHIC,         3
	db ICON_TILE_COLORLESS,       0
	db ICON_TILE_ENERGY,          2
	db ICON_TILE_BASIC_POKEMON,   2
	db ICON_TILE_STAGE_1_POKEMON, 2
	db ICON_TILE_STAGE_2_POKEMON, 1
	db ICON_TILE_TRAINER,         2
	db $00, $ff
; 0xa1a2

Func_a1a2: ; a1a2 (2:61a2)
	ld hl, wcf17
	ld a, DECK_SIZE + $15
	call ClearNBytesFromHL
	ld a, $ff
	ld [wceb1], a
	ld hl, .text
	ld de, wcfb9
	call CopyListFromHLToDE
	ld hl, .unknown_a1d8
	call Func_8d9d
	call Func_9345
	ret

.text
	text "Cards chosen to send"
	db TX_END

.unknown_a1d8
	db $3c, $3c, $00
	dw HandleSendDeckConfigurationMenu
	dw SendDeckConfigurationMenu_TransitionTable
; 0xa1df

SendDeckConfigurationMenu_TransitionTable: ; a1df (2:61df)
	cursor_transition $10, $20, $00, $00, $00, $01, $02
	cursor_transition $48, $20, $00, $01, $01, $02, $00
	cursor_transition $80, $20, $00, $02, $02, $00, $01

SendDeckConfigurationMenuData: ; a1f4 (2:61f4)
	textitem  2, 2, ConfirmText
	textitem  9, 2, SendText
	textitem 16, 2, CancelText
	db $ff

HandleSendDeckConfigurationMenu: ; a201 (2:6201)
	ld de, $0
	lb bc, 20, 6
	call DrawRegularTextBox
	ld hl, SendDeckConfigurationMenuData
	call PlaceTextItems
	ld a, $ff
	ld [wDuelInitialPrizesUpperBitsSet], a
.loop_input
	ld a, $01
	ld [wVBlankOAMCopyToggle], a
	call DoFrame
	call Func_89ae
	jr nc, .loop_input
	ld [wced6], a
	cp $ff
	jr nz, .asm_a23b
	call DrawCardTypeIconsAndPrintCardCounts
	ld a, [wced4]
	ld [wNamingScreenCursorY], a
	ld a, [wced3]
	call Func_993d
	jp Func_9345.skip_draw
.asm_a23b
	ld hl, .func_table
	call JumpToFunctionInTable
	jp Func_9461.asm_9475

.func_table
	dw ConfirmDeckConfiguration    ; Confirm
	dw SendDeckConfiguration       ; Send
	dw CancelSendDeckConfiguration ; Cancel
; 0xa24a

SendDeckConfiguration: ; a24a (2:624a)
	ld a, [wcf17]
	or a
	jr z, CancelSendDeckConfiguration
	xor a
	ld [wcea1], a
	ld hl, Data_b04a
	call Func_9a6d
	ld hl, wcf17
	ld de, wDuelTempList
	call CopyListFromHLToDE
	call Func_b131
	call Func_b088
	call EnableLCD
	ldtx hl, SendTheseCardsText
	call YesOrNoMenuWithText
	jr nc, .asm_a279
	add sp, $2
	jp Func_9345.skip_count
.asm_a279
	add sp, $2
	scf
	ret

CancelSendDeckConfiguration: ; a27d (2:627d)
	add sp, $2
	or a
	ret
; 0xa281

; copies b bytes from hl to de
CopyNBytesFromHLToDE: ; a281 (2:6281)
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, CopyNBytesFromHLToDE
	ret
; 0xa288

Func_a288: ; a288 (2:6288)
	INCROM $a288, $a3ca

Func_a3ca: ; a3ca (2:63ca)
	ld [hffb5], a
	ld hl, sCardCollection
	ld de, wTempCardCollection
	ld b, $ff
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM
; deck_1
	ld a, [hffb5] ; should be ldh
	bit 0, a
	jr z, .deck_2
	ld de, sDeck1Cards
	call GetDeckCardCounts
.deck_2
	ld a, [hffb5] ; should be ldh
	bit 1, a
	jr z, .deck_3
	ld de, sDeck2Cards
	call GetDeckCardCounts
.deck_3
	ld a, [hffb5] ; should be ldh
	bit 2, a
	jr z, .deck_4
	ld de, sDeck3Cards
	call GetDeckCardCounts
.deck_4
	ld a, [hffb5] ; should be ldh
	bit 3, a
	ret z
	ld de, sDeck4Cards
	call GetDeckCardCounts
	ret
; 0xa412

; goes through deck cards in de
; and gets the count of each card ID
; in wTempCardCollection in card collection order
GetDeckCardCounts: ; a412 (2:6412)
	call EnableSRAM
	ld bc, wTempCardCollection
	ld h, DECK_SIZE
.loop
	ld a, [de]
	inc de
	or a
	jr z, .done
	push hl
	ld h, $0
	ld l, a
	add hl, bc
	inc [hl]
	pop hl
	dec h
	jr nz, .loop
.done
	call DisableSRAM
	ret
; 0xa42d

; prints the name, level and storage count of the cards
; that are visible in the list window
; in the form:
; CARD NAME/LEVEL X
; where X is the current count of that card
PrintCardSelectionList: ; a42d (2:642d)
	push bc
	ld hl, wced0
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, 19 ; x coord
	ld c, e
	ld a, [wcea1]
	or a
	jr z, .alternate_cursor_tile
	ld a, SYM_CURSOR_U
	jr .got_cursor_tile_1
.alternate_cursor_tile
	ld a, [wCursorAlternateTile]
.got_cursor_tile_1
	call WriteByteToBGMap0

; iterates by decreasing value in wcecb
; by 1 until it reaches 0
	ld a, [wcea1]
	ld c, a
	ld b, $0
	ld hl, wFilteredCardList
	add hl, bc
	ld a, [wcecb]
.loop_filtered_cards
	push de
	or a
	jr z, .exit_loop
	ld b, a
	ld a, [hli]
	or a
	jr z, .invalid_card ; card ID of 0
	ld e, a
	call Func_9a59
	call LoadCardDataToBuffer1_FromCardID
	; places in wDefaultText the card's name and level
	; then appends at the end the count of that card
	; in the card storage
	ld a, 14
	push bc
	push hl
	push de
	call CopyCardNameAndLevel
	pop de
	call AppendOwnedCardCountNumber
	pop hl
	pop bc
	pop de
	push hl
	call InitTextPrinting
	ld hl, wDefaultText
	jr .process_text
.invalid_card
	pop de
	push hl
	call InitTextPrinting
	ld hl, Text_9a36
.process_text
	call ProcessText
	pop hl

	ld a, b
	dec a
	inc e
	inc e
	jr .loop_filtered_cards

.exit_loop
	ld a, [hli]
	or a
	jr z, .cannot_scroll
	pop de
; draw down cursor because
; there are still more cards
; to be scrolled down
	xor a
	ld [wcecd], a
	ld a, SYM_CURSOR_D
	jr .got_cursor_tile_2
.cannot_scroll
	pop de
	ld a, $01
	ld [wcecd], a
	ld a, [wCursorAlternateTile]
.got_cursor_tile_2
	ld b, 19 ; x coord
	ld c, e
	dec c
	dec c
	call WriteByteToBGMap0
	pop bc
	ret
; 0xa4ae

; appends the card count given in register e
; to the list in hl, in numerical form
; (i.e. its numeric symbol representation)
AppendOwnedCardCountNumber: ; a4ae (2:64ae)
	push af
	push bc
	push de
	push hl
; increment hl until end is reached ($00 byte)
.loop
	ld a, [hl]
	or a
	jr z, .end
	inc hl
	jr .loop
.end
	call GetOwnedCardCount
	call ConvertToNumericalDigits
	ld [hl], $00 ; insert byte terminator
	pop hl
	pop de
	pop bc
	pop af
	ret
; 0xa4c6

	INCROM $a4c6, $a913

Func_a913: ; a913 (2:6913)
	INCROM $a913, $ad51

Func_ad51: ; ad51 (2:6d51)
	INCROM $ad51, $adfe

Func_adfe: ; adfe (2:6dfe)
	INCROM $adfe, $af1d

Func_af1d: ; af1d (2:6f1d)
	xor a
	ld [wTileMapFill], a
	call ZeroObjectPositions
	call EmptyScreen
	ld a, $1
	ld [wVBlankOAMCopyToggle], a
	call LoadSymbolsFont
	bank1call SetDefaultPalettes

	lb de, $3c, $bf
	call SetupText
	lb de, 3, 1
	call InitTextPrinting
	ldtx hl, ProceduresForSendingCardsText
	call ProcessTextFromID
	lb de, 1, 3
	call InitTextPrinting
	ldtx hl, CardSendingProceduresText
	ld a, $01
	ld [wLineSeparation], a
	call ProcessTextFromID
	xor a
	ld [wLineSeparation], a
	ldtx hl, PleaseReadTheProceduresForSendingCardsText
	call DrawWideTextBox_WaitForInput

	call EnableLCD
	call Func_a1a2
	jr c, .asm_af6b
	ld a, $01
	or a
	ret

.asm_af6b
	ld hl, wcf17
	ld de, wDuelTempList
	call CopyListFromHLToDE
	xor a
	ld [wNameBuffer], a
	bank1call Func_756c
	ret c
	call EnableSRAM
	ld hl, wcf17
	call Func_910a
	call DisableSRAM
	call SaveGame
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	xor a
	ret

; never reached
	scf
	ret
; 0xaf98

Func_af98: ; af98 (2:6f98)
	xor a
	ld [wDuelTempList], a
	ld [wNameBuffer], a
	bank1call Func_7567
	ret c

	call EnableSRAM
	ld hl, wDuelTempList
	call Func_9120
	call DisableSRAM
	call SaveGame
	xor a
	ld [wcea1], a
	ld hl, Data_b04a
	call Func_9a6d
	call Func_b141
	call Func_b088
	call EnableLCD
	ld a, [wceab + 3]
	ld [wcfe4 + 2], a
	ld hl, wcecb
	cp [hl]
	jr nc, .asm_afd4
	ld [wNamingScreenKeyboardHeight], a
.asm_afd4
	ld hl, Func_b053
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d

	xor a
	ld [wced2], a
.asm_afe2
	call DoFrame
	call Func_9b25
	jr c, .asm_b02f
	call Func_9eb8
	jr c, .asm_afe2
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_afe2
.asm_aff5
	ld a, $01
	call PlaySFXConfirmOrCancel
	ld a, [wNamingScreenCursorY]
	ld [wced4], a
	ld de, wFilteredCardList
	ld hl, wcfd8
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_9c3f
	call Func_b141
	call PrintCardSelectionList
	call EnableLCD
	ld hl, Data_b04a
	call Func_9a6d
	ld a, [wceab + 3]
	ld hl, wcecb
	cp [hl]
	jr nc, .asm_b027
	ld [wNamingScreenKeyboardHeight], a
.asm_b027
	ld a, [wced4]
	ld [wNamingScreenCursorY], a
	jr .asm_afe2
.asm_b02f
	call Func_9c0e
	ld a, [wNamingScreenCursorY]
	ld [wced4], a
	ld a, [hffb3]
	cp $ff
	jr nz, .asm_aff5
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	or a
	ret

Data_b04a: ; b04a (2:704a)
	db $01, $03, $02, $00, $05, $0f, $00, $00, $00

Func_b053: ; b053 (2:7053)
	ld hl, hffb0
	ld [hl], $01
	lb de, 1, 1
	call InitTextPrinting
	ldtx hl, CardReceivedText
	call ProcessTextFromID
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	xor a
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	lb de, 1, 14
	call InitTextPrinting
	ldtx hl, ReceivedTheseCardsFromText
	call PrintTextNoDelay
	ld hl, hffb0
	ld [hl], $00
	jp PrintCardSelectionList
; 0xb088

Func_b088: ; b088 (2:7088)
	ld a, $ff
	ld hl, wTempCardCollection
	call ClearNBytesFromHL
	ld de, wDuelTempList
	call .Func_b0b2
	ld a, $ff
	call .Func_b0c0
	ld a, $05
	ld [wcecb], a
	lb de, 2, 3
	ld hl, wced0
	ld [hl], e
	inc hl
	ld [hl], d
	ld a, SYM_BOX_RIGHT
	ld [wCursorAlternateTile], a
	call PrintCardSelectionList
	ret

.Func_b0b2
	ld bc, wTempCardCollection
.loop
	ld a, [de]
	inc de
	or a
	ret z
	ld h, $00
	ld l, a
	add hl, bc
	inc [hl]
	jr .loop

.Func_b0c0
	push af
	push bc
	push de
	push hl
	push af
	ld a, DECK_SIZE
	ld hl, wOwnedCardsCountList
	call ClearNBytesFromHL
	ld a, DECK_SIZE
	ld hl, wFilteredCardList
	call ClearNBytesFromHL
	pop af
	ld hl, $0
	ld de, $0
	ld b, a
.asm_b0dd
	inc e
	call GetCardType
	jr c, .asm_b119
	ld c, a
	ld a, b
	cp $ff
	jr z, .asm_b0fc
	and $20
	cp $20
	jr z, .asm_b0f5
	ld a, c
	cp b
	jr nz, .asm_b0dd
	jr .asm_b0fc
.asm_b0f5
	ld a, c
	and TYPE_ENERGY
	cp TYPE_ENERGY
	jr nz, .asm_b0dd
.asm_b0fc
	push bc
	push hl
	ld bc, wFilteredCardList
	add hl, bc
	ld [hl], e
	ld hl, wTempCardCollection
	add hl, de
	ld a, [hl]
	and $7f
	pop hl
	or a
	jr z, .asm_b116
	push hl
	ld bc, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	inc l
.asm_b116
	pop bc
	jr .asm_b0dd

.asm_b119
	ld a, l
	ld [wceab + 3], a
	xor a
	ld c, l
	ld b, h
	ld hl, wFilteredCardList
	add hl, bc
	ld [hl], a
	ld a, $ff
	ld hl, wOwnedCardsCountList
	add hl, bc
	ld [hl], a
	pop hl
	pop de
	pop bc
	pop af
	ret
; 0xb131

Func_b131: ; b131 (2:7131)
	call Func_b141.Func_b167
	lb de, 1, 1
	call InitTextPrinting
	ldtx hl, CardToSendText
	call ProcessTextFromID
	ret
; 0xb141

Func_b141: ; b141 (2:7141)
	call .Func_b167
	lb de, 1, 1
	call InitTextPrinting
	ldtx hl, CardReceivedText
	call ProcessTextFromID
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	xor a
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	ldtx hl, ReceivedTheseCardsFromText
	call DrawWideTextBox_PrintText
	ret

.Func_b167
	call Set_OBJ_8x8
	call Func_8d78
	ld de, $0
	lb bc, 20, 13
	call DrawRegularTextBox
	ret
; 0xb177

Func_b177: ; b177 (2:7177)
	ld a, [wd10e]
	and $03
	ld hl, .FunctionTable
	call JumpToFunctionInTable
	jr c, .asm_b18f
	or a
	jr nz, .asm_b18f
	xor a
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	ret
.asm_b18f
	ld a, $ff
	ld [wd10e], a
	ret

.FunctionTable
	dw Func_af1d
	dw Func_af98
	dw Func_bc04
	dw Func_bc7a
; 0xb19d

Func_b19d: ; b19d (2:719d)
	xor a
	ld [wcea1], a
	ldtx de, DeckSaveMachineText
	ld hl, wd0a2
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_b379
	ld a, $3c
	ld [wd0a5], a
	xor a
.asm_b1b3
	ld hl, Data_b6fb
	call Func_9a6d
	call Func_b704
	call Func_b545
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseSelectDeckText
	call Func_b285
	call Func_b29f
	jr c, .asm_b1b3
	cp $ff
	ret z
	ld b, a
	ld a, [wcea1]
	add b
	ld [wd088], a
	call ResetCheckMenuCursorPositionAndBlink
	call DrawWideTextBox
	ld hl, Unknown_b274
	call PlaceTextItems
.asm_b1e7
	call DoFrame
	call HandleCheckMenuInput
	jp nc, .asm_b1e7
	cp $ff
	jr nz, .asm_b1fa
	ld a, [wd086]
	jp .asm_b1b3

.asm_b1fa
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	or a
	jr nz, .asm_b22c
	call Func_b35b
	jr nc, .asm_b216
	call Func_b592
	ld a, [wd086]
	jp c, .asm_b1b3
	jr .asm_b25e

.asm_b216
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	ld a, [wd086]
	jr c, .asm_b1b3
	call Func_b592
	ld a, [wd086]
	jp c, .asm_b1b3
	jr .asm_b25e

.asm_b22c
	cp $1
	jr nz, .asm_b24c
	call Func_b35b
	jr c, .asm_b240
	call Func_b6ca
	ld a, [wd086]
	jp c, .asm_b1b3
	jr .asm_b25e

.asm_b240
	ld hl, WaitForVBlank
	call DrawWideTextBox_WaitForInput
	ld a, [wd086]
	jp .asm_b1b3

.asm_b24c
	cp $2
	jr nz, .asm_b273
	call Func_b35b
	jr c, .asm_b240
	call Func_b7c6
	ld a, [wd086]
	jp nc, .asm_b1b3

.asm_b25e
	ld a, [wd087]
	ld [wcea1], a
	call Func_b379
	call Func_b704
	call Func_b545
	ld a, [wd086]
	jp .asm_b1b3

.asm_b273
	ret

Unknown_b274: ; b274 (2:7274)
	INCROM $b274, $b285

Func_b285: ; b285 (2:7285)
	ld a, $05
	ld [wNamingScreenKeyboardHeight], a
	ld hl, wd0a7
	ld [hl], e
	inc hl
	ld [hl], d
	ld hl, Func_b403
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d
	xor a
	ld [wced2], a
	ret
; 0xb29f

Func_b29f: ; b29f (2:729f)
	INCROM $b29f, $b35b

Func_b35b: ; b35b (2:735b)
	INCROM $b35b, $b379

Func_b379: ; b379 (2:7379)
	INCROM $b379, $b3b3

Func_b3b3: ; b3b3 (2:73b3)
	lb de, 1, 0
	call InitTextPrinting
	ld hl, wd0a2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call ProcessTextFromID
	ret
; 0xb3c3

	INCROM $b3c3, $b3e5

Func_b3e5: ; b3e5 (2:73e5)
	ld a, [wcea1]
	ld de, $202
	ld b, $05
.asm_b3ed
	push af
	push bc
	push de
	call Func_b424
	pop de
	pop bc
	pop af
	ret c
	dec b
	ret z
	inc a
	inc e
	inc e
	jr .asm_b3ed
; 0xb3fe

Unknown_b3fe: ; b3fe (2:73fe)
	INCROM $b3fe, $b403

Func_b403: ; b403 (2:7403)
	call Func_b704
	ld hl, hffb0
	ld [hl], $01
	call Func_b3b3
	lb de, 1, 14
	call InitTextPrinting
	ld hl, wd0a7
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call ProcessTextFromID
	ld hl, hffb0
	ld [hl], $00
	jr Func_b3e5
; 0xb424

Func_b424: ; b424 (2:7424)
	ld b, a
	push bc
	ld hl, wDefaultText
	inc a
	call ConvertToNumericalDigits
	ld [hl], $77
	inc hl
	ld [hl], $00
	call InitTextPrinting
	ld hl, wDefaultText
	call ProcessText
	pop af
	push af
	sla a
	ld l, a
	ld h, $00
	ld bc, wd00d
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc d
	inc d
	inc d
	push de
	call Func_92be
	pop de
	pop bc
	jr nc, .asm_b46b
	call InitTextPrinting
	ldtx hl, Text025b
	call ProcessTextFromID
	ld d, 13
	inc e
	call InitTextPrinting
	ld hl, Text_b4d4
	call ProcessText
	scf
	ret

.asm_b46b
	push de
	push bc
	ld d, 18
	call InitTextPrinting
	ld a, $00
	call Func_b625
	pop bc
	ld hl, wDefaultText
	jr c, .asm_b482
	ld de, $35f
	jr .asm_b4c2

.asm_b482
	push bc
	ld a, $ff
	call Func_b625
	jr c, .asm_b490
	pop bc
	ld de, $360
	jr .asm_b4c2

.asm_b490
	ld de, $6c
	call Func_22ca
	pop bc
	pop de
	push bc
	ld d, 17
	inc e
	call InitTextPrinting
	pop bc
	call Func_b4e1
	call CalculateOnesAndTensDigits
	ld hl, wOnesAndTensPlace
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld hl, wDefaultText
	ld [hl], TX_SYMBOL
	inc hl
	ld [hli], a
	ld [hl], TX_SYMBOL
	inc hl
	ld a, b
	ld [hli], a
	ld [hl], TX_END
	ld hl, wDefaultText
	call ProcessText
	or a
	ret

.asm_b4c2
	call Func_22ca
	pop de
	ld d, 13
	inc e
	call InitTextPrinting
	ld hl, Text_b4d4
	call ProcessText
	or a
	ret
; 0xb4d4

Text_b4d4: ; b4d4 (2:74d4)
	db TX_SYMBOL, TX_END
	db TX_SYMBOL, TX_END
	db TX_SYMBOL, TX_END
	db TX_SYMBOL, TX_END
	db TX_SYMBOL, TX_END
	db TX_SYMBOL, TX_END
	db TX_END
; 0xb4e1

Func_b4e1: ; b4e1 (2:74e1)
	push bc
	call Func_b644
	call Func_a3ca
	call Func_b664
	pop bc
	sla b
	ld c, b
	ld b, $00
	ld hl, wd00d
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, $18
	add hl, bc
	call EnableSRAM
	ld de, wTempCardCollection
	ld bc, $0
.asm_b505
	inc b
	ld a, DECK_SIZE
	cp b
	jr c, .asm_b520
	ld a, [hli]
	push hl
	ld l, a
	ld h, $00
	add hl, de
	ld a, [hl]
	and $7f
	or a
	jr z, .asm_b51c
	dec a
	ld [hl], a
	pop hl
	jr .asm_b505
.asm_b51c
	inc c
	pop hl
	jr .asm_b505
.asm_b520
	ld a, c
	call DisableSRAM
	ret
; 0xb525

	INCROM $b525, $b545

Func_b545: ; b545 (2:7545)
	INCROM $b545, $b592

Func_b592: ; b592 (2:7592)
	INCROM $b592, $b611

Func_b611: ; b611 (2:7611)
	push af
	push hl
	ld a, [wd088]
	sla a
	ld e, a
	ld d, $00
	ld hl, wd00d
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	pop af
	ret
; 0xb625

Func_b625: ; b625 (2:7625)
	INCROM $b625, $b644

Func_b644: ; b644 (2:7644)
	INCROM $b644, $b653

Func_b653: ; b653 (2:7653)
	INCROM $b653, $b664

Func_b664: ; b664 (2:7664)
	push af
	push bc
	ldh a, [hBankSRAM]
	ld b, a
	ld a, [wd0a4]
	cp b
	jr z, .asm_b672
	call BankswitchSRAM
.asm_b672
	pop bc
	pop af
	ret
; 0xb675

	INCROM $b675, $b6ca

Func_b6ca: ; b6ca (2:76ca)
	INCROM $b6ca, $b6fb

Data_b6fb: ; b6fb (2:76fb)
	db $01, $02, $02, $00, $05, $0f, $00, $00, $00

Func_b704: ; b704 (2:7704)
	INCROM $b704, $b7c6

Func_b7c6: ; b7c6 (2:77c6)
	INCROM $b7c6, $ba04

Func_ba04: ; ba04 (2:7a04)
	ld a, [wd0a9]
	ld hl, Data_bb83
	sla a
	ld c, a
	ld b, $0
	add hl, bc
	ld de, wd0a2
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	xor a
	ld [wcea1], a
	call Func_bb97
	ld a, $5
	ld [wd0a5], a
	xor a
	; fallthrough

Func_ba25: ; ba25 (2:7a25)
	ld hl, Func_bb6e
	call InitializeMenuParameters
	ldtx hl, PleaseSelectDeckText
	call DrawWideTextBox_PrintText
	ld a, $5
	ld [wNamingScreenKeyboardHeight], a
	ld hl, Unknown_b3fe
	ld d, h
	ld a, l
	ld hl, wcece
	ld [hli], a
	ld [hl], d
.asm_ba40
	call DoFrame
	call HandleMenuInput
	jr c, .asm_baa3
	ldh a, [hDPadHeld]
	and D_UP | D_DOWN
	jr z, .asm_ba4e

.asm_ba4e
	ldh a, [hDPadHeld]
	and START
	jr z, .asm_ba40
	ld a, [wcea1]
	ld [wd087], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wd086], a
	add b
	ld c, a
	inc a
	or $80
	ld [wceb1], a
	sla c
	ld b, $0
	ld hl, wd00d
	add hl, bc
	call Func_b653
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, $0018
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call Func_b644
	or a
	jr z, .asm_ba40
	ld a, $1
	call PlaySFXConfirmOrCancel
	call Func_b653
	call Func_8e1f
	call Func_b644
	ld a, [wd087]
	ld [wcea1], a
	call Func_bb97
	ld a, [wd086]
	jp Func_ba25

.asm_baa3
	call DrawCursor2
	ld a, [wcea1]
	ld [wd087], a
	ld a, [wCurMenuItem]
	ld [wd086], a
	ldh a, [hCurMenuItem]
	cp $ff
	jp z, .asm_bb0d
	ld [wd088], a
	call ResetCheckMenuCursorPositionAndBlink
	xor a
	ld [wce5e], a
	call DrawWideTextBox
	ld hl, Data_bb76
	call PlaceTextItems
.asm_bacc
	call DoFrame
	call HandleCheckMenuInput_YourOrOppPlayArea
	jp nc, .asm_bacc
	cp $ff
	jr nz, .asm_badf
	ld a, [wd086]
	jp Func_ba25

.asm_badf
	ld a, [wCheckMenuCursorYPosition]
	sla a
	ld hl, wCheckMenuCursorXPosition
	add [hl]
	or a
	jr nz, .asm_bb09
	call Func_b653
	call Func_b7c6
	call Func_b644
	ld a, [wd086]
	jp nc, Func_ba25
	ld a, [wd087]
	ld [wcea1], a
	call Func_bb97
	ld a, [wd086]
	jp Func_ba25

.asm_bb09
	cp $1
	jr nz, .asm_bb12
.asm_bb0d
	xor a
	ld [wd0a4], a
	ret

.asm_bb12
	ld a, [wcea1]
	ld [wd087], a
	ld b, a
	ld a, [wCurMenuItem]
	ld [wd086], a
	add b
	ld c, a
	ld [wceb1], a
	sla c
	ld b, $0
	ld hl, wd00d
	add hl, bc
	push hl
	ld hl, wd0aa
	add hl, bc
	ld bc, wcfda
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	pop hl
	call Func_b653
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld bc, $0018
	add hl, bc
	ld d, h
	ld e, l
	ld a, [hl]
	pop hl
	call Func_b644
	or a
	jp z, .asm_ba40
	ld a, $1
	call PlaySFXConfirmOrCancel
	call Func_b653
	xor a
	call Func_adfe
	call Func_b644
	ld a, [wd087]
	ld [wcea1], a
	call Func_bb97
	ld a, [wd086]
	jp Func_ba25

Func_bb6e: ; bb6e (2:7b6e)
	INCROM $bb6e, $bb76

Data_bb76: ; bb76 (2:7b76)
	INCROM $bb76, $bb83

Data_bb83: ; bb83 (2:7b83)
	tx FightingMachineText
	tx RockMachineText
	tx WaterMachineText
	tx LightningMachineText
	tx GrassMachineText
	tx PsychicMachineText
	tx ScienceMachineText
	tx FireMachineText
	tx AutoMachineText
	tx LegendaryMachineText

Func_bb97: ; bb97 (2:7b97)
	INCROM $bb97, $bc04

Func_bc04: ; bc04 (2:7c04)
	xor a
	ld [wcea1], a
	ldtx de, DeckSaveMachineText
	ld hl, wd0a2
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_b379
	ld a, DECK_SIZE
	ld [wd0a5], a
	xor a
.asm_bc1a
	ld hl, Data_b6fb
	call Func_9a6d
	call Func_b704
	call Func_b545
	ldtx hl, PleaseChooseADeckConfigurationToSendText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseADeckConfigurationToSendText
	call Func_b285
.asm_bc32
	call Func_b29f
	jr c, .asm_bc1a
	cp $ff
	jr nz, .asm_bc3f
	ld a, $01
	or a
	ret
.asm_bc3f
	ld b, a
	ld a, [wcea1]
	add b
	ld [wd088], a
	call Func_b35b
	jr c, .asm_bc32

	call Func_b611
	ld l, e
	ld h, d
	ld de, wDuelTempList
	ld b, $54
	call EnableSRAM
	call CopyNBytesFromHLToDE
	call DisableSRAM

	xor a
	ld [wNameBuffer], a
	bank1call Func_7562
	ret c

	call Func_b611
	ld l, e
	ld h, d
	ld de, wDefaultText
	call EnableSRAM
	call CopyListFromHLToDE
	call DisableSRAM
	or a
	ret
; 0xbc7a

Func_bc7a: ; bc7a (2:7c7a)
	xor a
	ld [wcea1], a
	ldtx de, DeckSaveMachineText
	ld hl, wd0a2
	ld [hl], e
	inc hl
	ld [hl], d
	call Func_b379
	ld a, DECK_SIZE
	ld [wd0a5], a
	xor a
.asm_bc90
	ld hl, Data_b6fb
	call Func_9a6d
	call Func_b704
	call Func_b545
	ldtx hl, PleaseChooseASaveSlotText
	call DrawWideTextBox_PrintText
	ldtx de, PleaseChooseASaveSlotText
	call Func_b285
	call Func_b29f
	jr c, .asm_bc90
	cp $ff
	jr nz, .asm_bcb5
	ld a, $01
	or a
	ret
.asm_bcb5
	ld b, a
	ld a, [wcea1]
	add b
	ld [wd088], a
	call Func_b35b
	jr nc, .asm_bcc4
	jr .asm_bcd1
.asm_bcc4
	ldtx hl, OKIfFileDeletedText
	call YesOrNoMenuWithText
	jr nc, .asm_bcd1
	ld a, [wNamingScreenCursorY]
	jr .asm_bc90
.asm_bcd1
	xor a
	ld [wDuelTempList], a
	ld [wNameBuffer], a
	bank1call Func_755d
	ret c
	call EnableSRAM
	ld hl, wDuelTempList
	call Func_b611
	ld b, $54
	call CopyNBytesFromHLToDE
	call DisableSRAM
	call SaveGame
	call Func_b379
	ld a, [wNamingScreenCursorY]
	ld hl, Data_b6fb
	call Func_9a6d
	call Func_b704
	call Func_b545
	call Func_9c3a
	ld hl, wNameBuffer
	ld de, wDefaultText
	call CopyListFromHLToDE
	xor a
	ld [wTxRam2 + 0], a
	ld [wTxRam2 + 1], a
	ldtx hl, ReceivedADeckConfigurationFromText
	call DrawWideTextBox_WaitForInput
	call Func_b611
	ld l, e
	ld h, d
	ld de, wDefaultText
	call EnableSRAM
	call CopyListFromHLToDE
	call DisableSRAM
	xor a
	ret
; 0xbd2e

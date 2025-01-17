SetMainSGBBorder: ; 70000 (1c:4000)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; exit if not SGB
	ld b, $1
	ld a, EVENT_RECEIVED_LEGENDARY_CARDS
	farcall GetEventValue
	or a
	jr z, .asm_70013
	ld b, $2
.asm_70013
	ld a, b
	call SetSGBBorder
	ret

SetIntroSGBBorder: ; 70018 (1c:4018)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; exit if not SGB
	ld a, $0
	call SetSGBBorder
	ret

AtrcEnPacket_Disable: ; 70024 (1c:4024)
	sgb ATRC_EN, 1 ; sgb_command, length
	db 1
	ds $0e

; disable Controller Set-up Screen
IconEnPacket: ; 70034 (1c:4034)
	sgb ICON_EN, 3 ; sgb_command, length
	db $01
	ds $0e

; sets SGB border corresponding with value in register a
; $0 = intro
; $1 = medals (gold)
; $2 = medals (blue)
; $3 = debug
SetSGBBorder: ; 70044 (1c:4044)
	push hl
	push bc
	add a ; *2
	ld c, a
	add a ; *4
	add c ; *6
	ld c, a
	ld b, $0
	ld hl, .SGBBorders
	add hl, bc
	call DecompressAndSendSGBBorder
	pop bc
	pop hl
	ret

.SGBBorders
	; tiles, pals (?), map (?)
	dw SGBBorderIntroGfxPointers,  SGBData_BorderIntro3,  SGBData_BorderIntro4
	dw SGBBorderMedalsGfxPointers, SGBData_BorderMedals3, SGBData_BorderMedals5
	dw SGBBorderMedalsGfxPointers, SGBData_BorderMedals4, SGBData_BorderMedals5
	dw SGBBorderDebugGfxPointers,  SGBData_BorderDebug3,  SGBData_BorderDebug4
; 0x7006f

; forces SGB border intro
; unreferenced?
Func_7006f: ; 7006f (1c:406f)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; exit if not SGB
	ld de, SGBData_BorderIntro3
	ld hl, SGBData_BorderIntro4
	call SetMainSGBBorderPalsAndMap
	call Func_701c0
	ret
; 0x70082

DecompressAndSendSGBBorder: ; 70082 (1c:4082)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; exit if not SGB
	push hl
	push bc
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	call Func_700a3
	pop hl
	inc hl

	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call SetMainSGBBorderPalsAndMap
	call Func_701c0
	pop bc
	pop hl
	ret

Func_700a3: ; 700a3 (1c:40a3)
	push hl
	push bc
	push de
	push hl
	call Func_70136
	pop hl

	push hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, v0Tiles1
	call DecompressSGBData
	call PrepareBGMapForSendingSGBBorder
	ld hl, ChrTrnPacket_BGTiles1
	call SendSGBBorder
	pop hl

	ld de, 2
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	or [hl]
	jr z, .asm_700da
	call Func_70136
	dec hl
	ld de, v0Tiles1
	call DecompressSGBData
	ld hl, ChrTrnPacket_BGTiles2
	call SendSGBBorder
.asm_700da
	pop de
	pop bc
	pop hl
	ret

; CHR_TRN: tiles $00-$7F, BG (border) tiles (from SNES $000-$FFF)
ChrTrnPacket_BGTiles1: ; 700de (1c:40de)
	sgb CHR_TRN, 1 ; sgb_command, length
	db 0
	ds $0e

; CHR_TRN: tiles $80-$FF, BG (border) tiles (from SNES $000-$FFF)
ChrTrnPacket_BGTiles2: ; 700ee (1c:40ee)
	sgb CHR_TRN, 1 ; sgb_command, length
	db 1
	ds $0e

; de = pals
; hl = map
SetMainSGBBorderPalsAndMap: ; 700fe (1c:40fe)
	push hl
	push bc
	push de
	push hl
	push de
	push hl ; input hl
	call Func_70136
	pop hl
	ld de, v0Tiles1
	call DecompressSGBData

	pop hl ; input de
	ld de, v0Tiles2
	call DecompressSGBData
	call PrepareBGMapForSendingSGBBorder

	pop hl ; input hl
	call FillSGBBorderMedalSlots
	ld hl, PctTrnPacket
	call SendSGBBorder
	pop de
	pop bc
	pop hl
	ret

; PCT_TRN: read tile map & palette data into VRAM (from SNES $000-$87F)
PctTrnPacket: ; 70126 (1c:4126)
	sgb PCT_TRN, 1 ; sgb_command, length
	ds $0f

Func_70136: ; 70136 (1c:4136)
	push hl
	push bc
	push de
	ldh a, [hSCX]
	ld [wd41d], a
	ldh a, [hSCY]
	ld [wd41e], a
	ld a, [wBGP]
	ld [wd41f], a
	ld a, [wLCDC]
	ld [wd420], a

	di
	ld hl, MaskEnPacket_Freeze_Bank1c
	call SendSGB
	call DisableLCD
	ld a, [wLCDC]
	and LCDC_BGENABLE | LCDC_WINSELECT
	or LCDC_BGON
	ld [wLCDC], a
	ld a, %11100100
	ldh [rBGP], a
	call SetBGP

	xor a
	ldh [hSCX], a
	ldh [rSCX], a
	ldh [hSCY], a
	ldh [rSCY], a
	pop de
	pop bc
	pop hl
	ret

SendSGBBorder: ; 70177 (1c:4177)
	push hl
	push bc
	push de
	push hl
	call EnableLCD
	pop hl
	call SendSGB
	ld a, [wd41d]
	ldh [hSCX], a
	ld a, [wd41e]
	ldh [hSCY], a
	ld a, [wd41f]
	call SetBGP
	ld a, [wd420]
	ld [wLCDC], a
	call DisableLCD
	ei
	pop de
	pop bc
	pop hl
	ret

; MASK_EN on
MaskEnPacket_Freeze_Bank1c: ; 701a0 (1c:41a0)
	sgb MASK_EN, 1 ; sgb_command, length
	db MASK_EN_FREEZE_SCREEN
	ds $0e

; MASK_EN off
MaskEnPacket_Cancel_Bank1c: ; 701b0 (1c:41b0)
	sgb MASK_EN, 1 ; sgb_command, length
	db MASK_EN_CANCEL_MASK
	ds $0e

Func_701c0: ; 701c0 (1c:41c0)
	push hl
	push bc
	call DisableLCD
	xor a
	ld c, $10
	ld hl, v0Tiles2
.asm_701cb
	ld [hli], a
	dec c
	jr nz, .asm_701cb
	ld a, [wTileMapFill]
	push af
	xor a
	ld [wTileMapFill], a
	call EmptyScreen
	pop af
	ld [wTileMapFill], a
	di
	ld hl, MaskEnPacket_Cancel_Bank1c
	call SendSGB
	ei
	pop bc
	pop hl
	ret

; decompresses data pointed by hl to de
DecompressSGBData: ; 701e9 (1c:41e9)
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	or c
	ret z
	push de
	push bc
	ld e, l
	ld d, h
	ld b, HIGH(wDecompressionSecondaryBuffer)
	call InitDataDecompression
	pop bc
	pop de
	call DecompressData
	ret

; fills a 20x13 rectangle in v0BGMap0
; with values ascending bytes starting at $80
PrepareBGMapForSendingSGBBorder: ; 701fe (1c:41fe)
	ld hl, v0BGMap0
	ld de, $000c
	ld a, $80
	ld c, $d
.asm_70208
	ld b, SCREEN_WIDTH
.asm_7020a
	ld [hli], a
	inc a
	dec b
	jr nz, .asm_7020a
	add hl, de
	dec c
	jr nz, .asm_70208
	ret

; iterates all the medals obtained by the player
; and fills the corresponding medal slot in the SGB border
FillSGBBorderMedalSlots: ; 70214 (1c:4214)
; exit if not SGBData_BorderMedals5
	ld a, l
	cp LOW(SGBData_BorderMedals5)
	ret nz
	ld a, h
	cp HIGH(SGBData_BorderMedals5)
	ret nz

	ld hl, .SGBBorderMedalTiles
	ld a, EVENT_MEDAL_FLAGS
	farcall GetEventValue
	ld c, NUM_MEDALS
.loop_medals
	push bc
	push hl
	push af
	bit 7, a
	jr z, .next_medal

	ld c, 3 * 3
.loop_tiles
	push bc
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	pop bc
	dec c
	jr nz, .loop_tiles

.next_medal
	pop af
	rlca
	pop hl
	ld bc, 3 * 3 * 4
	add hl, bc
	pop bc
	dec c
	jr nz, .loop_medals
	ret

border_medal_tile: MACRO
	dw \1 ; VRAM address
	db \2 ; tile
	db \3 ; pal (?)
ENDM

.SGBBorderMedalTiles
; GRASS_MEDAL
	border_medal_tile v0Tiles1 + $182, $3f, $10
	border_medal_tile v0Tiles1 + $184, $40, $10
	border_medal_tile v0Tiles1 + $186, $41, $10
	border_medal_tile v0Tiles1 + $1c2, $42, $10
	border_medal_tile v0Tiles1 + $1c4, $43, $10
	border_medal_tile v0Tiles1 + $1c6, $44, $10
	border_medal_tile v0Tiles1 + $202, $45, $10
	border_medal_tile v0Tiles1 + $204, $46, $10
	border_medal_tile v0Tiles1 + $206, $47, $10

; SCIENCE_MEDAL
	border_medal_tile v0Tiles1 + $282, $48, $10
	border_medal_tile v0Tiles1 + $284, $49, $10
	border_medal_tile v0Tiles1 + $286, $4a, $10
	border_medal_tile v0Tiles1 + $2c2, $4b, $10
	border_medal_tile v0Tiles1 + $2c4, $4c, $10
	border_medal_tile v0Tiles1 + $2c6, $4d, $10
	border_medal_tile v0Tiles1 + $302, $4e, $10
	border_medal_tile v0Tiles1 + $304, $4f, $10
	border_medal_tile v0Tiles1 + $306, $50, $10

; FIRE_MEDAL
	border_medal_tile v0Tiles1 + $382, $51, $10
	border_medal_tile v0Tiles1 + $384, $52, $10
	border_medal_tile v0Tiles1 + $386, $53, $10
	border_medal_tile v0Tiles1 + $3c2, $54, $10
	border_medal_tile v0Tiles1 + $3c4, $55, $10
	border_medal_tile v0Tiles1 + $3c6, $56, $10
	border_medal_tile v0Tiles1 + $402, $57, $10
	border_medal_tile v0Tiles1 + $404, $58, $10
	border_medal_tile v0Tiles1 + $406, $59, $10

; WATER_MEDAL
	border_medal_tile v0Tiles1 + $482, $5a, $10
	border_medal_tile v0Tiles1 + $484, $5b, $10
	border_medal_tile v0Tiles1 + $486, $5c, $10
	border_medal_tile v0Tiles1 + $4c2, $5d, $10
	border_medal_tile v0Tiles1 + $4c4, $5e, $10
	border_medal_tile v0Tiles1 + $4c6, $5f, $10
	border_medal_tile v0Tiles1 + $502, $60, $10
	border_medal_tile v0Tiles1 + $504, $61, $10
	border_medal_tile v0Tiles1 + $506, $62, $10

; LIGHTNING_MEDAL
	border_medal_tile v0Tiles1 + $1b8, $63, $10
	border_medal_tile v0Tiles1 + $1ba, $64, $10
	border_medal_tile v0Tiles1 + $1bc, $65, $10
	border_medal_tile v0Tiles1 + $1f8, $66, $10
	border_medal_tile v0Tiles1 + $1fa, $67, $10
	border_medal_tile v0Tiles1 + $1fc, $68, $10
	border_medal_tile v0Tiles1 + $238, $69, $10
	border_medal_tile v0Tiles1 + $23a, $6a, $10
	border_medal_tile v0Tiles1 + $23c, $6b, $10

; FIGHTING_MEDAL
	border_medal_tile v0Tiles1 + $2b8, $7e, $10
	border_medal_tile v0Tiles1 + $2ba, $7f, $10
	border_medal_tile v0Tiles1 + $2bc, $80, $10
	border_medal_tile v0Tiles1 + $2f8, $81, $10
	border_medal_tile v0Tiles1 + $2fa, $82, $10
	border_medal_tile v0Tiles1 + $2fc, $83, $10
	border_medal_tile v0Tiles1 + $338, $84, $10
	border_medal_tile v0Tiles1 + $33a, $85, $10
	border_medal_tile v0Tiles1 + $33c, $86, $10

; ROCK_MEDAL
	border_medal_tile v0Tiles1 + $3b8, $75, $10
	border_medal_tile v0Tiles1 + $3ba, $76, $10
	border_medal_tile v0Tiles1 + $3bc, $77, $10
	border_medal_tile v0Tiles1 + $3f8, $78, $10
	border_medal_tile v0Tiles1 + $3fa, $79, $10
	border_medal_tile v0Tiles1 + $3fc, $7a, $10
	border_medal_tile v0Tiles1 + $438, $7b, $10
	border_medal_tile v0Tiles1 + $43a, $7c, $10
	border_medal_tile v0Tiles1 + $43c, $7d, $10

; PSYCHIC_MEDAL
	border_medal_tile v0Tiles1 + $4b8, $6c, $10
	border_medal_tile v0Tiles1 + $4ba, $6d, $10
	border_medal_tile v0Tiles1 + $4bc, $6e, $10
	border_medal_tile v0Tiles1 + $4f8, $6f, $10
	border_medal_tile v0Tiles1 + $4fa, $70, $10
	border_medal_tile v0Tiles1 + $4fc, $71, $10
	border_medal_tile v0Tiles1 + $538, $72, $10
	border_medal_tile v0Tiles1 + $53a, $73, $10
	border_medal_tile v0Tiles1 + $53c, $74, $10
; 0x7036a

; decompresses palette data depending on wd132
; then sends it as SGB packet
SetSGB2AndSGB3MapPalette: ; 7036a (1c:436a)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; return if not SGB
	ld a, [wd132]
	or a
	ret z ; not valid

	push hl
	push bc
	push de
	ld a, [wd132]
	add a
	ld c, a
	ld b, $0
	ld hl, .pal_data_pointers
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call DecompressSGBPalette

	; load palettes to wTempSGBPacket
	ld hl, wDecompressionBuffer
	ld de, wTempSGBPacket + 1 ; PAL Packet color #0 (PAL23's SGB2)
	ld bc, 8 ; pal size
	call CopyDataHLtoDE
	ld hl, wDecompressionBuffer + 34
	ld de, wTempSGBPacket + 9 ; PAL Packet color #4 (PAL23's SGB3)
	ld bc, 6
	call CopyDataHLtoDE

	xor a
	ld [wTempSGBPacket + 15], a
	ld hl, wTempSGBPacket
	ld a, PAL01 << 3 + 1
	ld [hl], a
	call Func_704c7
	call SendSGB
	pop de
	pop bc
	pop hl
	ret

.pal_data_pointers
	dw SGBData_MapPals1  ; unused
	dw SGBData_MapPals1  ; MAP_SGB_PALS_1
	dw SGBData_MapPals2  ; MAP_SGB_PALS_2
	dw SGBData_MapPals3  ; MAP_SGB_PALS_3
	dw SGBData_MapPals4  ; MAP_SGB_PALS_4
	dw SGBData_MapPals5  ; MAP_SGB_PALS_5
	dw SGBData_MapPals6  ; MAP_SGB_PALS_6
	dw SGBData_MapPals7  ; MAP_SGB_PALS_7
	dw SGBData_MapPals8  ; MAP_SGB_PALS_8
	dw SGBData_MapPals9  ; MAP_SGB_PALS_9
	dw SGBData_MapPals10 ; MAP_SGB_PALS_10
; 0x703cb

Func_703cb: ; 703cb (1c:43cb)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz
	push hl
	push bc
	push de
	call DecompressSGBPalette
	ld hl, wDecompressionBuffer
	ld de, wTempSGBPacket + $1
	ld bc, $8 ; palette 2, color 0-3
	call CopyDataHLtoDE
	ld hl, wDecompressionBuffer + $22
	ld de, wTempSGBPacket + $9
	ld bc, $6 ; palette 3, color 1-3
	call CopyDataHLtoDE
	xor a
	ld [wTempSGBPacket + $f], a
	ld hl, wTempSGBPacket
	ld a, PAL23 << 3 + 1
	ld [hl], a
	call Func_704c7
	call SendSGB
	pop de
	pop bc
	pop hl
	ret

DecompressSGBPalette: ; 70403 (1c:4403)
	push hl
	push bc
	push de
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	push bc
	ld e, l
	ld d, h
	ld b, HIGH(wDecompressionSecondaryBuffer)
	call InitDataDecompression
	pop bc
	ld de, wDecompressionBuffer
	call DecompressData
	pop de
	pop bc
	pop hl
	ret
; 0x7041d

; sends an SGB packet related with palettes
; unreferenced?
Func_7041d: ; 7041d (1c:441d)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz ; exit if not SGB

	push hl
	push bc
	push de
	push bc
	push hl
	push hl
	ld hl, SGBData_UnusedPals1
	call DecompressSGBPalette
	ld hl, wLoadedPalData
	ld de, wTempSGBPacket + $1
	ld bc, $8
	call CopyDataHLtoDE

	pop hl
	call DecompressSGBPalette
	ld hl, wLoadedPalData + 2
	ld de, wTempSGBPacket + $9
	ld bc, $6
	call CopyDataHLtoDE

	xor a
	ld [wTempSGBPacket + $f], a
	ld hl, wTempSGBPacket
	ld a, $09
	ld [hl], a
	call Func_704c7
	call SendSGB

	pop hl
	ld c, $0f
	ld a, l
	cp LOW(SGBData_UnusedPals1)
	jr nz, .asm_7046a
	ld a, h
	cp HIGH(SGBData_UnusedPals1)
	jr nz, .asm_7046a
	ld c, $0a

.asm_7046a
	ld a, c
	ld [wTempSGBPacket + $3], a
	pop bc
	ld hl, wTempSGBPacket
	push hl
	ld a, $21
	ld [hli], a
	ld a, $01
	ld [hli], a
	ld a, $01
	ld [hli], a
	inc hl
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, $05
	add b
	ld [hli], a
	ld a, $05
	add c
	ld [hli], a
	xor a
	ld [wTempSGBPacket + $e], a
	ld [wTempSGBPacket + $f], a
	pop hl
	call SendSGB
	pop de
	pop bc
	pop hl
	ret
; 0x70498

; send an ATTR_BLK SGB packet
; input:
; b = x1 (left)
; c = y1 (upper)
; d = block width
; e = block height
; l = %00xxyyzz, palette number for: outside block, block border, inside block
Func_70498: ; 70498 (1c:4498)
	ld a, [wConsole]
	cp CONSOLE_SGB
	ret nz
	push hl
	push bc
	push de
	ld a, l
	ld [wTempSGBPacket + 3], a ; Color Palette Designation
	ld hl, wTempSGBPacket
	push hl
	ld a, ATTR_BLK << 3 + 1
	ld [hli], a ; packet command and length
	ld a, 1
	ld [hli], a ; 1 data set
	ld a, ATTR_BLK_CTRL_INSIDE
	ld [hli], a ; control code
	inc hl
	ld a, b
	ld [hli], a ; x1
	ld a, c
	ld [hli], a ; y1
	ld a, d
	dec a
	add b
	ld [hli], a ; x2
	ld a, e
	dec a
	add c
	ld [hli], a ; y2
	pop hl
	call SendSGB
	pop de
	pop bc
	pop hl
	ret

; set color 0 to default white rgb(28, 28, 24)
; input:
; hl = pointer to start of SGB packet
Func_704c7: ; 704c7 (1c:44c7)
	push af
	push hl
	inc hl
	ld a, LOW(24 << 10 | 28 << 5 | 28)
	ld [hli], a
	ld a, HIGH(24 << 10 | 28 << 5 | 28)
	ld [hl], a
	pop hl
	pop af
	ret
; 0x704d3

SGBData_BorderDebug4: ; 704d3 (1c:44d3)
	dw $800 ; length
	INCBIN "data/sgb_data/border_debug_4.bin"

SGBData_BorderIntro4: ; 706dd (1c:46dd)
	dw $800 ; length
	INCBIN "data/sgb_data/border_intro_4.bin"

SGBData_BorderMedals5: ; 709dc (1c:49dc)
	dw $800 ; length
	INCBIN "data/sgb_data/border_medals_5.bin"

SGBBorderDebugGfxPointers: ; 70b96 (1c:4b96)
	dw SGBData_BorderDebug1
	dw SGBData_BorderDebug2

SGBData_BorderDebug1: ; 70b9a (1c:45b9a)
	dw $1000 ; length
	INCBIN "data/sgb_data/border_debug_1.bin"

SGBData_BorderDebug2: ; 71359 (1c:5359)
	dw $a0 ; length
	INCBIN "data/sgb_data/border_debug_2.bin"

SGBBorderIntroGfxPointers: ; 713a9 (1c:53a9)
	dw SGBData_BorderIntro1
	dw SGBData_BorderIntro2

SGBData_BorderIntro1: ; 713ad (1c:53ad)
	dw $1000 ; length
	INCBIN "data/sgb_data/border_intro_1.bin"

SGBData_BorderIntro2: ; 71ec0 (1c:5ec0)
	dw $4e0 ; length
	INCBIN "data/sgb_data/border_intro_2.bin"

SGBBorderMedalsGfxPointers: ; 72273 (1c:6273)
	dw SGBData_BorderMedals1
	dw SGBData_BorderMedals2

SGBData_BorderMedals1: ; 72277 (1c:5277)
	dw $1000 ; length
	INCBIN "data/sgb_data/border_medals_1.bin"

SGBData_BorderMedals2: ; 72fe4 (1c:5fe4)
	dw $100 ; length
	INCBIN "data/sgb_data/border_medals_2.bin"

SGBData_BorderDebug3: ; 730de (1c:70de)
	dw $60 ; length
	INCBIN "data/sgb_data/border_debug_3.bin"

SGBData_BorderIntro3: ; 73146 (1c:7146)
	dw $60 ; length
	INCBIN "data/sgb_data/border_intro_3.bin"

SGBData_BorderMedals3: ; 7319a (1c:719a)
	dw $60 ; length
	INCBIN "data/sgb_data/border_medals_3.bin"

SGBData_BorderMedals4: ; 731e5 (1c:71e5)
	dw $60 ; length
	INCBIN "data/sgb_data/border_medals_4.bin"

SGBData_MapPals1: ; 7322f (1c:722f)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_1.bin"

SGBData_MapPals2: ; 73253 (1c:7253)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_2.bin"

SGBData_MapPals3: ; 73277 (1c:7277)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_3.bin"

SGBData_MapPals4: ; 7329a (1c:729a)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_4.bin"

SGBData_MapPals5: ; 732bd (1c:72bd)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_5.bin"

SGBData_MapPals6: ; 732e0 (1c:72e0)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_6.bin"

SGBData_MapPals7: ; 73304 (1c:7304)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_7.bin"

SGBData_MapPals8: ; 73328 (1c:7328)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_8.bin"

SGBData_MapPals9: ; 7334b (1c:734b)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_9.bin"

SGBData_MapPals10: ; 7336f (1c:736f)
	dw $20 ; length
	INCBIN "data/sgb_data/map_pals_10.bin"

SGBData_CharizardIntro: ; 73393 (1c:7393)
	dw $20 ; length
	INCBIN "data/sgb_data/charizard_intro_pals.bin"

SGBData_ScytherIntro: ; 733b8 (1c:73b8)
	dw $20 ; length
	INCBIN "data/sgb_data/scyther_intro_pals.bin"

SGBData_AerodactylIntro: ; 733dd (1c:73dd)
	dw $20 ; length
	INCBIN "data/sgb_data/aerodactyl_intro_pals.bin"

SGBData_ColosseumBooster: ; 73402 (1c:7402)
	dw $20 ; length
	INCBIN "data/sgb_data/colosseum_booster_pals.bin"

SGBData_EvolutionBooster: ; 73427 (1c:7427)
	dw $20 ; length
	INCBIN "data/sgb_data/evolution_booster_pals.bin"

SGBData_MysteryBooster: ; 7344c (1c:744c)
	dw $20 ; length
	INCBIN "data/sgb_data/mystery_booster_pals.bin"

SGBData_LaboratoryBooster: ; 73471 (1c:7471)
	dw $20 ; length
	INCBIN "data/sgb_data/laboratory_booster_pals.bin"

SGBData_UnusedPals1: ; 73496 (1c:7496)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_1.bin"

SGBData_UnusedPals2: ; 734bb (1c:74bb)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_2.bin"

SGBData_UnusedPals_3: ; 734e0 (1c:74e0)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_3.bin"

SGBData_UnusedPals_4: ; 73505 (1c:7505)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_4.bin"

SGBData_UnusedPals_5: ; 7352a (1c:752a)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_5.bin"

SGBData_UnusedPals_6: ; 7354f (1c:754f)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_6.bin"

SGBData_UnusedPals_7: ; 73574 (1c:7574)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_7.bin"

SGBData_UnusedPals_8: ; 73599 (1c:7599)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_8.bin"

SGBData_UnusedPals_9: ; 735be (1c:75be)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_9.bin"

SGBData_UnusedPals10: ; 735e3 (1c:75e3)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_10.bin"

SGBData_UnusedPals11: ; 73608 (1c:7608)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_11.bin"

SGBData_UnusedPals12: ; 7362d (1c:762d)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_12.bin"

SGBData_UnusedPals13: ; 73652 (1c:7652)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_13.bin"

SGBData_UnusedPals14: ; 73677 (1c:7677)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_14.bin"

SGBData_UnusedPals15: ; 7369c (1c:769c)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_15.bin"

SGBData_UnusedPals16: ; 736c1 (1c:76c1)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_16.bin"

SGBData_UnusedPals17: ; 736e6 (1c:76e6)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_17.bin"

SGBData_UnusedPals18: ; 7370b (1c:770b)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_18.bin"

SGBData_UnusedPals19: ; 73730 (1c:7730)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_19.bin"

SGBData_UnusedPals20: ; 73755 (1c:7755)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_20.bin"

SGBData_UnusedPals21: ; 7377a (1c:777a)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_21.bin"

SGBData_UnusedPals22: ; 7379f (1c:779f)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_22.bin"

SGBData_UnusedPals23: ; 737c4 (1c:77c4)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_23.bin"

SGBData_UnusedPals24: ; 737e9 (1c:77e9)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_24.bin"

SGBData_UnusedPals25: ; 7380e (1c:780e)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_25.bin"

SGBData_UnusedPals26: ; 73833 (1c:7833)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_26.bin"

SGBData_UnusedPals27: ; 73858 (1c:7858)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_27.bin"

SGBData_UnusedPals28: ; 7387d (1c:787d)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_28.bin"

SGBData_UnusedPals29: ; 738a2 (1c:78a2)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_29.bin"

SGBData_UnusedPals30: ; 738c7 (1c:78c7)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_30.bin"

SGBData_UnusedPals31: ; 738ec (1c:78ec)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_31.bin"

SGBData_UnusedPals32: ; 73911 (1c:7911)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_32.bin"

SGBData_UnusedPals33: ; 73936 (1c:7936)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_33.bin"

SGBData_UnusedPals34: ; 7395b (1c:795b)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_34.bin"

SGBData_UnusedPals35: ; 73980 (1c:7980)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_35.bin"

SGBData_UnusedPals36: ; 739a5 (1c:79a5)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_36.bin"

SGBData_UnusedPals37: ; 739ca (1c:79ca)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_37.bin"

SGBData_UnusedPals38: ; 739ef (1c:79ef)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_38.bin"

SGBData_UnusedPals39: ; 73a14 (1c:7a14)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_39.bin"

SGBData_UnusedPals40: ; 73a39 (1c:7a39)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_40.bin"

SGBData_UnusedPals41: ; 73a5e (1c:7a5e)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_41.bin"

SGBData_UnusedPals42: ; 73a83 (1c:7a83)
	dw $20 ; length
	INCBIN "data/sgb_data/unused_pals_42.bin"

SGBData_GameBoyLink: ; 73aa8 (1c:7aa8)
	dw $40 ; length
	INCBIN "data/sgb_data/gameboy_link_pals.bin"

SGBData_CardPop: ; 73ad8 (1c:7ad8)
	dw $40 ; length
	INCBIN "data/sgb_data/card_pop_pals.bin"

SGBData_GameBoyPrinter: ; 73b05 (1c:7b05)
	dw $40 ; length
	INCBIN "data/sgb_data/gameboy_printer_pals.bin"

SGBData_TitleScreen: ; 73b33 (1c:7b33)
	dw $40 ; length
	INCBIN "data/sgb_data/title_screen_pals.bin"

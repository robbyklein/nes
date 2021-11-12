.include "constants.inc"

.segment "HEADER"
  .byte "NES"
  .byte $1a
  .byte $02
  .byte $01 
  .byte %00000001
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00, $00, $00, $00, $00

.segment "ZEROPAGE"
.segment "STARTUP"
Reset:
  SEI
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK

:
  BIT $2002
  BPL :-


  ; Load sprite palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$10
  STX PPUADDR
  
  LDX #$00
LoadPalettes2:
    LDA colors2, X
    STA PPUDATA
    INX
    CPX #$10
    BNE LoadPalettes2


  ; Load background palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  
  LDX #$00
LoadPalettes:
    LDA colors, X
    STA PPUDATA
    INX
    CPX #$10
    BNE LoadPalettes


  ;;;;;;;;;;;;;;;;;;;;;;;
  ; Load Sprites
  ;;;;;;;;;;;;;;;;;;;;;;;
  ldx #$00
load_spirtes:
  lda sprites, x
  sta $0200, x
  inx
  cpx #$04
  bne load_spirtes


  ;;;;;;;;;;;;;;;;;;;;;;;
  ; Load Background
  ;;;;;;;;;;;;;;;;;;;;;;;
  ldx #$20
  ldy #$00 ; position

  lda #<bg
  sta 3
  lda #>bg
  sta 4

; Background
page:
  tiles:
    LDA PPUSTATUS
    STX PPUADDR
    STY PPUADDR
    lda (3),y
    STa PPUDATA
    iny
    bne tiles

  inc 4
  inx
  cpx #$24
  bne page
  
vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10000000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK


Loop:
    JMP Loop

NMI:
	  LDA #$00
	  STA OAMADDR
	  LDA #$02
	  STA OAMDMA
	  LDA #$00
	  STA $2005
    lda #$00
	  STA $2005
    ;inc $01
	  RTI

colors:
  .incbin "palettes.pal"

colors2:
  .incbin "sprite-palettes.pal"

sprites:
  .byte $cf, $06, $00, $80

bg:
  .incbin "bg.nam"

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "tiles.chr"
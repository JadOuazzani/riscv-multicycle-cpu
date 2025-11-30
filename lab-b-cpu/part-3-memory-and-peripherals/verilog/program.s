.section ".text.init"
.globl _start

_start:
    # Test ADD avec nombres négatifs
    li t0, -10
    li t1, 3
    add t2, t0, t1         # -10 + 3 = -7
    li t3, -7
    bne t2, t3, fail
    
    # Test SUB avec résultat négatif
    li t0, 5
    li t1, 10
    sub t2, t0, t1         # 5 - 10 = -5
    li t3, -5
    bne t2, t3, fail
    
    # Test ADD overflow (pas d'exception en RISC-V)
    li t0, 0x7FFFFFFF      # MAX_INT
    li t1, 1
    add t2, t0, t1         # overflow -> 0x80000000
    li t3, 0x80000000
    bne t2, t3, fail
    
    # Test avec zéro
    li t0, 0
    li t1, 42
    add t2, t0, t1
    bne t2, t1, fail
    
    # Succès!
    li t0, 0x60000000
    li t1, 0x7F7F7F7F
    sw t1, 0(t0)
    j end
    
fail:
    li t0, 0x60000000
    li t1, 0x79797979
    sw t1, 0(t0)
    
end:
    ebreak
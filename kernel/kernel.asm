
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	06e000ef          	jal	ra,80000084 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 10000; // cycles; about 1ms in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	6709                	lui	a4,0x2
    8000003a:	71070713          	addi	a4,a4,1808 # 2710 <_entry-0x7fffd8f0>
    8000003e:	963a                	add	a2,a2,a4
    80000040:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000042:	0057979b          	slliw	a5,a5,0x5
    80000046:	078e                	slli	a5,a5,0x3
    80000048:	00009617          	auipc	a2,0x9
    8000004c:	fe860613          	addi	a2,a2,-24 # 80009030 <mscratch0>
    80000050:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000052:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000054:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000056:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005a:	00006797          	auipc	a5,0x6
    8000005e:	ea678793          	addi	a5,a5,-346 # 80005f00 <timervec>
    80000062:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000066:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006a:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000006e:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000072:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000076:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007a:	30479073          	csrw	mie,a5
}
    8000007e:	6422                	ld	s0,8(sp)
    80000080:	0141                	addi	sp,sp,16
    80000082:	8082                	ret

0000000080000084 <start>:
{
    80000084:	1141                	addi	sp,sp,-16
    80000086:	e406                	sd	ra,8(sp)
    80000088:	e022                	sd	s0,0(sp)
    8000008a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008c:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000090:	7779                	lui	a4,0xffffe
    80000092:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000096:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000098:	6705                	lui	a4,0x1
    8000009a:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000009e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a0:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a4:	00001797          	auipc	a5,0x1
    800000a8:	e0278793          	addi	a5,a5,-510 # 80000ea6 <main>
    800000ac:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b0:	4781                	li	a5,0
    800000b2:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b6:	67c1                	lui	a5,0x10
    800000b8:	17fd                	addi	a5,a5,-1
    800000ba:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000be:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c6:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000ca:	10479073          	csrw	sie,a5
  timerinit();
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	f4e080e7          	jalr	-178(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d6:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000da:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000dc:	823e                	mv	tp,a5
  asm volatile("mret");
    800000de:	30200073          	mret
}
    800000e2:	60a2                	ld	ra,8(sp)
    800000e4:	6402                	ld	s0,0(sp)
    800000e6:	0141                	addi	sp,sp,16
    800000e8:	8082                	ret

00000000800000ea <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ea:	715d                	addi	sp,sp,-80
    800000ec:	e486                	sd	ra,72(sp)
    800000ee:	e0a2                	sd	s0,64(sp)
    800000f0:	fc26                	sd	s1,56(sp)
    800000f2:	f84a                	sd	s2,48(sp)
    800000f4:	f44e                	sd	s3,40(sp)
    800000f6:	f052                	sd	s4,32(sp)
    800000f8:	ec56                	sd	s5,24(sp)
    800000fa:	0880                	addi	s0,sp,80
    800000fc:	8a2a                	mv	s4,a0
    800000fe:	84ae                	mv	s1,a1
    80000100:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000102:	00011517          	auipc	a0,0x11
    80000106:	72e50513          	addi	a0,a0,1838 # 80011830 <cons>
    8000010a:	00001097          	auipc	ra,0x1
    8000010e:	af2080e7          	jalr	-1294(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80000112:	05305b63          	blez	s3,80000168 <consolewrite+0x7e>
    80000116:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000118:	5afd                	li	s5,-1
    8000011a:	4685                	li	a3,1
    8000011c:	8626                	mv	a2,s1
    8000011e:	85d2                	mv	a1,s4
    80000120:	fbf40513          	addi	a0,s0,-65
    80000124:	00002097          	auipc	ra,0x2
    80000128:	6b2080e7          	jalr	1714(ra) # 800027d6 <either_copyin>
    8000012c:	01550c63          	beq	a0,s5,80000144 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000130:	fbf44503          	lbu	a0,-65(s0)
    80000134:	00000097          	auipc	ra,0x0
    80000138:	796080e7          	jalr	1942(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    8000013c:	2905                	addiw	s2,s2,1
    8000013e:	0485                	addi	s1,s1,1
    80000140:	fd299de3          	bne	s3,s2,8000011a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000144:	00011517          	auipc	a0,0x11
    80000148:	6ec50513          	addi	a0,a0,1772 # 80011830 <cons>
    8000014c:	00001097          	auipc	ra,0x1
    80000150:	b64080e7          	jalr	-1180(ra) # 80000cb0 <release>

  return i;
}
    80000154:	854a                	mv	a0,s2
    80000156:	60a6                	ld	ra,72(sp)
    80000158:	6406                	ld	s0,64(sp)
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	7942                	ld	s2,48(sp)
    8000015e:	79a2                	ld	s3,40(sp)
    80000160:	7a02                	ld	s4,32(sp)
    80000162:	6ae2                	ld	s5,24(sp)
    80000164:	6161                	addi	sp,sp,80
    80000166:	8082                	ret
  for(i = 0; i < n; i++){
    80000168:	4901                	li	s2,0
    8000016a:	bfe9                	j	80000144 <consolewrite+0x5a>

000000008000016c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016c:	7159                	addi	sp,sp,-112
    8000016e:	f486                	sd	ra,104(sp)
    80000170:	f0a2                	sd	s0,96(sp)
    80000172:	eca6                	sd	s1,88(sp)
    80000174:	e8ca                	sd	s2,80(sp)
    80000176:	e4ce                	sd	s3,72(sp)
    80000178:	e0d2                	sd	s4,64(sp)
    8000017a:	fc56                	sd	s5,56(sp)
    8000017c:	f85a                	sd	s6,48(sp)
    8000017e:	f45e                	sd	s7,40(sp)
    80000180:	f062                	sd	s8,32(sp)
    80000182:	ec66                	sd	s9,24(sp)
    80000184:	e86a                	sd	s10,16(sp)
    80000186:	1880                	addi	s0,sp,112
    80000188:	8aaa                	mv	s5,a0
    8000018a:	8a2e                	mv	s4,a1
    8000018c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000018e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000192:	00011517          	auipc	a0,0x11
    80000196:	69e50513          	addi	a0,a0,1694 # 80011830 <cons>
    8000019a:	00001097          	auipc	ra,0x1
    8000019e:	a62080e7          	jalr	-1438(ra) # 80000bfc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a2:	00011497          	auipc	s1,0x11
    800001a6:	68e48493          	addi	s1,s1,1678 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001aa:	00011917          	auipc	s2,0x11
    800001ae:	71e90913          	addi	s2,s2,1822 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b2:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b4:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b6:	4ca9                	li	s9,10
  while(n > 0){
    800001b8:	07305863          	blez	s3,80000228 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001bc:	0984a783          	lw	a5,152(s1)
    800001c0:	09c4a703          	lw	a4,156(s1)
    800001c4:	02f71463          	bne	a4,a5,800001ec <consoleread+0x80>
      if(myproc()->killed){
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	964080e7          	jalr	-1692(ra) # 80001b2c <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	318080e7          	jalr	792(ra) # 800024f0 <sleep>
    while(cons.r == cons.w){
    800001e0:	0984a783          	lw	a5,152(s1)
    800001e4:	09c4a703          	lw	a4,156(s1)
    800001e8:	fef700e3          	beq	a4,a5,800001c8 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ec:	0017871b          	addiw	a4,a5,1
    800001f0:	08e4ac23          	sw	a4,152(s1)
    800001f4:	07f7f713          	andi	a4,a5,127
    800001f8:	9726                	add	a4,a4,s1
    800001fa:	01874703          	lbu	a4,24(a4)
    800001fe:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000202:	077d0563          	beq	s10,s7,8000026c <consoleread+0x100>
    cbuf = c;
    80000206:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	f9f40613          	addi	a2,s0,-97
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	56c080e7          	jalr	1388(ra) # 80002780 <either_copyout>
    8000021c:	01850663          	beq	a0,s8,80000228 <consoleread+0xbc>
    dst++;
    80000220:	0a05                	addi	s4,s4,1
    --n;
    80000222:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000224:	f99d1ae3          	bne	s10,s9,800001b8 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	60850513          	addi	a0,a0,1544 # 80011830 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a80080e7          	jalr	-1408(ra) # 80000cb0 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xe4>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	5f250513          	addi	a0,a0,1522 # 80011830 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a6a080e7          	jalr	-1430(ra) # 80000cb0 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	70a6                	ld	ra,104(sp)
    80000252:	7406                	ld	s0,96(sp)
    80000254:	64e6                	ld	s1,88(sp)
    80000256:	6946                	ld	s2,80(sp)
    80000258:	69a6                	ld	s3,72(sp)
    8000025a:	6a06                	ld	s4,64(sp)
    8000025c:	7ae2                	ld	s5,56(sp)
    8000025e:	7b42                	ld	s6,48(sp)
    80000260:	7ba2                	ld	s7,40(sp)
    80000262:	7c02                	ld	s8,32(sp)
    80000264:	6ce2                	ld	s9,24(sp)
    80000266:	6d42                	ld	s10,16(sp)
    80000268:	6165                	addi	sp,sp,112
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0009871b          	sext.w	a4,s3
    80000270:	fb677ce3          	bgeu	a4,s6,80000228 <consoleread+0xbc>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	64f72a23          	sw	a5,1620(a4) # 800118c8 <cons+0x98>
    8000027c:	b775                	j	80000228 <consoleread+0xbc>

000000008000027e <consputc>:
{
    8000027e:	1141                	addi	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	55e080e7          	jalr	1374(ra) # 800007ec <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	addi	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	54c080e7          	jalr	1356(ra) # 800007ec <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	540080e7          	jalr	1344(ra) # 800007ec <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	536080e7          	jalr	1334(ra) # 800007ec <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	addi	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	addi	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	56250513          	addi	a0,a0,1378 # 80011830 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	926080e7          	jalr	-1754(ra) # 80000bfc <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	538080e7          	jalr	1336(ra) # 8000282c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	addi	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	9ac080e7          	jalr	-1620(ra) # 80000cb0 <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	addi	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	51070713          	addi	a4,a4,1296 # 80011830 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	4e678793          	addi	a5,a5,1254 # 80011830 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addiw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	andi	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	5507a783          	lw	a5,1360(a5) # 800118c8 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	4a470713          	addi	a4,a4,1188 # 80011830 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	49448493          	addi	s1,s1,1172 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addiw	a5,a5,-1
    800003ac:	07f7f713          	andi	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	45870713          	addi	a4,a4,1112 # 80011830 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	4ef72123          	sw	a5,1250(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	41c78793          	addi	a5,a5,1052 # 80011830 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	andi	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	48c7aa23          	sw	a2,1172(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	48850513          	addi	a0,a0,1160 # 800118c8 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	242080e7          	jalr	578(ra) # 8000268a <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	addi	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	addi	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	3ce50513          	addi	a0,a0,974 # 80011830 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	702080e7          	jalr	1794(ra) # 80000b6c <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32a080e7          	jalr	810(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00022797          	auipc	a5,0x22
    8000047e:	23678793          	addi	a5,a5,566 # 800226b0 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	cea70713          	addi	a4,a4,-790 # 8000016c <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c5e70713          	addi	a4,a4,-930 # 800000ea <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	addi	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	addi	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054663          	bltz	a0,80000538 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b8460613          	addi	a2,a2,-1148 # 80008040 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addiw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	slli	a5,a5,0x20
    800004ce:	9381                	srli	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	addi	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088b63          	beqz	a7,800004fe <printint+0x60>
    buf[i++] = '-';
    800004ec:	fe040793          	addi	a5,s0,-32
    800004f0:	973e                	add	a4,a4,a5
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x8e>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d60080e7          	jalr	-672(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7c>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf9d                	j	800004b4 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	3a07a223          	sw	zero,932(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	c8250513          	addi	a0,a0,-894 # 800081f0 <digits+0x1b0>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a8f72023          	sw	a5,-1408(a4) # 80009000 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	334dad83          	lw	s11,820(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	2de50513          	addi	a0,a0,734 # 800118d8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5fa080e7          	jalr	1530(ra) # 80000bfc <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c62080e7          	jalr	-926(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e32080e7          	jalr	-462(ra) # 8000049e <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0e080e7          	jalr	-498(ra) # 8000049e <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bd0080e7          	jalr	-1072(ra) # 8000027e <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc4080e7          	jalr	-1084(ra) # 8000027e <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bb0080e7          	jalr	-1104(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b8a080e7          	jalr	-1142(ra) # 8000027e <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b68080e7          	jalr	-1176(ra) # 8000027e <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5c080e7          	jalr	-1188(ra) # 8000027e <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b52080e7          	jalr	-1198(ra) # 8000027e <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00011517          	auipc	a0,0x11
    8000075c:	18050513          	addi	a0,a0,384 # 800118d8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	550080e7          	jalr	1360(ra) # 80000cb0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00011497          	auipc	s1,0x11
    80000778:	16448493          	addi	s1,s1,356 # 800118d8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3e6080e7          	jalr	998(ra) # 80000b6c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00011517          	auipc	a0,0x11
    800007d8:	12450513          	addi	a0,a0,292 # 800118f8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	390080e7          	jalr	912(ra) # 80000b6c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3b8080e7          	jalr	952(ra) # 80000bb0 <push_off>

  if(panicked){
    80000800:	00009797          	auipc	a5,0x9
    80000804:	8007a783          	lw	a5,-2048(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	andi	a0,s1,255
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	42a080e7          	jalr	1066(ra) # 80000c50 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	7cc7a783          	lw	a5,1996(a5) # 80009004 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c872703          	lw	a4,1992(a4) # 80009008 <uart_tx_w>
    80000848:	08f70063          	beq	a4,a5,800008c8 <uartstart+0x90>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000862:	00011a97          	auipc	s5,0x11
    80000866:	096a8a93          	addi	s5,s5,150 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	79a48493          	addi	s1,s1,1946 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008a17          	auipc	s4,0x8
    80000876:	796a0a13          	addi	s4,s4,1942 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	cb15                	beqz	a4,800008b6 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000884:	00fa8733          	add	a4,s5,a5
    80000888:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088c:	2785                	addiw	a5,a5,1
    8000088e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000892:	01b7571b          	srliw	a4,a4,0x1b
    80000896:	9fb9                	addw	a5,a5,a4
    80000898:	8bfd                	andi	a5,a5,31
    8000089a:	9f99                	subw	a5,a5,a4
    8000089c:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	dea080e7          	jalr	-534(ra) # 8000268a <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	000a2703          	lw	a4,0(s4)
    800008b2:	fcf714e3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	01c50513          	addi	a0,a0,28 # 800118f8 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	318080e7          	jalr	792(ra) # 80000bfc <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008f8:	00008697          	auipc	a3,0x8
    800008fc:	7106a683          	lw	a3,1808(a3) # 80009008 <uart_tx_w>
    80000900:	0016879b          	addiw	a5,a3,1
    80000904:	41f7d71b          	sraiw	a4,a5,0x1f
    80000908:	01b7571b          	srliw	a4,a4,0x1b
    8000090c:	9fb9                	addw	a5,a5,a4
    8000090e:	8bfd                	andi	a5,a5,31
    80000910:	9f99                	subw	a5,a5,a4
    80000912:	00008717          	auipc	a4,0x8
    80000916:	6f272703          	lw	a4,1778(a4) # 80009004 <uart_tx_r>
    8000091a:	04f71363          	bne	a4,a5,80000960 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091e:	00011a17          	auipc	s4,0x11
    80000922:	fdaa0a13          	addi	s4,s4,-38 # 800118f8 <uart_tx_lock>
    80000926:	00008917          	auipc	s2,0x8
    8000092a:	6de90913          	addi	s2,s2,1758 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000092e:	00008997          	auipc	s3,0x8
    80000932:	6da98993          	addi	s3,s3,1754 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000936:	85d2                	mv	a1,s4
    80000938:	854a                	mv	a0,s2
    8000093a:	00002097          	auipc	ra,0x2
    8000093e:	bb6080e7          	jalr	-1098(ra) # 800024f0 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000942:	0009a683          	lw	a3,0(s3)
    80000946:	0016879b          	addiw	a5,a3,1
    8000094a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000094e:	01b7571b          	srliw	a4,a4,0x1b
    80000952:	9fb9                	addw	a5,a5,a4
    80000954:	8bfd                	andi	a5,a5,31
    80000956:	9f99                	subw	a5,a5,a4
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	fcf70de3          	beq	a4,a5,80000936 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000960:	00011917          	auipc	s2,0x11
    80000964:	f9890913          	addi	s2,s2,-104 # 800118f8 <uart_tx_lock>
    80000968:	96ca                	add	a3,a3,s2
    8000096a:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000096e:	00008717          	auipc	a4,0x8
    80000972:	68f72d23          	sw	a5,1690(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000976:	00000097          	auipc	ra,0x0
    8000097a:	ec2080e7          	jalr	-318(ra) # 80000838 <uartstart>
      release(&uart_tx_lock);
    8000097e:	854a                	mv	a0,s2
    80000980:	00000097          	auipc	ra,0x0
    80000984:	330080e7          	jalr	816(ra) # 80000cb0 <release>
}
    80000988:	70a2                	ld	ra,40(sp)
    8000098a:	7402                	ld	s0,32(sp)
    8000098c:	64e2                	ld	s1,24(sp)
    8000098e:	6942                	ld	s2,16(sp)
    80000990:	69a2                	ld	s3,8(sp)
    80000992:	6a02                	ld	s4,0(sp)
    80000994:	6145                	addi	sp,sp,48
    80000996:	8082                	ret

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    800009cc:	a029                	j	800009d6 <uartintr+0x16>
      break;
    consoleintr(c);
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	8f2080e7          	jalr	-1806(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	fc2080e7          	jalr	-62(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009de:	fe9518e3          	bne	a0,s1,800009ce <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00011497          	auipc	s1,0x11
    800009e6:	f1648493          	addi	s1,s1,-234 # 800118f8 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	210080e7          	jalr	528(ra) # 80000bfc <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e44080e7          	jalr	-444(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	2b2080e7          	jalr	690(ra) # 80000cb0 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a10:	1101                	addi	sp,sp,-32
    80000a12:	ec06                	sd	ra,24(sp)
    80000a14:	e822                	sd	s0,16(sp)
    80000a16:	e426                	sd	s1,8(sp)
    80000a18:	e04a                	sd	s2,0(sp)
    80000a1a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1c:	03451793          	slli	a5,a0,0x34
    80000a20:	ebb9                	bnez	a5,80000a76 <kfree+0x66>
    80000a22:	84aa                	mv	s1,a0
    80000a24:	00026797          	auipc	a5,0x26
    80000a28:	5dc78793          	addi	a5,a5,1500 # 80027000 <end>
    80000a2c:	04f56563          	bltu	a0,a5,80000a76 <kfree+0x66>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	04f57163          	bgeu	a0,a5,80000a76 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2bc080e7          	jalr	700(ra) # 80000cf8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a44:	00011917          	auipc	s2,0x11
    80000a48:	eec90913          	addi	s2,s2,-276 # 80011930 <kmem>
    80000a4c:	854a                	mv	a0,s2
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	1ae080e7          	jalr	430(ra) # 80000bfc <acquire>
  r->next = kmem.freelist;
    80000a56:	01893783          	ld	a5,24(s2)
    80000a5a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	24e080e7          	jalr	590(ra) # 80000cb0 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5ea50513          	addi	a0,a0,1514 # 80008060 <digits+0x20>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	ac2080e7          	jalr	-1342(ra) # 80000540 <panic>

0000000080000a86 <freerange>:
{
    80000a86:	7179                	addi	sp,sp,-48
    80000a88:	f406                	sd	ra,40(sp)
    80000a8a:	f022                	sd	s0,32(sp)
    80000a8c:	ec26                	sd	s1,24(sp)
    80000a8e:	e84a                	sd	s2,16(sp)
    80000a90:	e44e                	sd	s3,8(sp)
    80000a92:	e052                	sd	s4,0(sp)
    80000a94:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a96:	6785                	lui	a5,0x1
    80000a98:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9c:	94aa                	add	s1,s1,a0
    80000a9e:	757d                	lui	a0,0xfffff
    80000aa0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94be                	add	s1,s1,a5
    80000aa4:	0095ee63          	bltu	a1,s1,80000ac0 <freerange+0x3a>
    80000aa8:	892e                	mv	s2,a1
    kfree(p);
    80000aaa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	6985                	lui	s3,0x1
    kfree(p);
    80000aae:	01448533          	add	a0,s1,s4
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	f5e080e7          	jalr	-162(ra) # 80000a10 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aba:	94ce                	add	s1,s1,s3
    80000abc:	fe9979e3          	bgeu	s2,s1,80000aae <freerange+0x28>
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6942                	ld	s2,16(sp)
    80000ac8:	69a2                	ld	s3,8(sp)
    80000aca:	6a02                	ld	s4,0(sp)
    80000acc:	6145                	addi	sp,sp,48
    80000ace:	8082                	ret

0000000080000ad0 <kinit>:
{
    80000ad0:	1141                	addi	sp,sp,-16
    80000ad2:	e406                	sd	ra,8(sp)
    80000ad4:	e022                	sd	s0,0(sp)
    80000ad6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad8:	00007597          	auipc	a1,0x7
    80000adc:	59058593          	addi	a1,a1,1424 # 80008068 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	addi	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	slli	a1,a1,0x1b
    80000af4:	00026517          	auipc	a0,0x26
    80000af8:	50c50513          	addi	a0,a0,1292 # 80027000 <end>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	f8a080e7          	jalr	-118(ra) # 80000a86 <freerange>
}
    80000b04:	60a2                	ld	ra,8(sp)
    80000b06:	6402                	ld	s0,0(sp)
    80000b08:	0141                	addi	sp,sp,16
    80000b0a:	8082                	ret

0000000080000b0c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0c:	1101                	addi	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b16:	00011497          	auipc	s1,0x11
    80000b1a:	e1a48493          	addi	s1,s1,-486 # 80011930 <kmem>
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	0dc080e7          	jalr	220(ra) # 80000bfc <acquire>
  r = kmem.freelist;
    80000b28:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2a:	c885                	beqz	s1,80000b5a <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2c:	609c                	ld	a5,0(s1)
    80000b2e:	00011517          	auipc	a0,0x11
    80000b32:	e0250513          	addi	a0,a0,-510 # 80011930 <kmem>
    80000b36:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4595                	li	a1,5
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	1b2080e7          	jalr	434(ra) # 80000cf8 <memset>
  return (void*)r;
}
    80000b4e:	8526                	mv	a0,s1
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret
  release(&kmem.lock);
    80000b5a:	00011517          	auipc	a0,0x11
    80000b5e:	dd650513          	addi	a0,a0,-554 # 80011930 <kmem>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	14e080e7          	jalr	334(ra) # 80000cb0 <release>
  if(r)
    80000b6a:	b7d5                	j	80000b4e <kalloc+0x42>

0000000080000b6c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b72:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b74:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b78:	00053823          	sd	zero,16(a0)
}
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	411c                	lw	a5,0(a0)
    80000b84:	e399                	bnez	a5,80000b8a <holding+0x8>
    80000b86:	4501                	li	a0,0
  return r;
}
    80000b88:	8082                	ret
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b94:	6904                	ld	s1,16(a0)
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	f7a080e7          	jalr	-134(ra) # 80001b10 <mycpu>
    80000b9e:	40a48533          	sub	a0,s1,a0
    80000ba2:	00153513          	seqz	a0,a0
}
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	addi	sp,sp,32
    80000bae:	8082                	ret

0000000080000bb0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bba:	100024f3          	csrr	s1,sstatus
    80000bbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc8:	00001097          	auipc	ra,0x1
    80000bcc:	f48080e7          	jalr	-184(ra) # 80001b10 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f3c080e7          	jalr	-196(ra) # 80001b10 <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	2785                	addiw	a5,a5,1
    80000be0:	dd3c                	sw	a5,120(a0)
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret
    mycpu()->intena = old;
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	f24080e7          	jalr	-220(ra) # 80001b10 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf4:	8085                	srli	s1,s1,0x1
    80000bf6:	8885                	andi	s1,s1,1
    80000bf8:	dd64                	sw	s1,124(a0)
    80000bfa:	bfe9                	j	80000bd4 <push_off+0x24>

0000000080000bfc <acquire>:
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
    80000c06:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	fa8080e7          	jalr	-88(ra) # 80000bb0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f70080e7          	jalr	-144(ra) # 80000b82 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	4705                	li	a4,1
  if(holding(lk))
    80000c1c:	e115                	bnez	a0,80000c40 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	87ba                	mv	a5,a4
    80000c20:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c24:	2781                	sext.w	a5,a5
    80000c26:	ffe5                	bnez	a5,80000c1e <acquire+0x22>
  __sync_synchronize();
    80000c28:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	ee4080e7          	jalr	-284(ra) # 80001b10 <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	addi	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	43050513          	addi	a0,a0,1072 # 80008070 <digits+0x30>
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	8f8080e7          	jalr	-1800(ra) # 80000540 <panic>

0000000080000c50 <pop_off>:

void
pop_off(void)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e406                	sd	ra,8(sp)
    80000c54:	e022                	sd	s0,0(sp)
    80000c56:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	eb8080e7          	jalr	-328(ra) # 80001b10 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05b63          	blez	a5,80000ca0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addiw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x38>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	addi	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3e850513          	addi	a0,a0,1000 # 80008078 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8a8080e7          	jalr	-1880(ra) # 80000540 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3f050513          	addi	a0,a0,1008 # 80008090 <digits+0x50>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>

0000000080000cb0 <release>:
{
    80000cb0:	1101                	addi	sp,sp,-32
    80000cb2:	ec06                	sd	ra,24(sp)
    80000cb4:	e822                	sd	s0,16(sp)
    80000cb6:	e426                	sd	s1,8(sp)
    80000cb8:	1000                	addi	s0,sp,32
    80000cba:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	ec6080e7          	jalr	-314(ra) # 80000b82 <holding>
    80000cc4:	c115                	beqz	a0,80000ce8 <release+0x38>
  lk->cpu = 0;
    80000cc6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cce:	0f50000f          	fence	iorw,ow
    80000cd2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	f7a080e7          	jalr	-134(ra) # 80000c50 <pop_off>
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	addi	sp,sp,32
    80000ce6:	8082                	ret
    panic("release");
    80000ce8:	00007517          	auipc	a0,0x7
    80000cec:	3b050513          	addi	a0,a0,944 # 80008098 <digits+0x58>
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>

0000000080000cf8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfe:	ca19                	beqz	a2,80000d14 <memset+0x1c>
    80000d00:	87aa                	mv	a5,a0
    80000d02:	1602                	slli	a2,a2,0x20
    80000d04:	9201                	srli	a2,a2,0x20
    80000d06:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0e:	0785                	addi	a5,a5,1
    80000d10:	fee79de3          	bne	a5,a4,80000d0a <memset+0x12>
  }
  return dst;
}
    80000d14:	6422                	ld	s0,8(sp)
    80000d16:	0141                	addi	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d20:	ca05                	beqz	a2,80000d50 <memcmp+0x36>
    80000d22:	fff6069b          	addiw	a3,a2,-1
    80000d26:	1682                	slli	a3,a3,0x20
    80000d28:	9281                	srli	a3,a3,0x20
    80000d2a:	0685                	addi	a3,a3,1
    80000d2c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2e:	00054783          	lbu	a5,0(a0)
    80000d32:	0005c703          	lbu	a4,0(a1)
    80000d36:	00e79863          	bne	a5,a4,80000d46 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3a:	0505                	addi	a0,a0,1
    80000d3c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3e:	fed518e3          	bne	a0,a3,80000d2e <memcmp+0x14>
  }

  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	a019                	j	80000d4a <memcmp+0x30>
      return *s1 - *s2;
    80000d46:	40e7853b          	subw	a0,a5,a4
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	addi	sp,sp,16
    80000d4e:	8082                	ret
  return 0;
    80000d50:	4501                	li	a0,0
    80000d52:	bfe5                	j	80000d4a <memcmp+0x30>

0000000080000d54 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d54:	1141                	addi	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	02a5e563          	bltu	a1,a0,80000d84 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	ce11                	beqz	a2,80000d7e <memmove+0x2a>
    80000d64:	1682                	slli	a3,a3,0x20
    80000d66:	9281                	srli	a3,a3,0x20
    80000d68:	0685                	addi	a3,a3,1
    80000d6a:	96ae                	add	a3,a3,a1
    80000d6c:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fff5c703          	lbu	a4,-1(a1)
    80000d76:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7a:	fed59ae3          	bne	a1,a3,80000d6e <memmove+0x1a>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
  if(s < d && s + n > d){
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	fcf578e3          	bgeu	a0,a5,80000d5e <memmove+0xa>
    d += n;
    80000d92:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d94:	fff6069b          	addiw	a3,a2,-1
    80000d98:	d27d                	beqz	a2,80000d7e <memmove+0x2a>
    80000d9a:	02069613          	slli	a2,a3,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	fff64613          	not	a2,a2
    80000da4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da6:	17fd                	addi	a5,a5,-1
    80000da8:	177d                	addi	a4,a4,-1
    80000daa:	0007c683          	lbu	a3,0(a5)
    80000dae:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db2:	fef61ae3          	bne	a2,a5,80000da6 <memmove+0x52>
    80000db6:	b7e1                	j	80000d7e <memmove+0x2a>

0000000080000db8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e406                	sd	ra,8(sp)
    80000dbc:	e022                	sd	s0,0(sp)
    80000dbe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f94080e7          	jalr	-108(ra) # 80000d54 <memmove>
}
    80000dc8:	60a2                	ld	ra,8(sp)
    80000dca:	6402                	ld	s0,0(sp)
    80000dcc:	0141                	addi	sp,sp,16
    80000dce:	8082                	ret

0000000080000dd0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd6:	ce11                	beqz	a2,80000df2 <strncmp+0x22>
    80000dd8:	00054783          	lbu	a5,0(a0)
    80000ddc:	cf89                	beqz	a5,80000df6 <strncmp+0x26>
    80000dde:	0005c703          	lbu	a4,0(a1)
    80000de2:	00f71a63          	bne	a4,a5,80000df6 <strncmp+0x26>
    n--, p++, q++;
    80000de6:	367d                	addiw	a2,a2,-1
    80000de8:	0505                	addi	a0,a0,1
    80000dea:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dec:	f675                	bnez	a2,80000dd8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	a809                	j	80000e02 <strncmp+0x32>
    80000df2:	4501                	li	a0,0
    80000df4:	a039                	j	80000e02 <strncmp+0x32>
  if(n == 0)
    80000df6:	ca09                	beqz	a2,80000e08 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df8:	00054503          	lbu	a0,0(a0)
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	9d1d                	subw	a0,a0,a5
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	bfe5                	j	80000e02 <strncmp+0x32>

0000000080000e0c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e12:	872a                	mv	a4,a0
    80000e14:	8832                	mv	a6,a2
    80000e16:	367d                	addiw	a2,a2,-1
    80000e18:	01005963          	blez	a6,80000e2a <strncpy+0x1e>
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	0005c783          	lbu	a5,0(a1)
    80000e22:	fef70fa3          	sb	a5,-1(a4)
    80000e26:	0585                	addi	a1,a1,1
    80000e28:	f7f5                	bnez	a5,80000e14 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2a:	86ba                	mv	a3,a4
    80000e2c:	00c05c63          	blez	a2,80000e44 <strncpy+0x38>
    *s++ = 0;
    80000e30:	0685                	addi	a3,a3,1
    80000e32:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e36:	fff6c793          	not	a5,a3
    80000e3a:	9fb9                	addw	a5,a5,a4
    80000e3c:	010787bb          	addw	a5,a5,a6
    80000e40:	fef048e3          	bgtz	a5,80000e30 <strncpy+0x24>
  return os;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret

0000000080000e4a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e422                	sd	s0,8(sp)
    80000e4e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e50:	02c05363          	blez	a2,80000e76 <safestrcpy+0x2c>
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	96ae                	add	a3,a3,a1
    80000e5e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e60:	00d58963          	beq	a1,a3,80000e72 <safestrcpy+0x28>
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff5c703          	lbu	a4,-1(a1)
    80000e6c:	fee78fa3          	sb	a4,-1(a5)
    80000e70:	fb65                	bnez	a4,80000e60 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e72:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <strlen>:

int
strlen(const char *s)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e82:	00054783          	lbu	a5,0(a0)
    80000e86:	cf91                	beqz	a5,80000ea2 <strlen+0x26>
    80000e88:	0505                	addi	a0,a0,1
    80000e8a:	87aa                	mv	a5,a0
    80000e8c:	4685                	li	a3,1
    80000e8e:	9e89                	subw	a3,a3,a0
    80000e90:	00f6853b          	addw	a0,a3,a5
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff7c703          	lbu	a4,-1(a5)
    80000e9a:	fb7d                	bnez	a4,80000e90 <strlen+0x14>
    ;
  return n;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strlen+0x20>

0000000080000ea6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e406                	sd	ra,8(sp)
    80000eaa:	e022                	sd	s0,0(sp)
    80000eac:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eae:	00001097          	auipc	ra,0x1
    80000eb2:	c52080e7          	jalr	-942(ra) # 80001b00 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb6:	00008717          	auipc	a4,0x8
    80000eba:	15670713          	addi	a4,a4,342 # 8000900c <started>
  if(cpuid() == 0){
    80000ebe:	c139                	beqz	a0,80000f04 <main+0x5e>
    while(started == 0)
    80000ec0:	431c                	lw	a5,0(a4)
    80000ec2:	2781                	sext.w	a5,a5
    80000ec4:	dff5                	beqz	a5,80000ec0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	c36080e7          	jalr	-970(ra) # 80001b00 <cpuid>
    80000ed2:	85aa                	mv	a1,a0
    80000ed4:	00007517          	auipc	a0,0x7
    80000ed8:	20450513          	addi	a0,a0,516 # 800080d8 <digits+0x98>
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	6ae080e7          	jalr	1710(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	0c8080e7          	jalr	200(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eec:	00002097          	auipc	ra,0x2
    80000ef0:	a82080e7          	jalr	-1406(ra) # 8000296e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	04c080e7          	jalr	76(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1ec080e7          	jalr	492(ra) # 800020e8 <scheduler>
    consoleinit();
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	54e080e7          	jalr	1358(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	85e080e7          	jalr	-1954(ra) # 8000076a <printfinit>
    printf("\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	2dc50513          	addi	a0,a0,732 # 800081f0 <digits+0x1b0>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66e080e7          	jalr	1646(ra) # 8000058a <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	17c50513          	addi	a0,a0,380 # 800080a0 <digits+0x60>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65e080e7          	jalr	1630(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b9c080e7          	jalr	-1124(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	2a0080e7          	jalr	672(ra) # 800011dc <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	ae4080e7          	jalr	-1308(ra) # 80001a30 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9f2080e7          	jalr	-1550(ra) # 80002946 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	a12080e7          	jalr	-1518(ra) # 8000296e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fc6080e7          	jalr	-58(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fd4080e7          	jalr	-44(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	17e080e7          	jalr	382(ra) # 800030f2 <binit>
    iinit();         // inode cache
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	810080e7          	jalr	-2032(ra) # 8000378c <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7ae080e7          	jalr	1966(ra) # 80004732 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0bc080e7          	jalr	188(ra) # 80006048 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	ed2080e7          	jalr	-302(ra) # 80001e66 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72523          	sw	a5,106(a4) # 8000900c <started>
    80000faa:	bf89                	j	80000efc <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	05e7b783          	ld	a5,94(a5) # 80009010 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0fa50513          	addi	a0,a0,250 # 800080f0 <digits+0xb0>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	b02080e7          	jalr	-1278(ra) # 80000b0c <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cde080e7          	jalr	-802(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010b8:	1101                	addi	sp,sp,-32
    800010ba:	ec06                	sd	ra,24(sp)
    800010bc:	e822                	sd	s0,16(sp)
    800010be:	e426                	sd	s1,8(sp)
    800010c0:	1000                	addi	s0,sp,32
    800010c2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c4:	1552                	slli	a0,a0,0x34
    800010c6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00008517          	auipc	a0,0x8
    800010d0:	f4453503          	ld	a0,-188(a0) # 80009010 <kernel_pagetable>
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	efc080e7          	jalr	-260(ra) # 80000fd0 <walk>
  if(pte == 0)
    800010dc:	cd09                	beqz	a0,800010f6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010de:	6108                	ld	a0,0(a0)
    800010e0:	00157793          	andi	a5,a0,1
    800010e4:	c38d                	beqz	a5,80001106 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e6:	8129                	srli	a0,a0,0xa
    800010e8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ea:	9526                	add	a0,a0,s1
    800010ec:	60e2                	ld	ra,24(sp)
    800010ee:	6442                	ld	s0,16(sp)
    800010f0:	64a2                	ld	s1,8(sp)
    800010f2:	6105                	addi	sp,sp,32
    800010f4:	8082                	ret
    panic("kvmpa");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	00250513          	addi	a0,a0,2 # 800080f8 <digits+0xb8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	442080e7          	jalr	1090(ra) # 80000540 <panic>
    panic("kvmpa");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	ff250513          	addi	a0,a0,-14 # 800080f8 <digits+0xb8>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	432080e7          	jalr	1074(ra) # 80000540 <panic>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
    8000112c:	8aaa                	mv	s5,a0
    8000112e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001130:	777d                	lui	a4,0xfffff
    80001132:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001136:	167d                	addi	a2,a2,-1
    80001138:	00b609b3          	add	s3,a2,a1
    8000113c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001140:	893e                	mv	s2,a5
    80001142:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001146:	6b85                	lui	s7,0x1
    80001148:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114c:	4605                	li	a2,1
    8000114e:	85ca                	mv	a1,s2
    80001150:	8556                	mv	a0,s5
    80001152:	00000097          	auipc	ra,0x0
    80001156:	e7e080e7          	jalr	-386(ra) # 80000fd0 <walk>
    8000115a:	c51d                	beqz	a0,80001188 <mappages+0x72>
    if(*pte & PTE_V)
    8000115c:	611c                	ld	a5,0(a0)
    8000115e:	8b85                	andi	a5,a5,1
    80001160:	ef81                	bnez	a5,80001178 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001162:	80b1                	srli	s1,s1,0xc
    80001164:	04aa                	slli	s1,s1,0xa
    80001166:	0164e4b3          	or	s1,s1,s6
    8000116a:	0014e493          	ori	s1,s1,1
    8000116e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001170:	03390863          	beq	s2,s3,800011a0 <mappages+0x8a>
    a += PGSIZE;
    80001174:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001176:	bfc9                	j	80001148 <mappages+0x32>
      panic("remap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8850513          	addi	a0,a0,-120 # 80008100 <digits+0xc0>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>
      return -1;
    80001188:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118a:	60a6                	ld	ra,72(sp)
    8000118c:	6406                	ld	s0,64(sp)
    8000118e:	74e2                	ld	s1,56(sp)
    80001190:	7942                	ld	s2,48(sp)
    80001192:	79a2                	ld	s3,40(sp)
    80001194:	7a02                	ld	s4,32(sp)
    80001196:	6ae2                	ld	s5,24(sp)
    80001198:	6b42                	ld	s6,16(sp)
    8000119a:	6ba2                	ld	s7,8(sp)
    8000119c:	6161                	addi	sp,sp,80
    8000119e:	8082                	ret
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7e5                	j	8000118a <mappages+0x74>

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011ae:	86ae                	mv	a3,a1
    800011b0:	85aa                	mv	a1,a0
    800011b2:	00008517          	auipc	a0,0x8
    800011b6:	e5e53503          	ld	a0,-418(a0) # 80009010 <kernel_pagetable>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f5c080e7          	jalr	-164(ra) # 80001116 <mappages>
    800011c2:	e509                	bnez	a0,800011cc <kvmmap+0x28>
}
    800011c4:	60a2                	ld	ra,8(sp)
    800011c6:	6402                	ld	s0,0(sp)
    800011c8:	0141                	addi	sp,sp,16
    800011ca:	8082                	ret
    panic("kvmmap");
    800011cc:	00007517          	auipc	a0,0x7
    800011d0:	f3c50513          	addi	a0,a0,-196 # 80008108 <digits+0xc8>
    800011d4:	fffff097          	auipc	ra,0xfffff
    800011d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>

00000000800011dc <kvminit>:
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	926080e7          	jalr	-1754(ra) # 80000b0c <kalloc>
    800011ee:	00008797          	auipc	a5,0x8
    800011f2:	e2a7b123          	sd	a0,-478(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f6:	6605                	lui	a2,0x1
    800011f8:	4581                	li	a1,0
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	afe080e7          	jalr	-1282(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001202:	4699                	li	a3,6
    80001204:	6605                	lui	a2,0x1
    80001206:	100005b7          	lui	a1,0x10000
    8000120a:	10000537          	lui	a0,0x10000
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f96080e7          	jalr	-106(ra) # 800011a4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001216:	4699                	li	a3,6
    80001218:	6605                	lui	a2,0x1
    8000121a:	100015b7          	lui	a1,0x10001
    8000121e:	10001537          	lui	a0,0x10001
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f82080e7          	jalr	-126(ra) # 800011a4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6641                	lui	a2,0x10
    8000122e:	020005b7          	lui	a1,0x2000
    80001232:	02000537          	lui	a0,0x2000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f6e080e7          	jalr	-146(ra) # 800011a4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	00400637          	lui	a2,0x400
    80001244:	0c0005b7          	lui	a1,0xc000
    80001248:	0c000537          	lui	a0,0xc000
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f58080e7          	jalr	-168(ra) # 800011a4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001254:	00007497          	auipc	s1,0x7
    80001258:	dac48493          	addi	s1,s1,-596 # 80008000 <etext>
    8000125c:	46a9                	li	a3,10
    8000125e:	80007617          	auipc	a2,0x80007
    80001262:	da260613          	addi	a2,a2,-606 # 8000 <_entry-0x7fff8000>
    80001266:	4585                	li	a1,1
    80001268:	05fe                	slli	a1,a1,0x1f
    8000126a:	852e                	mv	a0,a1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	4645                	li	a2,17
    80001278:	066e                	slli	a2,a2,0x1b
    8000127a:	8e05                	sub	a2,a2,s1
    8000127c:	85a6                	mv	a1,s1
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f24080e7          	jalr	-220(ra) # 800011a4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001288:	46a9                	li	a3,10
    8000128a:	6605                	lui	a2,0x1
    8000128c:	00006597          	auipc	a1,0x6
    80001290:	d7458593          	addi	a1,a1,-652 # 80007000 <_trampoline>
    80001294:	04000537          	lui	a0,0x4000
    80001298:	157d                	addi	a0,a0,-1
    8000129a:	0532                	slli	a0,a0,0xc
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f08080e7          	jalr	-248(ra) # 800011a4 <kvmmap>
}
    800012a4:	60e2                	ld	ra,24(sp)
    800012a6:	6442                	ld	s0,16(sp)
    800012a8:	64a2                	ld	s1,8(sp)
    800012aa:	6105                	addi	sp,sp,32
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e1c50513          	addi	a0,a0,-484 # 80008110 <digits+0xd0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e2450513          	addi	a0,a0,-476 # 80008128 <digits+0xe8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	234080e7          	jalr	564(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e2450513          	addi	a0,a0,-476 # 80008138 <digits+0xf8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	224080e7          	jalr	548(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e2c50513          	addi	a0,a0,-468 # 80008150 <digits+0x110>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	c8c080e7          	jalr	-884(ra) # 80000fd0 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6a8080e7          	jalr	1704(ra) # 80000a10 <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	790080e7          	jalr	1936(ra) # 80000b0c <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	96c080e7          	jalr	-1684(ra) # 80000cf8 <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvminit+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	750080e7          	jalr	1872(ra) # 80000b0c <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	92e080e7          	jalr	-1746(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d3a080e7          	jalr	-710(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	96a080e7          	jalr	-1686(ra) # 80000d54 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("inituvm: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d6650513          	addi	a0,a0,-666 # 80008168 <digits+0x128>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	767d                	lui	a2,0xfffff
    8000142e:	8f71                	and	a4,a4,a2
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff1                	and	a5,a5,a2
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66163          	bltu	a2,a1,800014fc <uvmalloc+0xa2>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	0080                	addi	s0,sp,64
    80001470:	8aaa                	mv	s5,a0
    80001472:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001474:	6985                	lui	s3,0x1
    80001476:	19fd                	addi	s3,s3,-1
    80001478:	95ce                	add	a1,a1,s3
    8000147a:	79fd                	lui	s3,0xfffff
    8000147c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001480:	08c9f063          	bgeu	s3,a2,80001500 <uvmalloc+0xa6>
    80001484:	894e                	mv	s2,s3
    mem = kalloc();
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	686080e7          	jalr	1670(ra) # 80000b0c <kalloc>
    8000148e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001490:	c51d                	beqz	a0,800014be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001492:	6605                	lui	a2,0x1
    80001494:	4581                	li	a1,0
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	862080e7          	jalr	-1950(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000149e:	4779                	li	a4,30
    800014a0:	86a6                	mv	a3,s1
    800014a2:	6605                	lui	a2,0x1
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	c6e080e7          	jalr	-914(ra) # 80001116 <mappages>
    800014b0:	e905                	bnez	a0,800014e0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b2:	6785                	lui	a5,0x1
    800014b4:	993e                	add	s2,s2,a5
    800014b6:	fd4968e3          	bltu	s2,s4,80001486 <uvmalloc+0x2c>
  return newsz;
    800014ba:	8552                	mv	a0,s4
    800014bc:	a809                	j	800014ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014be:	864e                	mv	a2,s3
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	f4e080e7          	jalr	-178(ra) # 80001412 <uvmdealloc>
      return 0;
    800014cc:	4501                	li	a0,0
}
    800014ce:	70e2                	ld	ra,56(sp)
    800014d0:	7442                	ld	s0,48(sp)
    800014d2:	74a2                	ld	s1,40(sp)
    800014d4:	7902                	ld	s2,32(sp)
    800014d6:	69e2                	ld	s3,24(sp)
    800014d8:	6a42                	ld	s4,16(sp)
    800014da:	6aa2                	ld	s5,8(sp)
    800014dc:	6121                	addi	sp,sp,64
    800014de:	8082                	ret
      kfree(mem);
    800014e0:	8526                	mv	a0,s1
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	52e080e7          	jalr	1326(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f22080e7          	jalr	-222(ra) # 80001412 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	bfd1                	j	800014ce <uvmalloc+0x74>
    return oldsz;
    800014fc:	852e                	mv	a0,a1
}
    800014fe:	8082                	ret
  return newsz;
    80001500:	8532                	mv	a0,a2
    80001502:	b7f1                	j	800014ce <uvmalloc+0x74>

0000000080001504 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001504:	7179                	addi	sp,sp,-48
    80001506:	f406                	sd	ra,40(sp)
    80001508:	f022                	sd	s0,32(sp)
    8000150a:	ec26                	sd	s1,24(sp)
    8000150c:	e84a                	sd	s2,16(sp)
    8000150e:	e44e                	sd	s3,8(sp)
    80001510:	e052                	sd	s4,0(sp)
    80001512:	1800                	addi	s0,sp,48
    80001514:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001516:	84aa                	mv	s1,a0
    80001518:	6905                	lui	s2,0x1
    8000151a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	4985                	li	s3,1
    8000151e:	a821                	j	80001536 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001520:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001522:	0532                	slli	a0,a0,0xc
    80001524:	00000097          	auipc	ra,0x0
    80001528:	fe0080e7          	jalr	-32(ra) # 80001504 <freewalk>
      pagetable[i] = 0;
    8000152c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001530:	04a1                	addi	s1,s1,8
    80001532:	03248163          	beq	s1,s2,80001554 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001536:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001538:	00f57793          	andi	a5,a0,15
    8000153c:	ff3782e3          	beq	a5,s3,80001520 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001540:	8905                	andi	a0,a0,1
    80001542:	d57d                	beqz	a0,80001530 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001544:	00007517          	auipc	a0,0x7
    80001548:	c4450513          	addi	a0,a0,-956 # 80008188 <digits+0x148>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001554:	8552                	mv	a0,s4
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	4ba080e7          	jalr	1210(ra) # 80000a10 <kfree>
}
    8000155e:	70a2                	ld	ra,40(sp)
    80001560:	7402                	ld	s0,32(sp)
    80001562:	64e2                	ld	s1,24(sp)
    80001564:	6942                	ld	s2,16(sp)
    80001566:	69a2                	ld	s3,8(sp)
    80001568:	6a02                	ld	s4,0(sp)
    8000156a:	6145                	addi	sp,sp,48
    8000156c:	8082                	ret

000000008000156e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000156e:	1101                	addi	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	addi	s0,sp,32
    80001578:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157a:	e999                	bnez	a1,80001590 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157c:	8526                	mv	a0,s1
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	f86080e7          	jalr	-122(ra) # 80001504 <freewalk>
}
    80001586:	60e2                	ld	ra,24(sp)
    80001588:	6442                	ld	s0,16(sp)
    8000158a:	64a2                	ld	s1,8(sp)
    8000158c:	6105                	addi	sp,sp,32
    8000158e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001590:	6605                	lui	a2,0x1
    80001592:	167d                	addi	a2,a2,-1
    80001594:	962e                	add	a2,a2,a1
    80001596:	4685                	li	a3,1
    80001598:	8231                	srli	a2,a2,0xc
    8000159a:	4581                	li	a1,0
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	d12080e7          	jalr	-750(ra) # 800012ae <uvmunmap>
    800015a4:	bfe1                	j	8000157c <uvmfree+0xe>

00000000800015a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a6:	c679                	beqz	a2,80001674 <uvmcopy+0xce>
{
    800015a8:	715d                	addi	sp,sp,-80
    800015aa:	e486                	sd	ra,72(sp)
    800015ac:	e0a2                	sd	s0,64(sp)
    800015ae:	fc26                	sd	s1,56(sp)
    800015b0:	f84a                	sd	s2,48(sp)
    800015b2:	f44e                	sd	s3,40(sp)
    800015b4:	f052                	sd	s4,32(sp)
    800015b6:	ec56                	sd	s5,24(sp)
    800015b8:	e85a                	sd	s6,16(sp)
    800015ba:	e45e                	sd	s7,8(sp)
    800015bc:	0880                	addi	s0,sp,80
    800015be:	8b2a                	mv	s6,a0
    800015c0:	8aae                	mv	s5,a1
    800015c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c6:	4601                	li	a2,0
    800015c8:	85ce                	mv	a1,s3
    800015ca:	855a                	mv	a0,s6
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	a04080e7          	jalr	-1532(ra) # 80000fd0 <walk>
    800015d4:	c531                	beqz	a0,80001620 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d6:	6118                	ld	a4,0(a0)
    800015d8:	00177793          	andi	a5,a4,1
    800015dc:	cbb1                	beqz	a5,80001630 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015de:	00a75593          	srli	a1,a4,0xa
    800015e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	522080e7          	jalr	1314(ra) # 80000b0c <kalloc>
    800015f2:	892a                	mv	s2,a0
    800015f4:	c939                	beqz	a0,8000164a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85de                	mv	a1,s7
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	75a080e7          	jalr	1882(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001602:	8726                	mv	a4,s1
    80001604:	86ca                	mv	a3,s2
    80001606:	6605                	lui	a2,0x1
    80001608:	85ce                	mv	a1,s3
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	b0a080e7          	jalr	-1270(ra) # 80001116 <mappages>
    80001614:	e515                	bnez	a0,80001640 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001616:	6785                	lui	a5,0x1
    80001618:	99be                	add	s3,s3,a5
    8000161a:	fb49e6e3          	bltu	s3,s4,800015c6 <uvmcopy+0x20>
    8000161e:	a081                	j	8000165e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b7850513          	addi	a0,a0,-1160 # 80008198 <digits+0x158>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001630:	00007517          	auipc	a0,0x7
    80001634:	b8850513          	addi	a0,a0,-1144 # 800081b8 <digits+0x178>
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	f08080e7          	jalr	-248(ra) # 80000540 <panic>
      kfree(mem);
    80001640:	854a                	mv	a0,s2
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	3ce080e7          	jalr	974(ra) # 80000a10 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164a:	4685                	li	a3,1
    8000164c:	00c9d613          	srli	a2,s3,0xc
    80001650:	4581                	li	a1,0
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	c5a080e7          	jalr	-934(ra) # 800012ae <uvmunmap>
  return -1;
    8000165c:	557d                	li	a0,-1
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
  return 0;
    80001674:	4501                	li	a0,0
}
    80001676:	8082                	ret

0000000080001678 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001678:	1141                	addi	sp,sp,-16
    8000167a:	e406                	sd	ra,8(sp)
    8000167c:	e022                	sd	s0,0(sp)
    8000167e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001680:	4601                	li	a2,0
    80001682:	00000097          	auipc	ra,0x0
    80001686:	94e080e7          	jalr	-1714(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000168a:	c901                	beqz	a0,8000169a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168c:	611c                	ld	a5,0(a0)
    8000168e:	9bbd                	andi	a5,a5,-17
    80001690:	e11c                	sd	a5,0(a0)
}
    80001692:	60a2                	ld	ra,8(sp)
    80001694:	6402                	ld	s0,0(sp)
    80001696:	0141                	addi	sp,sp,16
    80001698:	8082                	ret
    panic("uvmclear");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	b3e50513          	addi	a0,a0,-1218 # 800081d8 <digits+0x198>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	e9e080e7          	jalr	-354(ra) # 80000540 <panic>

00000000800016aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016aa:	c6bd                	beqz	a3,80001718 <copyout+0x6e>
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	e062                	sd	s8,0(sp)
    800016c2:	0880                	addi	s0,sp,80
    800016c4:	8b2a                	mv	s6,a0
    800016c6:	8c2e                	mv	s8,a1
    800016c8:	8a32                	mv	s4,a2
    800016ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ce:	6a85                	lui	s5,0x1
    800016d0:	a015                	j	800016f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d2:	9562                	add	a0,a0,s8
    800016d4:	0004861b          	sext.w	a2,s1
    800016d8:	85d2                	mv	a1,s4
    800016da:	41250533          	sub	a0,a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	676080e7          	jalr	1654(ra) # 80000d54 <memmove>

    len -= n;
    800016e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f0:	02098263          	beqz	s3,80001714 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f8:	85ca                	mv	a1,s2
    800016fa:	855a                	mv	a0,s6
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	97a080e7          	jalr	-1670(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001704:	cd01                	beqz	a0,8000171c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001706:	418904b3          	sub	s1,s2,s8
    8000170a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170c:	fc99f3e3          	bgeu	s3,s1,800016d2 <copyout+0x28>
    80001710:	84ce                	mv	s1,s3
    80001712:	b7c1                	j	800016d2 <copyout+0x28>
  }
  return 0;
    80001714:	4501                	li	a0,0
    80001716:	a021                	j	8000171e <copyout+0x74>
    80001718:	4501                	li	a0,0
}
    8000171a:	8082                	ret
      return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6c02                	ld	s8,0(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret

0000000080001736 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	caa5                	beqz	a3,800017a6 <copyin+0x70>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8a2e                	mv	s4,a1
    80001754:	8c32                	mv	s8,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a01d                	j	80001782 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175e:	018505b3          	add	a1,a0,s8
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412585b3          	sub	a1,a1,s2
    8000176a:	8552                	mv	a0,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	5e8080e7          	jalr	1512(ra) # 80000d54 <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001782:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855a                	mv	a0,s6
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	8ec080e7          	jalr	-1812(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001794:	418904b3          	sub	s1,s2,s8
    80001798:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179a:	fc99f2e3          	bgeu	s3,s1,8000175e <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	bf7d                	j	8000175e <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x76>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	c6c5                	beqz	a3,8000186c <copyinstr+0xa8>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8a2a                	mv	s4,a0
    800017de:	8b2e                	mv	s6,a1
    800017e0:	8bb2                	mv	s7,a2
    800017e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6985                	lui	s3,0x1
    800017e8:	a035                	j	80001814 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f0:	0017b793          	seqz	a5,a5
    800017f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f8:	60a6                	ld	ra,72(sp)
    800017fa:	6406                	ld	s0,64(sp)
    800017fc:	74e2                	ld	s1,56(sp)
    800017fe:	7942                	ld	s2,48(sp)
    80001800:	79a2                	ld	s3,40(sp)
    80001802:	7a02                	ld	s4,32(sp)
    80001804:	6ae2                	ld	s5,24(sp)
    80001806:	6b42                	ld	s6,16(sp)
    80001808:	6ba2                	ld	s7,8(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001812:	c8a9                	beqz	s1,80001864 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001814:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	8552                	mv	a0,s4
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	85a080e7          	jalr	-1958(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001824:	c131                	beqz	a0,80001868 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001826:	41790833          	sub	a6,s2,s7
    8000182a:	984e                	add	a6,a6,s3
    if(n > max)
    8000182c:	0104f363          	bgeu	s1,a6,80001832 <copyinstr+0x6e>
    80001830:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001832:	955e                	add	a0,a0,s7
    80001834:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001838:	fc080be3          	beqz	a6,8000180e <copyinstr+0x4a>
    8000183c:	985a                	add	a6,a6,s6
    8000183e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001840:	41650633          	sub	a2,a0,s6
    80001844:	14fd                	addi	s1,s1,-1
    80001846:	9b26                	add	s6,s6,s1
    80001848:	00f60733          	add	a4,a2,a5
    8000184c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001850:	df49                	beqz	a4,800017ea <copyinstr+0x26>
        *dst = *p;
    80001852:	00e78023          	sb	a4,0(a5)
      --max;
    80001856:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185c:	ff0796e3          	bne	a5,a6,80001848 <copyinstr+0x84>
      dst++;
    80001860:	8b42                	mv	s6,a6
    80001862:	b775                	j	8000180e <copyinstr+0x4a>
    80001864:	4781                	li	a5,0
    80001866:	b769                	j	800017f0 <copyinstr+0x2c>
      return -1;
    80001868:	557d                	li	a0,-1
    8000186a:	b779                	j	800017f8 <copyinstr+0x34>
  int got_null = 0;
    8000186c:	4781                	li	a5,0
  if(got_null){
    8000186e:	0017b793          	seqz	a5,a5
    80001872:	40f00533          	neg	a0,a5
}
    80001876:	8082                	ret

0000000080001878 <getportion>:

extern char trampoline[]; // trampoline.S

// Calculate time portion
void getportion(struct proc *p)
{
    80001878:	1101                	addi	sp,sp,-32
    8000187a:	ec06                	sd	ra,24(sp)
    8000187c:	e822                	sd	s0,16(sp)
    8000187e:	e426                	sd	s1,8(sp)
    80001880:	e04a                	sd	s2,0(sp)
    80001882:	1000                	addi	s0,sp,32
    80001884:	84aa                	mv	s1,a0
  int total = p->end - p->start;
    80001886:	17852903          	lw	s2,376(a0)
    8000188a:	17452783          	lw	a5,372(a0)
    8000188e:	40f9093b          	subw	s2,s2,a5
  p->Qtime[0] = total - (p->Qtime[2] + p->Qtime[1]);
    80001892:	17052583          	lw	a1,368(a0)
    80001896:	16c52603          	lw	a2,364(a0)
    8000189a:	00c586bb          	addw	a3,a1,a2
    8000189e:	40d906bb          	subw	a3,s2,a3
    800018a2:	16d52423          	sw	a3,360(a0)

  printf("%d %d %d\n", p->Qtime[2], p->Qtime[1], p->Qtime[0]);
    800018a6:	2681                	sext.w	a3,a3
    800018a8:	00007517          	auipc	a0,0x7
    800018ac:	94050513          	addi	a0,a0,-1728 # 800081e8 <digits+0x1a8>
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	cda080e7          	jalr	-806(ra) # 8000058a <printf>
  p->Qtime[2] = p->Qtime[2] * 100 / total;
    800018b8:	06400793          	li	a5,100
    800018bc:	1704a703          	lw	a4,368(s1)
    800018c0:	02e7873b          	mulw	a4,a5,a4
    800018c4:	0327473b          	divw	a4,a4,s2
    800018c8:	16e4a823          	sw	a4,368(s1)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    800018cc:	16c4a703          	lw	a4,364(s1)
    800018d0:	02e7873b          	mulw	a4,a5,a4
    800018d4:	0327473b          	divw	a4,a4,s2
    800018d8:	16e4a623          	sw	a4,364(s1)
  p->Qtime[0] = p->Qtime[0] * 100 / total;
    800018dc:	1684a703          	lw	a4,360(s1)
    800018e0:	02e787bb          	mulw	a5,a5,a4
    800018e4:	0327c7bb          	divw	a5,a5,s2
    800018e8:	16f4a423          	sw	a5,360(s1)
}
    800018ec:	60e2                	ld	ra,24(sp)
    800018ee:	6442                	ld	s0,16(sp)
    800018f0:	64a2                	ld	s1,8(sp)
    800018f2:	6902                	ld	s2,0(sp)
    800018f4:	6105                	addi	sp,sp,32
    800018f6:	8082                	ret

00000000800018f8 <findproc>:

// find where 'obj' process resides in
// the Q[priority] queue
int findproc(struct proc *obj, int priority)
{
    800018f8:	1141                	addi	sp,sp,-16
    800018fa:	e422                	sd	s0,8(sp)
    800018fc:	0800                	addi	s0,sp,16
  int index = 0;
  while (1)
  {
    if (Q[priority][index] == obj)
    800018fe:	00959713          	slli	a4,a1,0x9
    80001902:	00010797          	auipc	a5,0x10
    80001906:	04e78793          	addi	a5,a5,78 # 80011950 <Q>
    8000190a:	97ba                	add	a5,a5,a4
    8000190c:	639c                	ld	a5,0(a5)
    8000190e:	02f50263          	beq	a0,a5,80001932 <findproc+0x3a>
    80001912:	86aa                	mv	a3,a0
    80001914:	00010797          	auipc	a5,0x10
    80001918:	04478793          	addi	a5,a5,68 # 80011958 <Q+0x8>
    8000191c:	97ba                	add	a5,a5,a4
  int index = 0;
    8000191e:	4501                	li	a0,0
      break;
    index++;
    80001920:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    80001922:	07a1                	addi	a5,a5,8
    80001924:	ff87b703          	ld	a4,-8(a5)
    80001928:	fed71ce3          	bne	a4,a3,80001920 <findproc+0x28>
  }
  return index;
}
    8000192c:	6422                	ld	s0,8(sp)
    8000192e:	0141                	addi	sp,sp,16
    80001930:	8082                	ret
  int index = 0;
    80001932:	4501                	li	a0,0
    80001934:	bfe5                	j	8000192c <findproc+0x34>

0000000080001936 <movequeue>:

// handle process change
void movequeue(struct proc *obj, int priority, int opt)
{
    80001936:	7179                	addi	sp,sp,-48
    80001938:	f406                	sd	ra,40(sp)
    8000193a:	f022                	sd	s0,32(sp)
    8000193c:	ec26                	sd	s1,24(sp)
    8000193e:	e84a                	sd	s2,16(sp)
    80001940:	e44e                	sd	s3,8(sp)
    80001942:	1800                	addi	s0,sp,48
    80001944:	84aa                	mv	s1,a0
    80001946:	892e                	mv	s2,a1
  // INSERT means pushing process to empty process
  // so doesn't need to handle this operation
  if (opt != INSERT)
    80001948:	4785                	li	a5,1
    8000194a:	06f60163          	beq	a2,a5,800019ac <movequeue+0x76>
    8000194e:	89b2                	mv	s3,a2
  {
    // delete the obj process from queue where it was in
    // and pull up the processes behind
    // obj process is in Q[obj.priority][pos]
    int pos = findproc(obj, obj->priority);
    80001950:	17c52583          	lw	a1,380(a0)
    80001954:	00000097          	auipc	ra,0x0
    80001958:	fa4080e7          	jalr	-92(ra) # 800018f8 <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    8000195c:	03e00793          	li	a5,62
    80001960:	02a7c863          	blt	a5,a0,80001990 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001964:	00010697          	auipc	a3,0x10
    80001968:	fec68693          	addi	a3,a3,-20 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    8000196c:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001970:	17c4a783          	lw	a5,380(s1)
    80001974:	862a                	mv	a2,a0
    80001976:	2505                	addiw	a0,a0,1
    80001978:	079a                	slli	a5,a5,0x6
    8000197a:	00a78733          	add	a4,a5,a0
    8000197e:	070e                	slli	a4,a4,0x3
    80001980:	9736                	add	a4,a4,a3
    80001982:	6318                	ld	a4,0(a4)
    80001984:	97b2                	add	a5,a5,a2
    80001986:	078e                	slli	a5,a5,0x3
    80001988:	97b6                	add	a5,a5,a3
    8000198a:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    8000198c:	feb512e3          	bne	a0,a1,80001970 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    80001990:	17c4a783          	lw	a5,380(s1)
    80001994:	00979713          	slli	a4,a5,0x9
    80001998:	00010797          	auipc	a5,0x10
    8000199c:	fb878793          	addi	a5,a5,-72 # 80011950 <Q>
    800019a0:	97ba                	add	a5,a5,a4
    800019a2:	1e07bc23          	sd	zero,504(a5)
  }

  // DELETE means just delete the process from all Qs,
  // so doesn't have to handle this operation
  if (opt != DELETE)
    800019a6:	4789                	li	a5,2
    800019a8:	02f98463          	beq	s3,a5,800019d0 <movequeue+0x9a>
  {
    // insert obj process in another queue. insertback
    // endstart indicates the position right after the tail
    // which can be found by finding NULL process in the queue
    int endstart = findproc(0, priority);
    800019ac:	85ca                	mv	a1,s2
    800019ae:	4501                	li	a0,0
    800019b0:	00000097          	auipc	ra,0x0
    800019b4:	f48080e7          	jalr	-184(ra) # 800018f8 <findproc>
    Q[priority][endstart] = obj;
    800019b8:	00691793          	slli	a5,s2,0x6
    800019bc:	97aa                	add	a5,a5,a0
    800019be:	078e                	slli	a5,a5,0x3
    800019c0:	00010717          	auipc	a4,0x10
    800019c4:	f9070713          	addi	a4,a4,-112 # 80011950 <Q>
    800019c8:	97ba                	add	a5,a5,a4
    800019ca:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    800019cc:	1724ae23          	sw	s2,380(s1)
  }
}
    800019d0:	70a2                	ld	ra,40(sp)
    800019d2:	7402                	ld	s0,32(sp)
    800019d4:	64e2                	ld	s1,24(sp)
    800019d6:	6942                	ld	s2,16(sp)
    800019d8:	69a2                	ld	s3,8(sp)
    800019da:	6145                	addi	sp,sp,48
    800019dc:	8082                	ret

00000000800019de <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	1000                	addi	s0,sp,32
    800019e8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	198080e7          	jalr	408(ra) # 80000b82 <holding>
    800019f2:	c909                	beqz	a0,80001a04 <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    800019f4:	749c                	ld	a5,40(s1)
    800019f6:	00978f63          	beq	a5,s1,80001a14 <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    // should be moved to Q2
    movequeue(p, 2, MOVE);
  }
}
    800019fa:	60e2                	ld	ra,24(sp)
    800019fc:	6442                	ld	s0,16(sp)
    800019fe:	64a2                	ld	s1,8(sp)
    80001a00:	6105                	addi	sp,sp,32
    80001a02:	8082                	ret
    panic("wakeup1");
    80001a04:	00006517          	auipc	a0,0x6
    80001a08:	7f450513          	addi	a0,a0,2036 # 800081f8 <digits+0x1b8>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	b34080e7          	jalr	-1228(ra) # 80000540 <panic>
  if (p->chan == p && p->state == SLEEPING)
    80001a14:	4c98                	lw	a4,24(s1)
    80001a16:	4785                	li	a5,1
    80001a18:	fef711e3          	bne	a4,a5,800019fa <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a1c:	4789                	li	a5,2
    80001a1e:	cc9c                	sw	a5,24(s1)
    movequeue(p, 2, MOVE);
    80001a20:	4601                	li	a2,0
    80001a22:	4589                	li	a1,2
    80001a24:	8526                	mv	a0,s1
    80001a26:	00000097          	auipc	ra,0x0
    80001a2a:	f10080e7          	jalr	-240(ra) # 80001936 <movequeue>
}
    80001a2e:	b7f1                	j	800019fa <wakeup1+0x1c>

0000000080001a30 <procinit>:
{
    80001a30:	715d                	addi	sp,sp,-80
    80001a32:	e486                	sd	ra,72(sp)
    80001a34:	e0a2                	sd	s0,64(sp)
    80001a36:	fc26                	sd	s1,56(sp)
    80001a38:	f84a                	sd	s2,48(sp)
    80001a3a:	f44e                	sd	s3,40(sp)
    80001a3c:	f052                	sd	s4,32(sp)
    80001a3e:	ec56                	sd	s5,24(sp)
    80001a40:	e85a                	sd	s6,16(sp)
    80001a42:	e45e                	sd	s7,8(sp)
    80001a44:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a46:	00006597          	auipc	a1,0x6
    80001a4a:	7ba58593          	addi	a1,a1,1978 # 80008200 <digits+0x1c0>
    80001a4e:	00010517          	auipc	a0,0x10
    80001a52:	50250513          	addi	a0,a0,1282 # 80011f50 <pid_lock>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	116080e7          	jalr	278(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a5e:	00011917          	auipc	s2,0x11
    80001a62:	a0a90913          	addi	s2,s2,-1526 # 80012468 <proc>
    initlock(&p->lock, "proc");
    80001a66:	00006b97          	auipc	s7,0x6
    80001a6a:	7a2b8b93          	addi	s7,s7,1954 # 80008208 <digits+0x1c8>
    uint64 va = KSTACK((int)(p - proc));
    80001a6e:	8b4a                	mv	s6,s2
    80001a70:	00006a97          	auipc	s5,0x6
    80001a74:	590a8a93          	addi	s5,s5,1424 # 80008000 <etext>
    80001a78:	040009b7          	lui	s3,0x4000
    80001a7c:	19fd                	addi	s3,s3,-1
    80001a7e:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a80:	00017a17          	auipc	s4,0x17
    80001a84:	9e8a0a13          	addi	s4,s4,-1560 # 80018468 <tickslock>
    initlock(&p->lock, "proc");
    80001a88:	85de                	mv	a1,s7
    80001a8a:	854a                	mv	a0,s2
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	0e0080e7          	jalr	224(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	078080e7          	jalr	120(ra) # 80000b0c <kalloc>
    80001a9c:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a9e:	c929                	beqz	a0,80001af0 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001aa0:	416904b3          	sub	s1,s2,s6
    80001aa4:	849d                	srai	s1,s1,0x7
    80001aa6:	000ab783          	ld	a5,0(s5)
    80001aaa:	02f484b3          	mul	s1,s1,a5
    80001aae:	2485                	addiw	s1,s1,1
    80001ab0:	00d4949b          	slliw	s1,s1,0xd
    80001ab4:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ab8:	4699                	li	a3,6
    80001aba:	6605                	lui	a2,0x1
    80001abc:	8526                	mv	a0,s1
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	6e6080e7          	jalr	1766(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001ac6:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001aca:	18090913          	addi	s2,s2,384
    80001ace:	fb491de3          	bne	s2,s4,80001a88 <procinit+0x58>
  kvminithart();
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	4da080e7          	jalr	1242(ra) # 80000fac <kvminithart>
}
    80001ada:	60a6                	ld	ra,72(sp)
    80001adc:	6406                	ld	s0,64(sp)
    80001ade:	74e2                	ld	s1,56(sp)
    80001ae0:	7942                	ld	s2,48(sp)
    80001ae2:	79a2                	ld	s3,40(sp)
    80001ae4:	7a02                	ld	s4,32(sp)
    80001ae6:	6ae2                	ld	s5,24(sp)
    80001ae8:	6b42                	ld	s6,16(sp)
    80001aea:	6ba2                	ld	s7,8(sp)
    80001aec:	6161                	addi	sp,sp,80
    80001aee:	8082                	ret
      panic("kalloc");
    80001af0:	00006517          	auipc	a0,0x6
    80001af4:	72050513          	addi	a0,a0,1824 # 80008210 <digits+0x1d0>
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	a48080e7          	jalr	-1464(ra) # 80000540 <panic>

0000000080001b00 <cpuid>:
{
    80001b00:	1141                	addi	sp,sp,-16
    80001b02:	e422                	sd	s0,8(sp)
    80001b04:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b06:	8512                	mv	a0,tp
}
    80001b08:	2501                	sext.w	a0,a0
    80001b0a:	6422                	ld	s0,8(sp)
    80001b0c:	0141                	addi	sp,sp,16
    80001b0e:	8082                	ret

0000000080001b10 <mycpu>:
{
    80001b10:	1141                	addi	sp,sp,-16
    80001b12:	e422                	sd	s0,8(sp)
    80001b14:	0800                	addi	s0,sp,16
    80001b16:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b18:	2781                	sext.w	a5,a5
    80001b1a:	079e                	slli	a5,a5,0x7
}
    80001b1c:	00010517          	auipc	a0,0x10
    80001b20:	44c50513          	addi	a0,a0,1100 # 80011f68 <cpus>
    80001b24:	953e                	add	a0,a0,a5
    80001b26:	6422                	ld	s0,8(sp)
    80001b28:	0141                	addi	sp,sp,16
    80001b2a:	8082                	ret

0000000080001b2c <myproc>:
{
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	1000                	addi	s0,sp,32
  push_off();
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	07a080e7          	jalr	122(ra) # 80000bb0 <push_off>
    80001b3e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b40:	2781                	sext.w	a5,a5
    80001b42:	079e                	slli	a5,a5,0x7
    80001b44:	00010717          	auipc	a4,0x10
    80001b48:	e0c70713          	addi	a4,a4,-500 # 80011950 <Q>
    80001b4c:	97ba                	add	a5,a5,a4
    80001b4e:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	0fe080e7          	jalr	254(ra) # 80000c50 <pop_off>
}
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	60e2                	ld	ra,24(sp)
    80001b5e:	6442                	ld	s0,16(sp)
    80001b60:	64a2                	ld	s1,8(sp)
    80001b62:	6105                	addi	sp,sp,32
    80001b64:	8082                	ret

0000000080001b66 <forkret>:
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e406                	sd	ra,8(sp)
    80001b6a:	e022                	sd	s0,0(sp)
    80001b6c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	fbe080e7          	jalr	-66(ra) # 80001b2c <myproc>
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	13a080e7          	jalr	314(ra) # 80000cb0 <release>
  if (first)
    80001b7e:	00007797          	auipc	a5,0x7
    80001b82:	cf27a783          	lw	a5,-782(a5) # 80008870 <first.1>
    80001b86:	eb89                	bnez	a5,80001b98 <forkret+0x32>
  usertrapret();
    80001b88:	00001097          	auipc	ra,0x1
    80001b8c:	dfe080e7          	jalr	-514(ra) # 80002986 <usertrapret>
}
    80001b90:	60a2                	ld	ra,8(sp)
    80001b92:	6402                	ld	s0,0(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret
    first = 0;
    80001b98:	00007797          	auipc	a5,0x7
    80001b9c:	cc07ac23          	sw	zero,-808(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001ba0:	4505                	li	a0,1
    80001ba2:	00002097          	auipc	ra,0x2
    80001ba6:	b6a080e7          	jalr	-1174(ra) # 8000370c <fsinit>
    80001baa:	bff9                	j	80001b88 <forkret+0x22>

0000000080001bac <allocpid>:
{
    80001bac:	1101                	addi	sp,sp,-32
    80001bae:	ec06                	sd	ra,24(sp)
    80001bb0:	e822                	sd	s0,16(sp)
    80001bb2:	e426                	sd	s1,8(sp)
    80001bb4:	e04a                	sd	s2,0(sp)
    80001bb6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bb8:	00010917          	auipc	s2,0x10
    80001bbc:	39890913          	addi	s2,s2,920 # 80011f50 <pid_lock>
    80001bc0:	854a                	mv	a0,s2
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	03a080e7          	jalr	58(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001bca:	00007797          	auipc	a5,0x7
    80001bce:	caa78793          	addi	a5,a5,-854 # 80008874 <nextpid>
    80001bd2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bd4:	0014871b          	addiw	a4,s1,1
    80001bd8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bda:	854a                	mv	a0,s2
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0d4080e7          	jalr	212(ra) # 80000cb0 <release>
}
    80001be4:	8526                	mv	a0,s1
    80001be6:	60e2                	ld	ra,24(sp)
    80001be8:	6442                	ld	s0,16(sp)
    80001bea:	64a2                	ld	s1,8(sp)
    80001bec:	6902                	ld	s2,0(sp)
    80001bee:	6105                	addi	sp,sp,32
    80001bf0:	8082                	ret

0000000080001bf2 <proc_pagetable>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	e04a                	sd	s2,0(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	772080e7          	jalr	1906(ra) # 80001372 <uvmcreate>
    80001c08:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c0a:	c121                	beqz	a0,80001c4a <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c0c:	4729                	li	a4,10
    80001c0e:	00005697          	auipc	a3,0x5
    80001c12:	3f268693          	addi	a3,a3,1010 # 80007000 <_trampoline>
    80001c16:	6605                	lui	a2,0x1
    80001c18:	040005b7          	lui	a1,0x4000
    80001c1c:	15fd                	addi	a1,a1,-1
    80001c1e:	05b2                	slli	a1,a1,0xc
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	4f6080e7          	jalr	1270(ra) # 80001116 <mappages>
    80001c28:	02054863          	bltz	a0,80001c58 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c2c:	4719                	li	a4,6
    80001c2e:	05893683          	ld	a3,88(s2)
    80001c32:	6605                	lui	a2,0x1
    80001c34:	020005b7          	lui	a1,0x2000
    80001c38:	15fd                	addi	a1,a1,-1
    80001c3a:	05b6                	slli	a1,a1,0xd
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	4d8080e7          	jalr	1240(ra) # 80001116 <mappages>
    80001c46:	02054163          	bltz	a0,80001c68 <proc_pagetable+0x76>
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    uvmfree(pagetable, 0);
    80001c58:	4581                	li	a1,0
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	912080e7          	jalr	-1774(ra) # 8000156e <uvmfree>
    return 0;
    80001c64:	4481                	li	s1,0
    80001c66:	b7d5                	j	80001c4a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c68:	4681                	li	a3,0
    80001c6a:	4605                	li	a2,1
    80001c6c:	040005b7          	lui	a1,0x4000
    80001c70:	15fd                	addi	a1,a1,-1
    80001c72:	05b2                	slli	a1,a1,0xc
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	638080e7          	jalr	1592(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c7e:	4581                	li	a1,0
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	8ec080e7          	jalr	-1812(ra) # 8000156e <uvmfree>
    return 0;
    80001c8a:	4481                	li	s1,0
    80001c8c:	bf7d                	j	80001c4a <proc_pagetable+0x58>

0000000080001c8e <proc_freepagetable>:
{
    80001c8e:	1101                	addi	sp,sp,-32
    80001c90:	ec06                	sd	ra,24(sp)
    80001c92:	e822                	sd	s0,16(sp)
    80001c94:	e426                	sd	s1,8(sp)
    80001c96:	e04a                	sd	s2,0(sp)
    80001c98:	1000                	addi	s0,sp,32
    80001c9a:	84aa                	mv	s1,a0
    80001c9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c9e:	4681                	li	a3,0
    80001ca0:	4605                	li	a2,1
    80001ca2:	040005b7          	lui	a1,0x4000
    80001ca6:	15fd                	addi	a1,a1,-1
    80001ca8:	05b2                	slli	a1,a1,0xc
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	604080e7          	jalr	1540(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cb2:	4681                	li	a3,0
    80001cb4:	4605                	li	a2,1
    80001cb6:	020005b7          	lui	a1,0x2000
    80001cba:	15fd                	addi	a1,a1,-1
    80001cbc:	05b6                	slli	a1,a1,0xd
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	5ee080e7          	jalr	1518(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001cc8:	85ca                	mv	a1,s2
    80001cca:	8526                	mv	a0,s1
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	8a2080e7          	jalr	-1886(ra) # 8000156e <uvmfree>
}
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6902                	ld	s2,0(sp)
    80001cdc:	6105                	addi	sp,sp,32
    80001cde:	8082                	ret

0000000080001ce0 <freeproc>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	1000                	addi	s0,sp,32
    80001cea:	84aa                	mv	s1,a0
  p->end = ticks;
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	3387a783          	lw	a5,824(a5) # 80009024 <ticks>
    80001cf4:	16f52c23          	sw	a5,376(a0)
  getportion(p);
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	b80080e7          	jalr	-1152(ra) # 80001878 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001d00:	1684a783          	lw	a5,360(s1)
    80001d04:	16c4a703          	lw	a4,364(s1)
    80001d08:	1704a683          	lw	a3,368(s1)
    80001d0c:	5c90                	lw	a2,56(s1)
    80001d0e:	15848593          	addi	a1,s1,344
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	50650513          	addi	a0,a0,1286 # 80008218 <digits+0x1d8>
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	870080e7          	jalr	-1936(ra) # 8000058a <printf>
  if (p->trapframe)
    80001d22:	6ca8                	ld	a0,88(s1)
    80001d24:	c509                	beqz	a0,80001d2e <freeproc+0x4e>
    kfree((void *)p->trapframe);
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	cea080e7          	jalr	-790(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001d2e:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d32:	68a8                	ld	a0,80(s1)
    80001d34:	c511                	beqz	a0,80001d40 <freeproc+0x60>
    proc_freepagetable(p->pagetable, p->sz);
    80001d36:	64ac                	ld	a1,72(s1)
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	f56080e7          	jalr	-170(ra) # 80001c8e <proc_freepagetable>
  p->pagetable = 0;
    80001d40:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d44:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d48:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d4c:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d50:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d54:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d58:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d5c:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d60:	0004ac23          	sw	zero,24(s1)
  p->Qtime[2] = 0;
    80001d64:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001d68:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001d6c:	1604a423          	sw	zero,360(s1)
  p->priority = 0;
    80001d70:	1604ae23          	sw	zero,380(s1)
  movequeue(p, 0, DELETE);
    80001d74:	4609                	li	a2,2
    80001d76:	4581                	li	a1,0
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	bbc080e7          	jalr	-1092(ra) # 80001936 <movequeue>
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret

0000000080001d8c <allocproc>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	e04a                	sd	s2,0(sp)
    80001d96:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d98:	00010497          	auipc	s1,0x10
    80001d9c:	6d048493          	addi	s1,s1,1744 # 80012468 <proc>
    80001da0:	00016917          	auipc	s2,0x16
    80001da4:	6c890913          	addi	s2,s2,1736 # 80018468 <tickslock>
    acquire(&p->lock);
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	e52080e7          	jalr	-430(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001db2:	4c9c                	lw	a5,24(s1)
    80001db4:	cf81                	beqz	a5,80001dcc <allocproc+0x40>
      release(&p->lock);
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	ef8080e7          	jalr	-264(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc0:	18048493          	addi	s1,s1,384
    80001dc4:	ff2492e3          	bne	s1,s2,80001da8 <allocproc+0x1c>
  return 0;
    80001dc8:	4481                	li	s1,0
    80001dca:	a0a5                	j	80001e32 <allocproc+0xa6>
  p->pid = allocpid();
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	de0080e7          	jalr	-544(ra) # 80001bac <allocpid>
    80001dd4:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	d36080e7          	jalr	-714(ra) # 80000b0c <kalloc>
    80001dde:	892a                	mv	s2,a0
    80001de0:	eca8                	sd	a0,88(s1)
    80001de2:	cd39                	beqz	a0,80001e40 <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001de4:	8526                	mv	a0,s1
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	e0c080e7          	jalr	-500(ra) # 80001bf2 <proc_pagetable>
    80001dee:	892a                	mv	s2,a0
    80001df0:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001df2:	cd31                	beqz	a0,80001e4e <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001df4:	07000613          	li	a2,112
    80001df8:	4581                	li	a1,0
    80001dfa:	06048513          	addi	a0,s1,96
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	efa080e7          	jalr	-262(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001e06:	00000797          	auipc	a5,0x0
    80001e0a:	d6078793          	addi	a5,a5,-672 # 80001b66 <forkret>
    80001e0e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e10:	60bc                	ld	a5,64(s1)
    80001e12:	6705                	lui	a4,0x1
    80001e14:	97ba                	add	a5,a5,a4
    80001e16:	f4bc                	sd	a5,104(s1)
  p->start = ticks;
    80001e18:	00007797          	auipc	a5,0x7
    80001e1c:	20c7a783          	lw	a5,524(a5) # 80009024 <ticks>
    80001e20:	16f4aa23          	sw	a5,372(s1)
  movequeue(p, 2, INSERT);
    80001e24:	4605                	li	a2,1
    80001e26:	4589                	li	a1,2
    80001e28:	8526                	mv	a0,s1
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	b0c080e7          	jalr	-1268(ra) # 80001936 <movequeue>
}
    80001e32:	8526                	mv	a0,s1
    80001e34:	60e2                	ld	ra,24(sp)
    80001e36:	6442                	ld	s0,16(sp)
    80001e38:	64a2                	ld	s1,8(sp)
    80001e3a:	6902                	ld	s2,0(sp)
    80001e3c:	6105                	addi	sp,sp,32
    80001e3e:	8082                	ret
    release(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e6e080e7          	jalr	-402(ra) # 80000cb0 <release>
    return 0;
    80001e4a:	84ca                	mv	s1,s2
    80001e4c:	b7dd                	j	80001e32 <allocproc+0xa6>
    freeproc(p);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	00000097          	auipc	ra,0x0
    80001e54:	e90080e7          	jalr	-368(ra) # 80001ce0 <freeproc>
    release(&p->lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e56080e7          	jalr	-426(ra) # 80000cb0 <release>
    return 0;
    80001e62:	84ca                	mv	s1,s2
    80001e64:	b7f9                	j	80001e32 <allocproc+0xa6>

0000000080001e66 <userinit>:
{
    80001e66:	1101                	addi	sp,sp,-32
    80001e68:	ec06                	sd	ra,24(sp)
    80001e6a:	e822                	sd	s0,16(sp)
    80001e6c:	e426                	sd	s1,8(sp)
    80001e6e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	f1c080e7          	jalr	-228(ra) # 80001d8c <allocproc>
    80001e78:	84aa                	mv	s1,a0
  initproc = p;
    80001e7a:	00007797          	auipc	a5,0x7
    80001e7e:	18a7bf23          	sd	a0,414(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e82:	03400613          	li	a2,52
    80001e86:	00007597          	auipc	a1,0x7
    80001e8a:	9fa58593          	addi	a1,a1,-1542 # 80008880 <initcode>
    80001e8e:	6928                	ld	a0,80(a0)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	510080e7          	jalr	1296(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e98:	6785                	lui	a5,0x1
    80001e9a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e9c:	6cb8                	ld	a4,88(s1)
    80001e9e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ea2:	6cb8                	ld	a4,88(s1)
    80001ea4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ea6:	4641                	li	a2,16
    80001ea8:	00006597          	auipc	a1,0x6
    80001eac:	3a058593          	addi	a1,a1,928 # 80008248 <digits+0x208>
    80001eb0:	15848513          	addi	a0,s1,344
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	f96080e7          	jalr	-106(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001ebc:	00006517          	auipc	a0,0x6
    80001ec0:	39c50513          	addi	a0,a0,924 # 80008258 <digits+0x218>
    80001ec4:	00002097          	auipc	ra,0x2
    80001ec8:	270080e7          	jalr	624(ra) # 80004134 <namei>
    80001ecc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ed0:	4789                	li	a5,2
    80001ed2:	cc9c                	sw	a5,24(s1)
  p->Qtime[2] = 0;
    80001ed4:	1604a823          	sw	zero,368(s1)
  p->Qtime[1] = 0;
    80001ed8:	1604a623          	sw	zero,364(s1)
  p->Qtime[0] = 0;
    80001edc:	1604a423          	sw	zero,360(s1)
  release(&p->lock);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	dce080e7          	jalr	-562(ra) # 80000cb0 <release>
}
    80001eea:	60e2                	ld	ra,24(sp)
    80001eec:	6442                	ld	s0,16(sp)
    80001eee:	64a2                	ld	s1,8(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret

0000000080001ef4 <growproc>:
{
    80001ef4:	1101                	addi	sp,sp,-32
    80001ef6:	ec06                	sd	ra,24(sp)
    80001ef8:	e822                	sd	s0,16(sp)
    80001efa:	e426                	sd	s1,8(sp)
    80001efc:	e04a                	sd	s2,0(sp)
    80001efe:	1000                	addi	s0,sp,32
    80001f00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	c2a080e7          	jalr	-982(ra) # 80001b2c <myproc>
    80001f0a:	892a                	mv	s2,a0
  sz = p->sz;
    80001f0c:	652c                	ld	a1,72(a0)
    80001f0e:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001f12:	00904f63          	bgtz	s1,80001f30 <growproc+0x3c>
  else if (n < 0)
    80001f16:	0204cc63          	bltz	s1,80001f4e <growproc+0x5a>
  p->sz = sz;
    80001f1a:	1602                	slli	a2,a2,0x20
    80001f1c:	9201                	srli	a2,a2,0x20
    80001f1e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f22:	4501                	li	a0,0
}
    80001f24:	60e2                	ld	ra,24(sp)
    80001f26:	6442                	ld	s0,16(sp)
    80001f28:	64a2                	ld	s1,8(sp)
    80001f2a:	6902                	ld	s2,0(sp)
    80001f2c:	6105                	addi	sp,sp,32
    80001f2e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f30:	9e25                	addw	a2,a2,s1
    80001f32:	1602                	slli	a2,a2,0x20
    80001f34:	9201                	srli	a2,a2,0x20
    80001f36:	1582                	slli	a1,a1,0x20
    80001f38:	9181                	srli	a1,a1,0x20
    80001f3a:	6928                	ld	a0,80(a0)
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	51e080e7          	jalr	1310(ra) # 8000145a <uvmalloc>
    80001f44:	0005061b          	sext.w	a2,a0
    80001f48:	fa69                	bnez	a2,80001f1a <growproc+0x26>
      return -1;
    80001f4a:	557d                	li	a0,-1
    80001f4c:	bfe1                	j	80001f24 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f4e:	9e25                	addw	a2,a2,s1
    80001f50:	1602                	slli	a2,a2,0x20
    80001f52:	9201                	srli	a2,a2,0x20
    80001f54:	1582                	slli	a1,a1,0x20
    80001f56:	9181                	srli	a1,a1,0x20
    80001f58:	6928                	ld	a0,80(a0)
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	4b8080e7          	jalr	1208(ra) # 80001412 <uvmdealloc>
    80001f62:	0005061b          	sext.w	a2,a0
    80001f66:	bf55                	j	80001f1a <growproc+0x26>

0000000080001f68 <fork>:
{
    80001f68:	7139                	addi	sp,sp,-64
    80001f6a:	fc06                	sd	ra,56(sp)
    80001f6c:	f822                	sd	s0,48(sp)
    80001f6e:	f426                	sd	s1,40(sp)
    80001f70:	f04a                	sd	s2,32(sp)
    80001f72:	ec4e                	sd	s3,24(sp)
    80001f74:	e852                	sd	s4,16(sp)
    80001f76:	e456                	sd	s5,8(sp)
    80001f78:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	bb2080e7          	jalr	-1102(ra) # 80001b2c <myproc>
    80001f82:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f84:	00000097          	auipc	ra,0x0
    80001f88:	e08080e7          	jalr	-504(ra) # 80001d8c <allocproc>
    80001f8c:	c96d                	beqz	a0,8000207e <fork+0x116>
    80001f8e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f90:	048ab603          	ld	a2,72(s5)
    80001f94:	692c                	ld	a1,80(a0)
    80001f96:	050ab503          	ld	a0,80(s5)
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	60c080e7          	jalr	1548(ra) # 800015a6 <uvmcopy>
    80001fa2:	04054a63          	bltz	a0,80001ff6 <fork+0x8e>
  np->sz = p->sz;
    80001fa6:	048ab783          	ld	a5,72(s5)
    80001faa:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001fae:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fb2:	058ab683          	ld	a3,88(s5)
    80001fb6:	87b6                	mv	a5,a3
    80001fb8:	0589b703          	ld	a4,88(s3)
    80001fbc:	12068693          	addi	a3,a3,288
    80001fc0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fc4:	6788                	ld	a0,8(a5)
    80001fc6:	6b8c                	ld	a1,16(a5)
    80001fc8:	6f90                	ld	a2,24(a5)
    80001fca:	01073023          	sd	a6,0(a4)
    80001fce:	e708                	sd	a0,8(a4)
    80001fd0:	eb0c                	sd	a1,16(a4)
    80001fd2:	ef10                	sd	a2,24(a4)
    80001fd4:	02078793          	addi	a5,a5,32
    80001fd8:	02070713          	addi	a4,a4,32
    80001fdc:	fed792e3          	bne	a5,a3,80001fc0 <fork+0x58>
  np->trapframe->a0 = 0;
    80001fe0:	0589b783          	ld	a5,88(s3)
    80001fe4:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fe8:	0d0a8493          	addi	s1,s5,208
    80001fec:	0d098913          	addi	s2,s3,208
    80001ff0:	150a8a13          	addi	s4,s5,336
    80001ff4:	a00d                	j	80002016 <fork+0xae>
    freeproc(np);
    80001ff6:	854e                	mv	a0,s3
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	ce8080e7          	jalr	-792(ra) # 80001ce0 <freeproc>
    release(&np->lock);
    80002000:	854e                	mv	a0,s3
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	cae080e7          	jalr	-850(ra) # 80000cb0 <release>
    return -1;
    8000200a:	54fd                	li	s1,-1
    8000200c:	a8b9                	j	8000206a <fork+0x102>
  for (i = 0; i < NOFILE; i++)
    8000200e:	04a1                	addi	s1,s1,8
    80002010:	0921                	addi	s2,s2,8
    80002012:	01448b63          	beq	s1,s4,80002028 <fork+0xc0>
    if (p->ofile[i])
    80002016:	6088                	ld	a0,0(s1)
    80002018:	d97d                	beqz	a0,8000200e <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    8000201a:	00002097          	auipc	ra,0x2
    8000201e:	7aa080e7          	jalr	1962(ra) # 800047c4 <filedup>
    80002022:	00a93023          	sd	a0,0(s2)
    80002026:	b7e5                	j	8000200e <fork+0xa6>
  np->cwd = idup(p->cwd);
    80002028:	150ab503          	ld	a0,336(s5)
    8000202c:	00002097          	auipc	ra,0x2
    80002030:	91a080e7          	jalr	-1766(ra) # 80003946 <idup>
    80002034:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002038:	4641                	li	a2,16
    8000203a:	158a8593          	addi	a1,s5,344
    8000203e:	15898513          	addi	a0,s3,344
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	e08080e7          	jalr	-504(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    8000204a:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    8000204e:	4789                	li	a5,2
    80002050:	00f9ac23          	sw	a5,24(s3)
  np->Qtime[2] = 0;
    80002054:	1609a823          	sw	zero,368(s3)
  np->Qtime[1] = 0;
    80002058:	1609a623          	sw	zero,364(s3)
  np->Qtime[0] = 0;
    8000205c:	1609a423          	sw	zero,360(s3)
  release(&np->lock);
    80002060:	854e                	mv	a0,s3
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c4e080e7          	jalr	-946(ra) # 80000cb0 <release>
}
    8000206a:	8526                	mv	a0,s1
    8000206c:	70e2                	ld	ra,56(sp)
    8000206e:	7442                	ld	s0,48(sp)
    80002070:	74a2                	ld	s1,40(sp)
    80002072:	7902                	ld	s2,32(sp)
    80002074:	69e2                	ld	s3,24(sp)
    80002076:	6a42                	ld	s4,16(sp)
    80002078:	6aa2                	ld	s5,8(sp)
    8000207a:	6121                	addi	sp,sp,64
    8000207c:	8082                	ret
    return -1;
    8000207e:	54fd                	li	s1,-1
    80002080:	b7ed                	j	8000206a <fork+0x102>

0000000080002082 <reparent>:
{
    80002082:	7179                	addi	sp,sp,-48
    80002084:	f406                	sd	ra,40(sp)
    80002086:	f022                	sd	s0,32(sp)
    80002088:	ec26                	sd	s1,24(sp)
    8000208a:	e84a                	sd	s2,16(sp)
    8000208c:	e44e                	sd	s3,8(sp)
    8000208e:	e052                	sd	s4,0(sp)
    80002090:	1800                	addi	s0,sp,48
    80002092:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002094:	00010497          	auipc	s1,0x10
    80002098:	3d448493          	addi	s1,s1,980 # 80012468 <proc>
      pp->parent = initproc;
    8000209c:	00007a17          	auipc	s4,0x7
    800020a0:	f7ca0a13          	addi	s4,s4,-132 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800020a4:	00016997          	auipc	s3,0x16
    800020a8:	3c498993          	addi	s3,s3,964 # 80018468 <tickslock>
    800020ac:	a029                	j	800020b6 <reparent+0x34>
    800020ae:	18048493          	addi	s1,s1,384
    800020b2:	03348363          	beq	s1,s3,800020d8 <reparent+0x56>
    if (pp->parent == p)
    800020b6:	709c                	ld	a5,32(s1)
    800020b8:	ff279be3          	bne	a5,s2,800020ae <reparent+0x2c>
      acquire(&pp->lock);
    800020bc:	8526                	mv	a0,s1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b3e080e7          	jalr	-1218(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    800020c6:	000a3783          	ld	a5,0(s4)
    800020ca:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020cc:	8526                	mv	a0,s1
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	be2080e7          	jalr	-1054(ra) # 80000cb0 <release>
    800020d6:	bfe1                	j	800020ae <reparent+0x2c>
}
    800020d8:	70a2                	ld	ra,40(sp)
    800020da:	7402                	ld	s0,32(sp)
    800020dc:	64e2                	ld	s1,24(sp)
    800020de:	6942                	ld	s2,16(sp)
    800020e0:	69a2                	ld	s3,8(sp)
    800020e2:	6a02                	ld	s4,0(sp)
    800020e4:	6145                	addi	sp,sp,48
    800020e6:	8082                	ret

00000000800020e8 <scheduler>:
{
    800020e8:	7159                	addi	sp,sp,-112
    800020ea:	f486                	sd	ra,104(sp)
    800020ec:	f0a2                	sd	s0,96(sp)
    800020ee:	eca6                	sd	s1,88(sp)
    800020f0:	e8ca                	sd	s2,80(sp)
    800020f2:	e4ce                	sd	s3,72(sp)
    800020f4:	e0d2                	sd	s4,64(sp)
    800020f6:	fc56                	sd	s5,56(sp)
    800020f8:	f85a                	sd	s6,48(sp)
    800020fa:	f45e                	sd	s7,40(sp)
    800020fc:	f062                	sd	s8,32(sp)
    800020fe:	ec66                	sd	s9,24(sp)
    80002100:	e86a                	sd	s10,16(sp)
    80002102:	e46e                	sd	s11,8(sp)
    80002104:	1880                	addi	s0,sp,112
    80002106:	8792                	mv	a5,tp
  int id = r_tp();
    80002108:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000210a:	00779c93          	slli	s9,a5,0x7
    8000210e:	00010717          	auipc	a4,0x10
    80002112:	84270713          	addi	a4,a4,-1982 # 80011950 <Q>
    80002116:	9766                	add	a4,a4,s9
    80002118:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    8000211c:	00010717          	auipc	a4,0x10
    80002120:	e5470713          	addi	a4,a4,-428 # 80011f70 <cpus+0x8>
    80002124:	9cba                	add	s9,s9,a4
  int exec = 0;
    80002126:	4c01                	li	s8,0
        c->proc = p;
    80002128:	00010d97          	auipc	s11,0x10
    8000212c:	828d8d93          	addi	s11,s11,-2008 # 80011950 <Q>
    80002130:	079e                	slli	a5,a5,0x7
    80002132:	00fd8ab3          	add	s5,s11,a5
        pid[tail] = p->pid;
    80002136:	00007b17          	auipc	s6,0x7
    8000213a:	eeab0b13          	addi	s6,s6,-278 # 80009020 <tail>
    8000213e:	00011d17          	auipc	s10,0x11
    80002142:	812d0d13          	addi	s10,s10,-2030 # 80012950 <proc+0x4e8>
    80002146:	a061                	j	800021ce <scheduler+0xe6>
      exec = 0;
    80002148:	4c01                	li	s8,0
    8000214a:	a051                	j	800021ce <scheduler+0xe6>
      release(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b62080e7          	jalr	-1182(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    80002156:	0921                	addi	s2,s2,8
    80002158:	05390663          	beq	s2,s3,800021a4 <scheduler+0xbc>
      p = Q[2][i];
    8000215c:	00093483          	ld	s1,0(s2)
      if (p==0)
    80002160:	c0b1                	beqz	s1,800021a4 <scheduler+0xbc>
      acquire(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a98080e7          	jalr	-1384(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    8000216c:	4c9c                	lw	a5,24(s1)
    8000216e:	fd479fe3          	bne	a5,s4,8000214c <scheduler+0x64>
        p->state = RUNNING;
    80002172:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002176:	609abc23          	sd	s1,1560(s5)
        swtch(&c->context, &p->context);
    8000217a:	06048593          	addi	a1,s1,96
    8000217e:	8566                	mv	a0,s9
    80002180:	00000097          	auipc	ra,0x0
    80002184:	75c080e7          	jalr	1884(ra) # 800028dc <swtch>
        pid[tail] = p->pid;
    80002188:	000b2783          	lw	a5,0(s6)
    8000218c:	5c94                	lw	a3,56(s1)
    8000218e:	00279713          	slli	a4,a5,0x2
    80002192:	976a                	add	a4,a4,s10
    80002194:	a0d72c23          	sw	a3,-1512(a4)
        tail++;
    80002198:	2785                	addiw	a5,a5,1
    8000219a:	00fb2023          	sw	a5,0(s6)
        c->proc = 0;
    8000219e:	600abc23          	sd	zero,1560(s5)
    800021a2:	b76d                	j	8000214c <scheduler+0x64>
    p = Q[1][exec];
    800021a4:	040c0793          	addi	a5,s8,64
    800021a8:	078e                	slli	a5,a5,0x3
    800021aa:	97ee                	add	a5,a5,s11
    800021ac:	6384                	ld	s1,0(a5)
    if (p == 0)
    800021ae:	dcc9                	beqz	s1,80002148 <scheduler+0x60>
    acquire(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a4a080e7          	jalr	-1462(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    800021ba:	4c98                	lw	a4,24(s1)
    800021bc:	4789                	li	a5,2
    800021be:	04f70863          	beq	a4,a5,8000220e <scheduler+0x126>
    release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	aec080e7          	jalr	-1300(ra) # 80000cb0 <release>
    exec++;
    800021cc:	2c05                	addiw	s8,s8,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021d6:	10079073          	csrw	sstatus,a5
    int tail2 = findproc(0, 2) - 1;
    800021da:	4589                	li	a1,2
    800021dc:	4501                	li	a0,0
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	71a080e7          	jalr	1818(ra) # 800018f8 <findproc>
    for (int i = 0; i <= tail2; i++)
    800021e6:	faa05fe3          	blez	a0,800021a4 <scheduler+0xbc>
    800021ea:	00010917          	auipc	s2,0x10
    800021ee:	b6690913          	addi	s2,s2,-1178 # 80011d50 <Q+0x400>
    800021f2:	fff5099b          	addiw	s3,a0,-1
    800021f6:	02099793          	slli	a5,s3,0x20
    800021fa:	01d7d993          	srli	s3,a5,0x1d
    800021fe:	00010797          	auipc	a5,0x10
    80002202:	b5a78793          	addi	a5,a5,-1190 # 80011d58 <Q+0x408>
    80002206:	99be                	add	s3,s3,a5
      if (p->state == RUNNABLE)
    80002208:	4a09                	li	s4,2
        p->state = RUNNING;
    8000220a:	4b8d                	li	s7,3
    8000220c:	bf81                	j	8000215c <scheduler+0x74>
      p->state = RUNNING;
    8000220e:	478d                	li	a5,3
    80002210:	cc9c                	sw	a5,24(s1)
      c->proc = p;
    80002212:	609abc23          	sd	s1,1560(s5)
      swtch(&c->context, &p->context);
    80002216:	06048593          	addi	a1,s1,96
    8000221a:	8566                	mv	a0,s9
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	6c0080e7          	jalr	1728(ra) # 800028dc <swtch>
      pid[tail] = p->pid;
    80002224:	000b2783          	lw	a5,0(s6)
    80002228:	5c94                	lw	a3,56(s1)
    8000222a:	00279713          	slli	a4,a5,0x2
    8000222e:	976a                	add	a4,a4,s10
    80002230:	a0d72c23          	sw	a3,-1512(a4)
      tail++;
    80002234:	2785                	addiw	a5,a5,1
    80002236:	00fb2023          	sw	a5,0(s6)
      c->proc = 0;
    8000223a:	600abc23          	sd	zero,1560(s5)
    8000223e:	b751                	j	800021c2 <scheduler+0xda>

0000000080002240 <sched>:
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	8de080e7          	jalr	-1826(ra) # 80001b2c <myproc>
    80002256:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	92a080e7          	jalr	-1750(ra) # 80000b82 <holding>
    80002260:	c93d                	beqz	a0,800022d6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002262:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002264:	2781                	sext.w	a5,a5
    80002266:	079e                	slli	a5,a5,0x7
    80002268:	0000f717          	auipc	a4,0xf
    8000226c:	6e870713          	addi	a4,a4,1768 # 80011950 <Q>
    80002270:	97ba                	add	a5,a5,a4
    80002272:	6907a703          	lw	a4,1680(a5)
    80002276:	4785                	li	a5,1
    80002278:	06f71763          	bne	a4,a5,800022e6 <sched+0xa6>
  if (p->state == RUNNING)
    8000227c:	4c98                	lw	a4,24(s1)
    8000227e:	478d                	li	a5,3
    80002280:	06f70b63          	beq	a4,a5,800022f6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002284:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002288:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000228a:	efb5                	bnez	a5,80002306 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000228c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000228e:	0000f917          	auipc	s2,0xf
    80002292:	6c290913          	addi	s2,s2,1730 # 80011950 <Q>
    80002296:	2781                	sext.w	a5,a5
    80002298:	079e                	slli	a5,a5,0x7
    8000229a:	97ca                	add	a5,a5,s2
    8000229c:	6947a983          	lw	s3,1684(a5)
    800022a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022a2:	2781                	sext.w	a5,a5
    800022a4:	079e                	slli	a5,a5,0x7
    800022a6:	00010597          	auipc	a1,0x10
    800022aa:	cca58593          	addi	a1,a1,-822 # 80011f70 <cpus+0x8>
    800022ae:	95be                	add	a1,a1,a5
    800022b0:	06048513          	addi	a0,s1,96
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	628080e7          	jalr	1576(ra) # 800028dc <swtch>
    800022bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022be:	2781                	sext.w	a5,a5
    800022c0:	079e                	slli	a5,a5,0x7
    800022c2:	97ca                	add	a5,a5,s2
    800022c4:	6937aa23          	sw	s3,1684(a5)
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret
    panic("sched p->lock");
    800022d6:	00006517          	auipc	a0,0x6
    800022da:	f8a50513          	addi	a0,a0,-118 # 80008260 <digits+0x220>
    800022de:	ffffe097          	auipc	ra,0xffffe
    800022e2:	262080e7          	jalr	610(ra) # 80000540 <panic>
    panic("sched locks");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f8a50513          	addi	a0,a0,-118 # 80008270 <digits+0x230>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	252080e7          	jalr	594(ra) # 80000540 <panic>
    panic("sched running");
    800022f6:	00006517          	auipc	a0,0x6
    800022fa:	f8a50513          	addi	a0,a0,-118 # 80008280 <digits+0x240>
    800022fe:	ffffe097          	auipc	ra,0xffffe
    80002302:	242080e7          	jalr	578(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f8a50513          	addi	a0,a0,-118 # 80008290 <digits+0x250>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	232080e7          	jalr	562(ra) # 80000540 <panic>

0000000080002316 <exit>:
{
    80002316:	7179                	addi	sp,sp,-48
    80002318:	f406                	sd	ra,40(sp)
    8000231a:	f022                	sd	s0,32(sp)
    8000231c:	ec26                	sd	s1,24(sp)
    8000231e:	e84a                	sd	s2,16(sp)
    80002320:	e44e                	sd	s3,8(sp)
    80002322:	e052                	sd	s4,0(sp)
    80002324:	1800                	addi	s0,sp,48
    80002326:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002328:	00000097          	auipc	ra,0x0
    8000232c:	804080e7          	jalr	-2044(ra) # 80001b2c <myproc>
    80002330:	89aa                	mv	s3,a0
  if (p == initproc)
    80002332:	00007797          	auipc	a5,0x7
    80002336:	ce67b783          	ld	a5,-794(a5) # 80009018 <initproc>
    8000233a:	0d050493          	addi	s1,a0,208
    8000233e:	15050913          	addi	s2,a0,336
    80002342:	02a79363          	bne	a5,a0,80002368 <exit+0x52>
    panic("init exiting");
    80002346:	00006517          	auipc	a0,0x6
    8000234a:	f6250513          	addi	a0,a0,-158 # 800082a8 <digits+0x268>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1f2080e7          	jalr	498(ra) # 80000540 <panic>
      fileclose(f);
    80002356:	00002097          	auipc	ra,0x2
    8000235a:	4c0080e7          	jalr	1216(ra) # 80004816 <fileclose>
      p->ofile[fd] = 0;
    8000235e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002362:	04a1                	addi	s1,s1,8
    80002364:	01248563          	beq	s1,s2,8000236e <exit+0x58>
    if (p->ofile[fd])
    80002368:	6088                	ld	a0,0(s1)
    8000236a:	f575                	bnez	a0,80002356 <exit+0x40>
    8000236c:	bfdd                	j	80002362 <exit+0x4c>
  begin_op();
    8000236e:	00002097          	auipc	ra,0x2
    80002372:	fd6080e7          	jalr	-42(ra) # 80004344 <begin_op>
  iput(p->cwd);
    80002376:	1509b503          	ld	a0,336(s3)
    8000237a:	00001097          	auipc	ra,0x1
    8000237e:	7c4080e7          	jalr	1988(ra) # 80003b3e <iput>
  end_op();
    80002382:	00002097          	auipc	ra,0x2
    80002386:	042080e7          	jalr	66(ra) # 800043c4 <end_op>
  p->cwd = 0;
    8000238a:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000238e:	00007497          	auipc	s1,0x7
    80002392:	c8a48493          	addi	s1,s1,-886 # 80009018 <initproc>
    80002396:	6088                	ld	a0,0(s1)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	864080e7          	jalr	-1948(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    800023a0:	6088                	ld	a0,0(s1)
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	63c080e7          	jalr	1596(ra) # 800019de <wakeup1>
  release(&initproc->lock);
    800023aa:	6088                	ld	a0,0(s1)
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	904080e7          	jalr	-1788(ra) # 80000cb0 <release>
  acquire(&p->lock);
    800023b4:	854e                	mv	a0,s3
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	846080e7          	jalr	-1978(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    800023be:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023c2:	854e                	mv	a0,s3
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8ec080e7          	jalr	-1812(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	82e080e7          	jalr	-2002(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    800023d6:	854e                	mv	a0,s3
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	824080e7          	jalr	-2012(ra) # 80000bfc <acquire>
  reparent(p);
    800023e0:	854e                	mv	a0,s3
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	ca0080e7          	jalr	-864(ra) # 80002082 <reparent>
  wakeup1(original_parent);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	5f2080e7          	jalr	1522(ra) # 800019de <wakeup1>
  p->xstate = status;
    800023f4:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023f8:	4791                	li	a5,4
    800023fa:	00f9ac23          	sw	a5,24(s3)
  movequeue(p, 0, MOVE);
    800023fe:	4601                	li	a2,0
    80002400:	4581                	li	a1,0
    80002402:	854e                	mv	a0,s3
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	532080e7          	jalr	1330(ra) # 80001936 <movequeue>
  release(&original_parent->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	8a2080e7          	jalr	-1886(ra) # 80000cb0 <release>
  sched();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	e2a080e7          	jalr	-470(ra) # 80002240 <sched>
  panic("zombie exit");
    8000241e:	00006517          	auipc	a0,0x6
    80002422:	e9a50513          	addi	a0,a0,-358 # 800082b8 <digits+0x278>
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	11a080e7          	jalr	282(ra) # 80000540 <panic>

000000008000242e <yield>:
{
    8000242e:	1101                	addi	sp,sp,-32
    80002430:	ec06                	sd	ra,24(sp)
    80002432:	e822                	sd	s0,16(sp)
    80002434:	e426                	sd	s1,8(sp)
    80002436:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	6f4080e7          	jalr	1780(ra) # 80001b2c <myproc>
    80002440:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	7ba080e7          	jalr	1978(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    8000244a:	4789                	li	a5,2
    8000244c:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    8000244e:	17c4a703          	lw	a4,380(s1)
    80002452:	02f70363          	beq	a4,a5,80002478 <yield+0x4a>
  else if(p->priority == 1)
    80002456:	4785                	li	a5,1
    80002458:	08f70663          	beq	a4,a5,800024e4 <yield+0xb6>
  sched();
    8000245c:	00000097          	auipc	ra,0x0
    80002460:	de4080e7          	jalr	-540(ra) # 80002240 <sched>
  release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	84a080e7          	jalr	-1974(ra) # 80000cb0 <release>
}
    8000246e:	60e2                	ld	ra,24(sp)
    80002470:	6442                	ld	s0,16(sp)
    80002472:	64a2                	ld	s1,8(sp)
    80002474:	6105                	addi	sp,sp,32
    80002476:	8082                	ret
    p->Qtime[2]++;
    80002478:	1704a783          	lw	a5,368(s1)
    8000247c:	2785                	addiw	a5,a5,1
    8000247e:	16f4a823          	sw	a5,368(s1)
    for(int i=0; i<tail; i++)
    80002482:	00007597          	auipc	a1,0x7
    80002486:	b9e5a583          	lw	a1,-1122(a1) # 80009020 <tail>
    8000248a:	04b05563          	blez	a1,800024d4 <yield+0xa6>
    8000248e:	00010797          	auipc	a5,0x10
    80002492:	eda78793          	addi	a5,a5,-294 # 80012368 <pid>
    80002496:	35fd                	addiw	a1,a1,-1
    80002498:	02059713          	slli	a4,a1,0x20
    8000249c:	01e75593          	srli	a1,a4,0x1e
    800024a0:	00010717          	auipc	a4,0x10
    800024a4:	ecc70713          	addi	a4,a4,-308 # 8001236c <pid+0x4>
    800024a8:	95ba                	add	a1,a1,a4
  int down = 1;
    800024aa:	4505                	li	a0,1
        down = 0;
    800024ac:	4801                	li	a6,0
    800024ae:	a031                	j	800024ba <yield+0x8c>
      pid[i] = 0;
    800024b0:	00072023          	sw	zero,0(a4)
    for(int i=0; i<tail; i++)
    800024b4:	0791                	addi	a5,a5,4
    800024b6:	00b78963          	beq	a5,a1,800024c8 <yield+0x9a>
      if(pid[i] != p->pid)
    800024ba:	873e                	mv	a4,a5
    800024bc:	4390                	lw	a2,0(a5)
    800024be:	5c94                	lw	a3,56(s1)
    800024c0:	fed608e3          	beq	a2,a3,800024b0 <yield+0x82>
        down = 0;
    800024c4:	8542                	mv	a0,a6
    800024c6:	b7ed                	j	800024b0 <yield+0x82>
    if (down)
    800024c8:	e511                	bnez	a0,800024d4 <yield+0xa6>
    tail = 0;     
    800024ca:	00007797          	auipc	a5,0x7
    800024ce:	b407ab23          	sw	zero,-1194(a5) # 80009020 <tail>
    800024d2:	b769                	j	8000245c <yield+0x2e>
      movequeue(p, 1, MOVE);
    800024d4:	4601                	li	a2,0
    800024d6:	4585                	li	a1,1
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	45c080e7          	jalr	1116(ra) # 80001936 <movequeue>
    800024e2:	b7e5                	j	800024ca <yield+0x9c>
    p->Qtime[1]++;
    800024e4:	16c4a783          	lw	a5,364(s1)
    800024e8:	2785                	addiw	a5,a5,1
    800024ea:	16f4a623          	sw	a5,364(s1)
    800024ee:	b7bd                	j	8000245c <yield+0x2e>

00000000800024f0 <sleep>:
{
    800024f0:	7179                	addi	sp,sp,-48
    800024f2:	f406                	sd	ra,40(sp)
    800024f4:	f022                	sd	s0,32(sp)
    800024f6:	ec26                	sd	s1,24(sp)
    800024f8:	e84a                	sd	s2,16(sp)
    800024fa:	e44e                	sd	s3,8(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	89aa                	mv	s3,a0
    80002500:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	62a080e7          	jalr	1578(ra) # 80001b2c <myproc>
    8000250a:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    8000250c:	05250d63          	beq	a0,s2,80002566 <sleep+0x76>
    acquire(&p->lock); //DOC: sleeplock1
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	6ec080e7          	jalr	1772(ra) # 80000bfc <acquire>
    release(lk);
    80002518:	854a                	mv	a0,s2
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	796080e7          	jalr	1942(ra) # 80000cb0 <release>
  p->chan = chan;
    80002522:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002526:	4785                	li	a5,1
    80002528:	cc9c                	sw	a5,24(s1)
  movequeue(p, 0, MOVE);
    8000252a:	4601                	li	a2,0
    8000252c:	4581                	li	a1,0
    8000252e:	8526                	mv	a0,s1
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	406080e7          	jalr	1030(ra) # 80001936 <movequeue>
  sched();
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	d08080e7          	jalr	-760(ra) # 80002240 <sched>
  p->chan = 0;
    80002540:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	76a080e7          	jalr	1898(ra) # 80000cb0 <release>
    acquire(lk);
    8000254e:	854a                	mv	a0,s2
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	6ac080e7          	jalr	1708(ra) # 80000bfc <acquire>
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
  p->chan = chan;
    80002566:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000256a:	4785                	li	a5,1
    8000256c:	cd1c                	sw	a5,24(a0)
  movequeue(p, 0, MOVE);
    8000256e:	4601                	li	a2,0
    80002570:	4581                	li	a1,0
    80002572:	fffff097          	auipc	ra,0xfffff
    80002576:	3c4080e7          	jalr	964(ra) # 80001936 <movequeue>
  sched();
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	cc6080e7          	jalr	-826(ra) # 80002240 <sched>
  p->chan = 0;
    80002582:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    80002586:	bfc9                	j	80002558 <sleep+0x68>

0000000080002588 <wait>:
{
    80002588:	715d                	addi	sp,sp,-80
    8000258a:	e486                	sd	ra,72(sp)
    8000258c:	e0a2                	sd	s0,64(sp)
    8000258e:	fc26                	sd	s1,56(sp)
    80002590:	f84a                	sd	s2,48(sp)
    80002592:	f44e                	sd	s3,40(sp)
    80002594:	f052                	sd	s4,32(sp)
    80002596:	ec56                	sd	s5,24(sp)
    80002598:	e85a                	sd	s6,16(sp)
    8000259a:	e45e                	sd	s7,8(sp)
    8000259c:	0880                	addi	s0,sp,80
    8000259e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	58c080e7          	jalr	1420(ra) # 80001b2c <myproc>
    800025a8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	652080e7          	jalr	1618(ra) # 80000bfc <acquire>
    havekids = 0;
    800025b2:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800025b4:	4a11                	li	s4,4
        havekids = 1;
    800025b6:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800025b8:	00016997          	auipc	s3,0x16
    800025bc:	eb098993          	addi	s3,s3,-336 # 80018468 <tickslock>
    havekids = 0;
    800025c0:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025c2:	00010497          	auipc	s1,0x10
    800025c6:	ea648493          	addi	s1,s1,-346 # 80012468 <proc>
    800025ca:	a08d                	j	8000262c <wait+0xa4>
          pid = np->pid;
    800025cc:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025d0:	000b0e63          	beqz	s6,800025ec <wait+0x64>
    800025d4:	4691                	li	a3,4
    800025d6:	03448613          	addi	a2,s1,52
    800025da:	85da                	mv	a1,s6
    800025dc:	05093503          	ld	a0,80(s2)
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	0ca080e7          	jalr	202(ra) # 800016aa <copyout>
    800025e8:	02054263          	bltz	a0,8000260c <wait+0x84>
          freeproc(np);
    800025ec:	8526                	mv	a0,s1
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	6f2080e7          	jalr	1778(ra) # 80001ce0 <freeproc>
          release(&np->lock);
    800025f6:	8526                	mv	a0,s1
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	6b8080e7          	jalr	1720(ra) # 80000cb0 <release>
          release(&p->lock);
    80002600:	854a                	mv	a0,s2
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	6ae080e7          	jalr	1710(ra) # 80000cb0 <release>
          return pid;
    8000260a:	a8a9                	j	80002664 <wait+0xdc>
            release(&np->lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	6a2080e7          	jalr	1698(ra) # 80000cb0 <release>
            release(&p->lock);
    80002616:	854a                	mv	a0,s2
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	698080e7          	jalr	1688(ra) # 80000cb0 <release>
            return -1;
    80002620:	59fd                	li	s3,-1
    80002622:	a089                	j	80002664 <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    80002624:	18048493          	addi	s1,s1,384
    80002628:	03348463          	beq	s1,s3,80002650 <wait+0xc8>
      if (np->parent == p)
    8000262c:	709c                	ld	a5,32(s1)
    8000262e:	ff279be3          	bne	a5,s2,80002624 <wait+0x9c>
        acquire(&np->lock);
    80002632:	8526                	mv	a0,s1
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	5c8080e7          	jalr	1480(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    8000263c:	4c9c                	lw	a5,24(s1)
    8000263e:	f94787e3          	beq	a5,s4,800025cc <wait+0x44>
        release(&np->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	66c080e7          	jalr	1644(ra) # 80000cb0 <release>
        havekids = 1;
    8000264c:	8756                	mv	a4,s5
    8000264e:	bfd9                	j	80002624 <wait+0x9c>
    if (!havekids || p->killed)
    80002650:	c701                	beqz	a4,80002658 <wait+0xd0>
    80002652:	03092783          	lw	a5,48(s2)
    80002656:	c39d                	beqz	a5,8000267c <wait+0xf4>
      release(&p->lock);
    80002658:	854a                	mv	a0,s2
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	656080e7          	jalr	1622(ra) # 80000cb0 <release>
      return -1;
    80002662:	59fd                	li	s3,-1
}
    80002664:	854e                	mv	a0,s3
    80002666:	60a6                	ld	ra,72(sp)
    80002668:	6406                	ld	s0,64(sp)
    8000266a:	74e2                	ld	s1,56(sp)
    8000266c:	7942                	ld	s2,48(sp)
    8000266e:	79a2                	ld	s3,40(sp)
    80002670:	7a02                	ld	s4,32(sp)
    80002672:	6ae2                	ld	s5,24(sp)
    80002674:	6b42                	ld	s6,16(sp)
    80002676:	6ba2                	ld	s7,8(sp)
    80002678:	6161                	addi	sp,sp,80
    8000267a:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    8000267c:	85ca                	mv	a1,s2
    8000267e:	854a                	mv	a0,s2
    80002680:	00000097          	auipc	ra,0x0
    80002684:	e70080e7          	jalr	-400(ra) # 800024f0 <sleep>
    havekids = 0;
    80002688:	bf25                	j	800025c0 <wait+0x38>

000000008000268a <wakeup>:
{
    8000268a:	7139                	addi	sp,sp,-64
    8000268c:	fc06                	sd	ra,56(sp)
    8000268e:	f822                	sd	s0,48(sp)
    80002690:	f426                	sd	s1,40(sp)
    80002692:	f04a                	sd	s2,32(sp)
    80002694:	ec4e                	sd	s3,24(sp)
    80002696:	e852                	sd	s4,16(sp)
    80002698:	e456                	sd	s5,8(sp)
    8000269a:	0080                	addi	s0,sp,64
    8000269c:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    8000269e:	00010497          	auipc	s1,0x10
    800026a2:	dca48493          	addi	s1,s1,-566 # 80012468 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800026a6:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026a8:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800026aa:	00016917          	auipc	s2,0x16
    800026ae:	dbe90913          	addi	s2,s2,-578 # 80018468 <tickslock>
    800026b2:	a811                	j	800026c6 <wakeup+0x3c>
    release(&p->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5fa080e7          	jalr	1530(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026be:	18048493          	addi	s1,s1,384
    800026c2:	03248763          	beq	s1,s2,800026f0 <wakeup+0x66>
    acquire(&p->lock);
    800026c6:	8526                	mv	a0,s1
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	534080e7          	jalr	1332(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800026d0:	4c9c                	lw	a5,24(s1)
    800026d2:	ff3791e3          	bne	a5,s3,800026b4 <wakeup+0x2a>
    800026d6:	749c                	ld	a5,40(s1)
    800026d8:	fd479ee3          	bne	a5,s4,800026b4 <wakeup+0x2a>
      p->state = RUNNABLE;
    800026dc:	0154ac23          	sw	s5,24(s1)
      movequeue(p, 2, MOVE);
    800026e0:	4601                	li	a2,0
    800026e2:	85d6                	mv	a1,s5
    800026e4:	8526                	mv	a0,s1
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	250080e7          	jalr	592(ra) # 80001936 <movequeue>
    800026ee:	b7d9                	j	800026b4 <wakeup+0x2a>
}
    800026f0:	70e2                	ld	ra,56(sp)
    800026f2:	7442                	ld	s0,48(sp)
    800026f4:	74a2                	ld	s1,40(sp)
    800026f6:	7902                	ld	s2,32(sp)
    800026f8:	69e2                	ld	s3,24(sp)
    800026fa:	6a42                	ld	s4,16(sp)
    800026fc:	6aa2                	ld	s5,8(sp)
    800026fe:	6121                	addi	sp,sp,64
    80002700:	8082                	ret

0000000080002702 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002702:	7179                	addi	sp,sp,-48
    80002704:	f406                	sd	ra,40(sp)
    80002706:	f022                	sd	s0,32(sp)
    80002708:	ec26                	sd	s1,24(sp)
    8000270a:	e84a                	sd	s2,16(sp)
    8000270c:	e44e                	sd	s3,8(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002712:	00010497          	auipc	s1,0x10
    80002716:	d5648493          	addi	s1,s1,-682 # 80012468 <proc>
    8000271a:	00016997          	auipc	s3,0x16
    8000271e:	d4e98993          	addi	s3,s3,-690 # 80018468 <tickslock>
  {
    acquire(&p->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4d8080e7          	jalr	1240(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    8000272c:	5c9c                	lw	a5,56(s1)
    8000272e:	01278d63          	beq	a5,s2,80002748 <kill+0x46>
        movequeue(p, 2, MOVE);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	57c080e7          	jalr	1404(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000273c:	18048493          	addi	s1,s1,384
    80002740:	ff3491e3          	bne	s1,s3,80002722 <kill+0x20>
  }
  return -1;
    80002744:	557d                	li	a0,-1
    80002746:	a821                	j	8000275e <kill+0x5c>
      p->killed = 1;
    80002748:	4785                	li	a5,1
    8000274a:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    8000274c:	4c98                	lw	a4,24(s1)
    8000274e:	00f70f63          	beq	a4,a5,8000276c <kill+0x6a>
      release(&p->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	55c080e7          	jalr	1372(ra) # 80000cb0 <release>
      return 0;
    8000275c:	4501                	li	a0,0
}
    8000275e:	70a2                	ld	ra,40(sp)
    80002760:	7402                	ld	s0,32(sp)
    80002762:	64e2                	ld	s1,24(sp)
    80002764:	6942                	ld	s2,16(sp)
    80002766:	69a2                	ld	s3,8(sp)
    80002768:	6145                	addi	sp,sp,48
    8000276a:	8082                	ret
        p->state = RUNNABLE;
    8000276c:	4789                	li	a5,2
    8000276e:	cc9c                	sw	a5,24(s1)
        movequeue(p, 2, MOVE);
    80002770:	4601                	li	a2,0
    80002772:	4589                	li	a1,2
    80002774:	8526                	mv	a0,s1
    80002776:	fffff097          	auipc	ra,0xfffff
    8000277a:	1c0080e7          	jalr	448(ra) # 80001936 <movequeue>
    8000277e:	bfd1                	j	80002752 <kill+0x50>

0000000080002780 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002780:	7179                	addi	sp,sp,-48
    80002782:	f406                	sd	ra,40(sp)
    80002784:	f022                	sd	s0,32(sp)
    80002786:	ec26                	sd	s1,24(sp)
    80002788:	e84a                	sd	s2,16(sp)
    8000278a:	e44e                	sd	s3,8(sp)
    8000278c:	e052                	sd	s4,0(sp)
    8000278e:	1800                	addi	s0,sp,48
    80002790:	84aa                	mv	s1,a0
    80002792:	892e                	mv	s2,a1
    80002794:	89b2                	mv	s3,a2
    80002796:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002798:	fffff097          	auipc	ra,0xfffff
    8000279c:	394080e7          	jalr	916(ra) # 80001b2c <myproc>
  if (user_dst)
    800027a0:	c08d                	beqz	s1,800027c2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027a2:	86d2                	mv	a3,s4
    800027a4:	864e                	mv	a2,s3
    800027a6:	85ca                	mv	a1,s2
    800027a8:	6928                	ld	a0,80(a0)
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	f00080e7          	jalr	-256(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027b2:	70a2                	ld	ra,40(sp)
    800027b4:	7402                	ld	s0,32(sp)
    800027b6:	64e2                	ld	s1,24(sp)
    800027b8:	6942                	ld	s2,16(sp)
    800027ba:	69a2                	ld	s3,8(sp)
    800027bc:	6a02                	ld	s4,0(sp)
    800027be:	6145                	addi	sp,sp,48
    800027c0:	8082                	ret
    memmove((char *)dst, src, len);
    800027c2:	000a061b          	sext.w	a2,s4
    800027c6:	85ce                	mv	a1,s3
    800027c8:	854a                	mv	a0,s2
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	58a080e7          	jalr	1418(ra) # 80000d54 <memmove>
    return 0;
    800027d2:	8526                	mv	a0,s1
    800027d4:	bff9                	j	800027b2 <either_copyout+0x32>

00000000800027d6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027d6:	7179                	addi	sp,sp,-48
    800027d8:	f406                	sd	ra,40(sp)
    800027da:	f022                	sd	s0,32(sp)
    800027dc:	ec26                	sd	s1,24(sp)
    800027de:	e84a                	sd	s2,16(sp)
    800027e0:	e44e                	sd	s3,8(sp)
    800027e2:	e052                	sd	s4,0(sp)
    800027e4:	1800                	addi	s0,sp,48
    800027e6:	892a                	mv	s2,a0
    800027e8:	84ae                	mv	s1,a1
    800027ea:	89b2                	mv	s3,a2
    800027ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ee:	fffff097          	auipc	ra,0xfffff
    800027f2:	33e080e7          	jalr	830(ra) # 80001b2c <myproc>
  if (user_src)
    800027f6:	c08d                	beqz	s1,80002818 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027f8:	86d2                	mv	a3,s4
    800027fa:	864e                	mv	a2,s3
    800027fc:	85ca                	mv	a1,s2
    800027fe:	6928                	ld	a0,80(a0)
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	f36080e7          	jalr	-202(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002808:	70a2                	ld	ra,40(sp)
    8000280a:	7402                	ld	s0,32(sp)
    8000280c:	64e2                	ld	s1,24(sp)
    8000280e:	6942                	ld	s2,16(sp)
    80002810:	69a2                	ld	s3,8(sp)
    80002812:	6a02                	ld	s4,0(sp)
    80002814:	6145                	addi	sp,sp,48
    80002816:	8082                	ret
    memmove(dst, (char *)src, len);
    80002818:	000a061b          	sext.w	a2,s4
    8000281c:	85ce                	mv	a1,s3
    8000281e:	854a                	mv	a0,s2
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	534080e7          	jalr	1332(ra) # 80000d54 <memmove>
    return 0;
    80002828:	8526                	mv	a0,s1
    8000282a:	bff9                	j	80002808 <either_copyin+0x32>

000000008000282c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000282c:	715d                	addi	sp,sp,-80
    8000282e:	e486                	sd	ra,72(sp)
    80002830:	e0a2                	sd	s0,64(sp)
    80002832:	fc26                	sd	s1,56(sp)
    80002834:	f84a                	sd	s2,48(sp)
    80002836:	f44e                	sd	s3,40(sp)
    80002838:	f052                	sd	s4,32(sp)
    8000283a:	ec56                	sd	s5,24(sp)
    8000283c:	e85a                	sd	s6,16(sp)
    8000283e:	e45e                	sd	s7,8(sp)
    80002840:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002842:	00006517          	auipc	a0,0x6
    80002846:	9ae50513          	addi	a0,a0,-1618 # 800081f0 <digits+0x1b0>
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	d40080e7          	jalr	-704(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002852:	00010497          	auipc	s1,0x10
    80002856:	d6e48493          	addi	s1,s1,-658 # 800125c0 <proc+0x158>
    8000285a:	00016917          	auipc	s2,0x16
    8000285e:	d6690913          	addi	s2,s2,-666 # 800185c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002862:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002864:	00006997          	auipc	s3,0x6
    80002868:	a6498993          	addi	s3,s3,-1436 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    8000286c:	00006a97          	auipc	s5,0x6
    80002870:	a64a8a93          	addi	s5,s5,-1436 # 800082d0 <digits+0x290>
    printf("\n");
    80002874:	00006a17          	auipc	s4,0x6
    80002878:	97ca0a13          	addi	s4,s4,-1668 # 800081f0 <digits+0x1b0>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287c:	00006b97          	auipc	s7,0x6
    80002880:	a8cb8b93          	addi	s7,s7,-1396 # 80008308 <states.0>
    80002884:	a00d                	j	800028a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002886:	ee06a583          	lw	a1,-288(a3)
    8000288a:	8556                	mv	a0,s5
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	cfe080e7          	jalr	-770(ra) # 8000058a <printf>
    printf("\n");
    80002894:	8552                	mv	a0,s4
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	cf4080e7          	jalr	-780(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000289e:	18048493          	addi	s1,s1,384
    800028a2:	03248263          	beq	s1,s2,800028c6 <procdump+0x9a>
    if (p->state == UNUSED)
    800028a6:	86a6                	mv	a3,s1
    800028a8:	ec04a783          	lw	a5,-320(s1)
    800028ac:	dbed                	beqz	a5,8000289e <procdump+0x72>
      state = "???";
    800028ae:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b0:	fcfb6be3          	bltu	s6,a5,80002886 <procdump+0x5a>
    800028b4:	02079713          	slli	a4,a5,0x20
    800028b8:	01d75793          	srli	a5,a4,0x1d
    800028bc:	97de                	add	a5,a5,s7
    800028be:	6390                	ld	a2,0(a5)
    800028c0:	f279                	bnez	a2,80002886 <procdump+0x5a>
      state = "???";
    800028c2:	864e                	mv	a2,s3
    800028c4:	b7c9                	j	80002886 <procdump+0x5a>
  }
}
    800028c6:	60a6                	ld	ra,72(sp)
    800028c8:	6406                	ld	s0,64(sp)
    800028ca:	74e2                	ld	s1,56(sp)
    800028cc:	7942                	ld	s2,48(sp)
    800028ce:	79a2                	ld	s3,40(sp)
    800028d0:	7a02                	ld	s4,32(sp)
    800028d2:	6ae2                	ld	s5,24(sp)
    800028d4:	6b42                	ld	s6,16(sp)
    800028d6:	6ba2                	ld	s7,8(sp)
    800028d8:	6161                	addi	sp,sp,80
    800028da:	8082                	ret

00000000800028dc <swtch>:
    800028dc:	00153023          	sd	ra,0(a0)
    800028e0:	00253423          	sd	sp,8(a0)
    800028e4:	e900                	sd	s0,16(a0)
    800028e6:	ed04                	sd	s1,24(a0)
    800028e8:	03253023          	sd	s2,32(a0)
    800028ec:	03353423          	sd	s3,40(a0)
    800028f0:	03453823          	sd	s4,48(a0)
    800028f4:	03553c23          	sd	s5,56(a0)
    800028f8:	05653023          	sd	s6,64(a0)
    800028fc:	05753423          	sd	s7,72(a0)
    80002900:	05853823          	sd	s8,80(a0)
    80002904:	05953c23          	sd	s9,88(a0)
    80002908:	07a53023          	sd	s10,96(a0)
    8000290c:	07b53423          	sd	s11,104(a0)
    80002910:	0005b083          	ld	ra,0(a1)
    80002914:	0085b103          	ld	sp,8(a1)
    80002918:	6980                	ld	s0,16(a1)
    8000291a:	6d84                	ld	s1,24(a1)
    8000291c:	0205b903          	ld	s2,32(a1)
    80002920:	0285b983          	ld	s3,40(a1)
    80002924:	0305ba03          	ld	s4,48(a1)
    80002928:	0385ba83          	ld	s5,56(a1)
    8000292c:	0405bb03          	ld	s6,64(a1)
    80002930:	0485bb83          	ld	s7,72(a1)
    80002934:	0505bc03          	ld	s8,80(a1)
    80002938:	0585bc83          	ld	s9,88(a1)
    8000293c:	0605bd03          	ld	s10,96(a1)
    80002940:	0685bd83          	ld	s11,104(a1)
    80002944:	8082                	ret

0000000080002946 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002946:	1141                	addi	sp,sp,-16
    80002948:	e406                	sd	ra,8(sp)
    8000294a:	e022                	sd	s0,0(sp)
    8000294c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000294e:	00006597          	auipc	a1,0x6
    80002952:	9e258593          	addi	a1,a1,-1566 # 80008330 <states.0+0x28>
    80002956:	00016517          	auipc	a0,0x16
    8000295a:	b1250513          	addi	a0,a0,-1262 # 80018468 <tickslock>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	20e080e7          	jalr	526(ra) # 80000b6c <initlock>
}
    80002966:	60a2                	ld	ra,8(sp)
    80002968:	6402                	ld	s0,0(sp)
    8000296a:	0141                	addi	sp,sp,16
    8000296c:	8082                	ret

000000008000296e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000296e:	1141                	addi	sp,sp,-16
    80002970:	e422                	sd	s0,8(sp)
    80002972:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002974:	00003797          	auipc	a5,0x3
    80002978:	4fc78793          	addi	a5,a5,1276 # 80005e70 <kernelvec>
    8000297c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002980:	6422                	ld	s0,8(sp)
    80002982:	0141                	addi	sp,sp,16
    80002984:	8082                	ret

0000000080002986 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002986:	1141                	addi	sp,sp,-16
    80002988:	e406                	sd	ra,8(sp)
    8000298a:	e022                	sd	s0,0(sp)
    8000298c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	19e080e7          	jalr	414(ra) # 80001b2c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000299a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029a0:	00004617          	auipc	a2,0x4
    800029a4:	66060613          	addi	a2,a2,1632 # 80007000 <_trampoline>
    800029a8:	00004697          	auipc	a3,0x4
    800029ac:	65868693          	addi	a3,a3,1624 # 80007000 <_trampoline>
    800029b0:	8e91                	sub	a3,a3,a2
    800029b2:	040007b7          	lui	a5,0x4000
    800029b6:	17fd                	addi	a5,a5,-1
    800029b8:	07b2                	slli	a5,a5,0xc
    800029ba:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029bc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029c0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029c2:	180026f3          	csrr	a3,satp
    800029c6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029c8:	6d38                	ld	a4,88(a0)
    800029ca:	6134                	ld	a3,64(a0)
    800029cc:	6585                	lui	a1,0x1
    800029ce:	96ae                	add	a3,a3,a1
    800029d0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029d2:	6d38                	ld	a4,88(a0)
    800029d4:	00000697          	auipc	a3,0x0
    800029d8:	13868693          	addi	a3,a3,312 # 80002b0c <usertrap>
    800029dc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029de:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029e0:	8692                	mv	a3,tp
    800029e2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029e8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ec:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029f0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f6:	6f18                	ld	a4,24(a4)
    800029f8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029fc:	692c                	ld	a1,80(a0)
    800029fe:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a00:	00004717          	auipc	a4,0x4
    80002a04:	69070713          	addi	a4,a4,1680 # 80007090 <userret>
    80002a08:	8f11                	sub	a4,a4,a2
    80002a0a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a0c:	577d                	li	a4,-1
    80002a0e:	177e                	slli	a4,a4,0x3f
    80002a10:	8dd9                	or	a1,a1,a4
    80002a12:	02000537          	lui	a0,0x2000
    80002a16:	157d                	addi	a0,a0,-1
    80002a18:	0536                	slli	a0,a0,0xd
    80002a1a:	9782                	jalr	a5
}
    80002a1c:	60a2                	ld	ra,8(sp)
    80002a1e:	6402                	ld	s0,0(sp)
    80002a20:	0141                	addi	sp,sp,16
    80002a22:	8082                	ret

0000000080002a24 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a24:	1101                	addi	sp,sp,-32
    80002a26:	ec06                	sd	ra,24(sp)
    80002a28:	e822                	sd	s0,16(sp)
    80002a2a:	e426                	sd	s1,8(sp)
    80002a2c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a2e:	00016497          	auipc	s1,0x16
    80002a32:	a3a48493          	addi	s1,s1,-1478 # 80018468 <tickslock>
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	1c4080e7          	jalr	452(ra) # 80000bfc <acquire>
  ticks++;
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	5e450513          	addi	a0,a0,1508 # 80009024 <ticks>
    80002a48:	411c                	lw	a5,0(a0)
    80002a4a:	2785                	addiw	a5,a5,1
    80002a4c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	c3c080e7          	jalr	-964(ra) # 8000268a <wakeup>
  release(&tickslock);
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	258080e7          	jalr	600(ra) # 80000cb0 <release>
}
    80002a60:	60e2                	ld	ra,24(sp)
    80002a62:	6442                	ld	s0,16(sp)
    80002a64:	64a2                	ld	s1,8(sp)
    80002a66:	6105                	addi	sp,sp,32
    80002a68:	8082                	ret

0000000080002a6a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a6a:	1101                	addi	sp,sp,-32
    80002a6c:	ec06                	sd	ra,24(sp)
    80002a6e:	e822                	sd	s0,16(sp)
    80002a70:	e426                	sd	s1,8(sp)
    80002a72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a78:	00074d63          	bltz	a4,80002a92 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a7c:	57fd                	li	a5,-1
    80002a7e:	17fe                	slli	a5,a5,0x3f
    80002a80:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a82:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a84:	06f70363          	beq	a4,a5,80002aea <devintr+0x80>
  }
}
    80002a88:	60e2                	ld	ra,24(sp)
    80002a8a:	6442                	ld	s0,16(sp)
    80002a8c:	64a2                	ld	s1,8(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret
     (scause & 0xff) == 9){
    80002a92:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a96:	46a5                	li	a3,9
    80002a98:	fed792e3          	bne	a5,a3,80002a7c <devintr+0x12>
    int irq = plic_claim();
    80002a9c:	00003097          	auipc	ra,0x3
    80002aa0:	4dc080e7          	jalr	1244(ra) # 80005f78 <plic_claim>
    80002aa4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002aa6:	47a9                	li	a5,10
    80002aa8:	02f50763          	beq	a0,a5,80002ad6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aac:	4785                	li	a5,1
    80002aae:	02f50963          	beq	a0,a5,80002ae0 <devintr+0x76>
    return 1;
    80002ab2:	4505                	li	a0,1
    } else if(irq){
    80002ab4:	d8f1                	beqz	s1,80002a88 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ab6:	85a6                	mv	a1,s1
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	88050513          	addi	a0,a0,-1920 # 80008338 <states.0+0x30>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	aca080e7          	jalr	-1334(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ac8:	8526                	mv	a0,s1
    80002aca:	00003097          	auipc	ra,0x3
    80002ace:	4d2080e7          	jalr	1234(ra) # 80005f9c <plic_complete>
    return 1;
    80002ad2:	4505                	li	a0,1
    80002ad4:	bf55                	j	80002a88 <devintr+0x1e>
      uartintr();
    80002ad6:	ffffe097          	auipc	ra,0xffffe
    80002ada:	eea080e7          	jalr	-278(ra) # 800009c0 <uartintr>
    80002ade:	b7ed                	j	80002ac8 <devintr+0x5e>
      virtio_disk_intr();
    80002ae0:	00004097          	auipc	ra,0x4
    80002ae4:	936080e7          	jalr	-1738(ra) # 80006416 <virtio_disk_intr>
    80002ae8:	b7c5                	j	80002ac8 <devintr+0x5e>
    if(cpuid() == 0){
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	016080e7          	jalr	22(ra) # 80001b00 <cpuid>
    80002af2:	c901                	beqz	a0,80002b02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002af4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002af8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002afa:	14479073          	csrw	sip,a5
    return 2;
    80002afe:	4509                	li	a0,2
    80002b00:	b761                	j	80002a88 <devintr+0x1e>
      clockintr();
    80002b02:	00000097          	auipc	ra,0x0
    80002b06:	f22080e7          	jalr	-222(ra) # 80002a24 <clockintr>
    80002b0a:	b7ed                	j	80002af4 <devintr+0x8a>

0000000080002b0c <usertrap>:
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	e04a                	sd	s2,0(sp)
    80002b16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b1c:	1007f793          	andi	a5,a5,256
    80002b20:	e3ad                	bnez	a5,80002b82 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b22:	00003797          	auipc	a5,0x3
    80002b26:	34e78793          	addi	a5,a5,846 # 80005e70 <kernelvec>
    80002b2a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	ffe080e7          	jalr	-2(ra) # 80001b2c <myproc>
    80002b36:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b38:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3a:	14102773          	csrr	a4,sepc
    80002b3e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b40:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b44:	47a1                	li	a5,8
    80002b46:	04f71c63          	bne	a4,a5,80002b9e <usertrap+0x92>
    if(p->killed)
    80002b4a:	591c                	lw	a5,48(a0)
    80002b4c:	e3b9                	bnez	a5,80002b92 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b4e:	6cb8                	ld	a4,88(s1)
    80002b50:	6f1c                	ld	a5,24(a4)
    80002b52:	0791                	addi	a5,a5,4
    80002b54:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	2f8080e7          	jalr	760(ra) # 80002e5a <syscall>
  if(p->killed)
    80002b6a:	589c                	lw	a5,48(s1)
    80002b6c:	ebc1                	bnez	a5,80002bfc <usertrap+0xf0>
  usertrapret();
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	e18080e7          	jalr	-488(ra) # 80002986 <usertrapret>
}
    80002b76:	60e2                	ld	ra,24(sp)
    80002b78:	6442                	ld	s0,16(sp)
    80002b7a:	64a2                	ld	s1,8(sp)
    80002b7c:	6902                	ld	s2,0(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret
    panic("usertrap: not from user mode");
    80002b82:	00005517          	auipc	a0,0x5
    80002b86:	7d650513          	addi	a0,a0,2006 # 80008358 <states.0+0x50>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9b6080e7          	jalr	-1610(ra) # 80000540 <panic>
      exit(-1);
    80002b92:	557d                	li	a0,-1
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	782080e7          	jalr	1922(ra) # 80002316 <exit>
    80002b9c:	bf4d                	j	80002b4e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	ecc080e7          	jalr	-308(ra) # 80002a6a <devintr>
    80002ba6:	892a                	mv	s2,a0
    80002ba8:	c501                	beqz	a0,80002bb0 <usertrap+0xa4>
  if(p->killed)
    80002baa:	589c                	lw	a5,48(s1)
    80002bac:	c3a1                	beqz	a5,80002bec <usertrap+0xe0>
    80002bae:	a815                	j	80002be2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bb4:	5c90                	lw	a2,56(s1)
    80002bb6:	00005517          	auipc	a0,0x5
    80002bba:	7c250513          	addi	a0,a0,1986 # 80008378 <states.0+0x70>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	9cc080e7          	jalr	-1588(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bca:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bce:	00005517          	auipc	a0,0x5
    80002bd2:	7da50513          	addi	a0,a0,2010 # 800083a8 <states.0+0xa0>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9b4080e7          	jalr	-1612(ra) # 8000058a <printf>
    p->killed = 1;
    80002bde:	4785                	li	a5,1
    80002be0:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002be2:	557d                	li	a0,-1
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	732080e7          	jalr	1842(ra) # 80002316 <exit>
  if(which_dev == 2)
    80002bec:	4789                	li	a5,2
    80002bee:	f8f910e3          	bne	s2,a5,80002b6e <usertrap+0x62>
    yield();
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	83c080e7          	jalr	-1988(ra) # 8000242e <yield>
    80002bfa:	bf95                	j	80002b6e <usertrap+0x62>
  int which_dev = 0;
    80002bfc:	4901                	li	s2,0
    80002bfe:	b7d5                	j	80002be2 <usertrap+0xd6>

0000000080002c00 <kerneltrap>:
{
    80002c00:	7179                	addi	sp,sp,-48
    80002c02:	f406                	sd	ra,40(sp)
    80002c04:	f022                	sd	s0,32(sp)
    80002c06:	ec26                	sd	s1,24(sp)
    80002c08:	e84a                	sd	s2,16(sp)
    80002c0a:	e44e                	sd	s3,8(sp)
    80002c0c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c0e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c12:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c16:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c1a:	1004f793          	andi	a5,s1,256
    80002c1e:	cb85                	beqz	a5,80002c4e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c20:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c24:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c26:	ef85                	bnez	a5,80002c5e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	e42080e7          	jalr	-446(ra) # 80002a6a <devintr>
    80002c30:	cd1d                	beqz	a0,80002c6e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c32:	4789                	li	a5,2
    80002c34:	08f50663          	beq	a0,a5,80002cc0 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c38:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c3c:	10049073          	csrw	sstatus,s1
}
    80002c40:	70a2                	ld	ra,40(sp)
    80002c42:	7402                	ld	s0,32(sp)
    80002c44:	64e2                	ld	s1,24(sp)
    80002c46:	6942                	ld	s2,16(sp)
    80002c48:	69a2                	ld	s3,8(sp)
    80002c4a:	6145                	addi	sp,sp,48
    80002c4c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	77a50513          	addi	a0,a0,1914 # 800083c8 <states.0+0xc0>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	8ea080e7          	jalr	-1814(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	79250513          	addi	a0,a0,1938 # 800083f0 <states.0+0xe8>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	8da080e7          	jalr	-1830(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c6e:	00006597          	auipc	a1,0x6
    80002c72:	3b65a583          	lw	a1,950(a1) # 80009024 <ticks>
    80002c76:	00005517          	auipc	a0,0x5
    80002c7a:	7f250513          	addi	a0,a0,2034 # 80008468 <states.0+0x160>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	90c080e7          	jalr	-1780(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002c86:	85ce                	mv	a1,s3
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	78850513          	addi	a0,a0,1928 # 80008410 <states.0+0x108>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8fa080e7          	jalr	-1798(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c9c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca0:	00005517          	auipc	a0,0x5
    80002ca4:	78050513          	addi	a0,a0,1920 # 80008420 <states.0+0x118>
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	8e2080e7          	jalr	-1822(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cb0:	00005517          	auipc	a0,0x5
    80002cb4:	78850513          	addi	a0,a0,1928 # 80008438 <states.0+0x130>
    80002cb8:	ffffe097          	auipc	ra,0xffffe
    80002cbc:	888080e7          	jalr	-1912(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	e6c080e7          	jalr	-404(ra) # 80001b2c <myproc>
    80002cc8:	d925                	beqz	a0,80002c38 <kerneltrap+0x38>
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	e62080e7          	jalr	-414(ra) # 80001b2c <myproc>
    80002cd2:	4d18                	lw	a4,24(a0)
    80002cd4:	478d                	li	a5,3
    80002cd6:	f6f711e3          	bne	a4,a5,80002c38 <kerneltrap+0x38>
    yield();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	754080e7          	jalr	1876(ra) # 8000242e <yield>
    80002ce2:	bf99                	j	80002c38 <kerneltrap+0x38>

0000000080002ce4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce4:	1101                	addi	sp,sp,-32
    80002ce6:	ec06                	sd	ra,24(sp)
    80002ce8:	e822                	sd	s0,16(sp)
    80002cea:	e426                	sd	s1,8(sp)
    80002cec:	1000                	addi	s0,sp,32
    80002cee:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	e3c080e7          	jalr	-452(ra) # 80001b2c <myproc>
  switch (n)
    80002cf8:	4795                	li	a5,5
    80002cfa:	0497e163          	bltu	a5,s1,80002d3c <argraw+0x58>
    80002cfe:	048a                	slli	s1,s1,0x2
    80002d00:	00005717          	auipc	a4,0x5
    80002d04:	77070713          	addi	a4,a4,1904 # 80008470 <states.0+0x168>
    80002d08:	94ba                	add	s1,s1,a4
    80002d0a:	409c                	lw	a5,0(s1)
    80002d0c:	97ba                	add	a5,a5,a4
    80002d0e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d10:	6d3c                	ld	a5,88(a0)
    80002d12:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	64a2                	ld	s1,8(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret
    return p->trapframe->a1;
    80002d1e:	6d3c                	ld	a5,88(a0)
    80002d20:	7fa8                	ld	a0,120(a5)
    80002d22:	bfcd                	j	80002d14 <argraw+0x30>
    return p->trapframe->a2;
    80002d24:	6d3c                	ld	a5,88(a0)
    80002d26:	63c8                	ld	a0,128(a5)
    80002d28:	b7f5                	j	80002d14 <argraw+0x30>
    return p->trapframe->a3;
    80002d2a:	6d3c                	ld	a5,88(a0)
    80002d2c:	67c8                	ld	a0,136(a5)
    80002d2e:	b7dd                	j	80002d14 <argraw+0x30>
    return p->trapframe->a4;
    80002d30:	6d3c                	ld	a5,88(a0)
    80002d32:	6bc8                	ld	a0,144(a5)
    80002d34:	b7c5                	j	80002d14 <argraw+0x30>
    return p->trapframe->a5;
    80002d36:	6d3c                	ld	a5,88(a0)
    80002d38:	6fc8                	ld	a0,152(a5)
    80002d3a:	bfe9                	j	80002d14 <argraw+0x30>
  panic("argraw");
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	70c50513          	addi	a0,a0,1804 # 80008448 <states.0+0x140>
    80002d44:	ffffd097          	auipc	ra,0xffffd
    80002d48:	7fc080e7          	jalr	2044(ra) # 80000540 <panic>

0000000080002d4c <fetchaddr>:
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	e426                	sd	s1,8(sp)
    80002d54:	e04a                	sd	s2,0(sp)
    80002d56:	1000                	addi	s0,sp,32
    80002d58:	84aa                	mv	s1,a0
    80002d5a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	dd0080e7          	jalr	-560(ra) # 80001b2c <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d64:	653c                	ld	a5,72(a0)
    80002d66:	02f4f863          	bgeu	s1,a5,80002d96 <fetchaddr+0x4a>
    80002d6a:	00848713          	addi	a4,s1,8
    80002d6e:	02e7e663          	bltu	a5,a4,80002d9a <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d72:	46a1                	li	a3,8
    80002d74:	8626                	mv	a2,s1
    80002d76:	85ca                	mv	a1,s2
    80002d78:	6928                	ld	a0,80(a0)
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	9bc080e7          	jalr	-1604(ra) # 80001736 <copyin>
    80002d82:	00a03533          	snez	a0,a0
    80002d86:	40a00533          	neg	a0,a0
}
    80002d8a:	60e2                	ld	ra,24(sp)
    80002d8c:	6442                	ld	s0,16(sp)
    80002d8e:	64a2                	ld	s1,8(sp)
    80002d90:	6902                	ld	s2,0(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret
    return -1;
    80002d96:	557d                	li	a0,-1
    80002d98:	bfcd                	j	80002d8a <fetchaddr+0x3e>
    80002d9a:	557d                	li	a0,-1
    80002d9c:	b7fd                	j	80002d8a <fetchaddr+0x3e>

0000000080002d9e <fetchstr>:
{
    80002d9e:	7179                	addi	sp,sp,-48
    80002da0:	f406                	sd	ra,40(sp)
    80002da2:	f022                	sd	s0,32(sp)
    80002da4:	ec26                	sd	s1,24(sp)
    80002da6:	e84a                	sd	s2,16(sp)
    80002da8:	e44e                	sd	s3,8(sp)
    80002daa:	1800                	addi	s0,sp,48
    80002dac:	892a                	mv	s2,a0
    80002dae:	84ae                	mv	s1,a1
    80002db0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	d7a080e7          	jalr	-646(ra) # 80001b2c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dba:	86ce                	mv	a3,s3
    80002dbc:	864a                	mv	a2,s2
    80002dbe:	85a6                	mv	a1,s1
    80002dc0:	6928                	ld	a0,80(a0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	a02080e7          	jalr	-1534(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002dca:	00054763          	bltz	a0,80002dd8 <fetchstr+0x3a>
  return strlen(buf);
    80002dce:	8526                	mv	a0,s1
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	0ac080e7          	jalr	172(ra) # 80000e7c <strlen>
}
    80002dd8:	70a2                	ld	ra,40(sp)
    80002dda:	7402                	ld	s0,32(sp)
    80002ddc:	64e2                	ld	s1,24(sp)
    80002dde:	6942                	ld	s2,16(sp)
    80002de0:	69a2                	ld	s3,8(sp)
    80002de2:	6145                	addi	sp,sp,48
    80002de4:	8082                	ret

0000000080002de6 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	1000                	addi	s0,sp,32
    80002df0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	ef2080e7          	jalr	-270(ra) # 80002ce4 <argraw>
    80002dfa:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dfc:	4501                	li	a0,0
    80002dfe:	60e2                	ld	ra,24(sp)
    80002e00:	6442                	ld	s0,16(sp)
    80002e02:	64a2                	ld	s1,8(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	e426                	sd	s1,8(sp)
    80002e10:	1000                	addi	s0,sp,32
    80002e12:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	ed0080e7          	jalr	-304(ra) # 80002ce4 <argraw>
    80002e1c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e1e:	4501                	li	a0,0
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	64a2                	ld	s1,8(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e2a:	1101                	addi	sp,sp,-32
    80002e2c:	ec06                	sd	ra,24(sp)
    80002e2e:	e822                	sd	s0,16(sp)
    80002e30:	e426                	sd	s1,8(sp)
    80002e32:	e04a                	sd	s2,0(sp)
    80002e34:	1000                	addi	s0,sp,32
    80002e36:	84ae                	mv	s1,a1
    80002e38:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	eaa080e7          	jalr	-342(ra) # 80002ce4 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e42:	864a                	mv	a2,s2
    80002e44:	85a6                	mv	a1,s1
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	f58080e7          	jalr	-168(ra) # 80002d9e <fetchstr>
}
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	64a2                	ld	s1,8(sp)
    80002e54:	6902                	ld	s2,0(sp)
    80002e56:	6105                	addi	sp,sp,32
    80002e58:	8082                	ret

0000000080002e5a <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e5a:	1101                	addi	sp,sp,-32
    80002e5c:	ec06                	sd	ra,24(sp)
    80002e5e:	e822                	sd	s0,16(sp)
    80002e60:	e426                	sd	s1,8(sp)
    80002e62:	e04a                	sd	s2,0(sp)
    80002e64:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	cc6080e7          	jalr	-826(ra) # 80001b2c <myproc>
    80002e6e:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  if (p->priority != 2) 
    80002e70:	17c52703          	lw	a4,380(a0)
    80002e74:	4789                	li	a5,2
    80002e76:	02f71963          	bne	a4,a5,80002ea8 <syscall+0x4e>
    acquire(&p->lock);
    movequeue(p, 2, 0);
    release(&p->lock);
  }

  num = p->trapframe->a7;
    80002e7a:	0584b903          	ld	s2,88(s1)
    80002e7e:	0a893783          	ld	a5,168(s2)
    80002e82:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e86:	37fd                	addiw	a5,a5,-1
    80002e88:	4751                	li	a4,20
    80002e8a:	04f76063          	bltu	a4,a5,80002eca <syscall+0x70>
    80002e8e:	00369713          	slli	a4,a3,0x3
    80002e92:	00005797          	auipc	a5,0x5
    80002e96:	5f678793          	addi	a5,a5,1526 # 80008488 <syscalls>
    80002e9a:	97ba                	add	a5,a5,a4
    80002e9c:	639c                	ld	a5,0(a5)
    80002e9e:	c795                	beqz	a5,80002eca <syscall+0x70>
  {
    p->trapframe->a0 = syscalls[num]();
    80002ea0:	9782                	jalr	a5
    80002ea2:	06a93823          	sd	a0,112(s2)
    80002ea6:	a081                	j	80002ee6 <syscall+0x8c>
    acquire(&p->lock);
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	d54080e7          	jalr	-684(ra) # 80000bfc <acquire>
    movequeue(p, 2, 0);
    80002eb0:	4601                	li	a2,0
    80002eb2:	4589                	li	a1,2
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	a80080e7          	jalr	-1408(ra) # 80001936 <movequeue>
    release(&p->lock);
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	df0080e7          	jalr	-528(ra) # 80000cb0 <release>
    80002ec8:	bf4d                	j	80002e7a <syscall+0x20>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002eca:	15848613          	addi	a2,s1,344
    80002ece:	5c8c                	lw	a1,56(s1)
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	58050513          	addi	a0,a0,1408 # 80008450 <states.0+0x148>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	6b2080e7          	jalr	1714(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee0:	6cbc                	ld	a5,88(s1)
    80002ee2:	577d                	li	a4,-1
    80002ee4:	fbb8                	sd	a4,112(a5)
  }
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6902                	ld	s2,0(sp)
    80002eee:	6105                	addi	sp,sp,32
    80002ef0:	8082                	ret

0000000080002ef2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002efa:	fec40593          	addi	a1,s0,-20
    80002efe:	4501                	li	a0,0
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	ee6080e7          	jalr	-282(ra) # 80002de6 <argint>
    return -1;
    80002f08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f0a:	00054963          	bltz	a0,80002f1c <sys_exit+0x2a>
  exit(n);
    80002f0e:	fec42503          	lw	a0,-20(s0)
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	404080e7          	jalr	1028(ra) # 80002316 <exit>
  return 0;  // not reached
    80002f1a:	4781                	li	a5,0
}
    80002f1c:	853e                	mv	a0,a5
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	bfe080e7          	jalr	-1026(ra) # 80001b2c <myproc>
}
    80002f36:	5d08                	lw	a0,56(a0)
    80002f38:	60a2                	ld	ra,8(sp)
    80002f3a:	6402                	ld	s0,0(sp)
    80002f3c:	0141                	addi	sp,sp,16
    80002f3e:	8082                	ret

0000000080002f40 <sys_fork>:

uint64
sys_fork(void)
{
    80002f40:	1141                	addi	sp,sp,-16
    80002f42:	e406                	sd	ra,8(sp)
    80002f44:	e022                	sd	s0,0(sp)
    80002f46:	0800                	addi	s0,sp,16
  return fork();
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	020080e7          	jalr	32(ra) # 80001f68 <fork>
}
    80002f50:	60a2                	ld	ra,8(sp)
    80002f52:	6402                	ld	s0,0(sp)
    80002f54:	0141                	addi	sp,sp,16
    80002f56:	8082                	ret

0000000080002f58 <sys_wait>:

uint64
sys_wait(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f60:	fe840593          	addi	a1,s0,-24
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	ea2080e7          	jalr	-350(ra) # 80002e08 <argaddr>
    80002f6e:	87aa                	mv	a5,a0
    return -1;
    80002f70:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f72:	0007c863          	bltz	a5,80002f82 <sys_wait+0x2a>
  return wait(p);
    80002f76:	fe843503          	ld	a0,-24(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	60e080e7          	jalr	1550(ra) # 80002588 <wait>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret

0000000080002f8a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f94:	fdc40593          	addi	a1,s0,-36
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	e4c080e7          	jalr	-436(ra) # 80002de6 <argint>
    return -1;
    80002fa2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fa4:	00054f63          	bltz	a0,80002fc2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	b84080e7          	jalr	-1148(ra) # 80001b2c <myproc>
    80002fb0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fb2:	fdc42503          	lw	a0,-36(s0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	f3e080e7          	jalr	-194(ra) # 80001ef4 <growproc>
    80002fbe:	00054863          	bltz	a0,80002fce <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fc2:	8526                	mv	a0,s1
    80002fc4:	70a2                	ld	ra,40(sp)
    80002fc6:	7402                	ld	s0,32(sp)
    80002fc8:	64e2                	ld	s1,24(sp)
    80002fca:	6145                	addi	sp,sp,48
    80002fcc:	8082                	ret
    return -1;
    80002fce:	54fd                	li	s1,-1
    80002fd0:	bfcd                	j	80002fc2 <sys_sbrk+0x38>

0000000080002fd2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fd2:	7139                	addi	sp,sp,-64
    80002fd4:	fc06                	sd	ra,56(sp)
    80002fd6:	f822                	sd	s0,48(sp)
    80002fd8:	f426                	sd	s1,40(sp)
    80002fda:	f04a                	sd	s2,32(sp)
    80002fdc:	ec4e                	sd	s3,24(sp)
    80002fde:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe0:	fcc40593          	addi	a1,s0,-52
    80002fe4:	4501                	li	a0,0
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	e00080e7          	jalr	-512(ra) # 80002de6 <argint>
    return -1;
    80002fee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff0:	06054563          	bltz	a0,8000305a <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff4:	00015517          	auipc	a0,0x15
    80002ff8:	47450513          	addi	a0,a0,1140 # 80018468 <tickslock>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	c00080e7          	jalr	-1024(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80003004:	00006917          	auipc	s2,0x6
    80003008:	02092903          	lw	s2,32(s2) # 80009024 <ticks>
  while(ticks - ticks0 < n){
    8000300c:	fcc42783          	lw	a5,-52(s0)
    80003010:	cf85                	beqz	a5,80003048 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003012:	00015997          	auipc	s3,0x15
    80003016:	45698993          	addi	s3,s3,1110 # 80018468 <tickslock>
    8000301a:	00006497          	auipc	s1,0x6
    8000301e:	00a48493          	addi	s1,s1,10 # 80009024 <ticks>
    if(myproc()->killed){
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	b0a080e7          	jalr	-1270(ra) # 80001b2c <myproc>
    8000302a:	591c                	lw	a5,48(a0)
    8000302c:	ef9d                	bnez	a5,8000306a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000302e:	85ce                	mv	a1,s3
    80003030:	8526                	mv	a0,s1
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	4be080e7          	jalr	1214(ra) # 800024f0 <sleep>
  while(ticks - ticks0 < n){
    8000303a:	409c                	lw	a5,0(s1)
    8000303c:	412787bb          	subw	a5,a5,s2
    80003040:	fcc42703          	lw	a4,-52(s0)
    80003044:	fce7efe3          	bltu	a5,a4,80003022 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003048:	00015517          	auipc	a0,0x15
    8000304c:	42050513          	addi	a0,a0,1056 # 80018468 <tickslock>
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	c60080e7          	jalr	-928(ra) # 80000cb0 <release>
  return 0;
    80003058:	4781                	li	a5,0
}
    8000305a:	853e                	mv	a0,a5
    8000305c:	70e2                	ld	ra,56(sp)
    8000305e:	7442                	ld	s0,48(sp)
    80003060:	74a2                	ld	s1,40(sp)
    80003062:	7902                	ld	s2,32(sp)
    80003064:	69e2                	ld	s3,24(sp)
    80003066:	6121                	addi	sp,sp,64
    80003068:	8082                	ret
      release(&tickslock);
    8000306a:	00015517          	auipc	a0,0x15
    8000306e:	3fe50513          	addi	a0,a0,1022 # 80018468 <tickslock>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c3e080e7          	jalr	-962(ra) # 80000cb0 <release>
      return -1;
    8000307a:	57fd                	li	a5,-1
    8000307c:	bff9                	j	8000305a <sys_sleep+0x88>

000000008000307e <sys_kill>:

uint64
sys_kill(void)
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003086:	fec40593          	addi	a1,s0,-20
    8000308a:	4501                	li	a0,0
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	d5a080e7          	jalr	-678(ra) # 80002de6 <argint>
    80003094:	87aa                	mv	a5,a0
    return -1;
    80003096:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003098:	0007c863          	bltz	a5,800030a8 <sys_kill+0x2a>
  return kill(pid);
    8000309c:	fec42503          	lw	a0,-20(s0)
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	662080e7          	jalr	1634(ra) # 80002702 <kill>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret

00000000800030b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	e426                	sd	s1,8(sp)
    800030b8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	3ae50513          	addi	a0,a0,942 # 80018468 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	b3a080e7          	jalr	-1222(ra) # 80000bfc <acquire>
  xticks = ticks;
    800030ca:	00006497          	auipc	s1,0x6
    800030ce:	f5a4a483          	lw	s1,-166(s1) # 80009024 <ticks>
  release(&tickslock);
    800030d2:	00015517          	auipc	a0,0x15
    800030d6:	39650513          	addi	a0,a0,918 # 80018468 <tickslock>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	bd6080e7          	jalr	-1066(ra) # 80000cb0 <release>
  return xticks;
}
    800030e2:	02049513          	slli	a0,s1,0x20
    800030e6:	9101                	srli	a0,a0,0x20
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6105                	addi	sp,sp,32
    800030f0:	8082                	ret

00000000800030f2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030f2:	7179                	addi	sp,sp,-48
    800030f4:	f406                	sd	ra,40(sp)
    800030f6:	f022                	sd	s0,32(sp)
    800030f8:	ec26                	sd	s1,24(sp)
    800030fa:	e84a                	sd	s2,16(sp)
    800030fc:	e44e                	sd	s3,8(sp)
    800030fe:	e052                	sd	s4,0(sp)
    80003100:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003102:	00005597          	auipc	a1,0x5
    80003106:	43658593          	addi	a1,a1,1078 # 80008538 <syscalls+0xb0>
    8000310a:	00015517          	auipc	a0,0x15
    8000310e:	37650513          	addi	a0,a0,886 # 80018480 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	a5a080e7          	jalr	-1446(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000311a:	0001d797          	auipc	a5,0x1d
    8000311e:	36678793          	addi	a5,a5,870 # 80020480 <bcache+0x8000>
    80003122:	0001d717          	auipc	a4,0x1d
    80003126:	5c670713          	addi	a4,a4,1478 # 800206e8 <bcache+0x8268>
    8000312a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000312e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003132:	00015497          	auipc	s1,0x15
    80003136:	36648493          	addi	s1,s1,870 # 80018498 <bcache+0x18>
    b->next = bcache.head.next;
    8000313a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000313c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000313e:	00005a17          	auipc	s4,0x5
    80003142:	402a0a13          	addi	s4,s4,1026 # 80008540 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003146:	2b893783          	ld	a5,696(s2)
    8000314a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000314c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003150:	85d2                	mv	a1,s4
    80003152:	01048513          	addi	a0,s1,16
    80003156:	00001097          	auipc	ra,0x1
    8000315a:	4b2080e7          	jalr	1202(ra) # 80004608 <initsleeplock>
    bcache.head.next->prev = b;
    8000315e:	2b893783          	ld	a5,696(s2)
    80003162:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003164:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003168:	45848493          	addi	s1,s1,1112
    8000316c:	fd349de3          	bne	s1,s3,80003146 <binit+0x54>
  }
}
    80003170:	70a2                	ld	ra,40(sp)
    80003172:	7402                	ld	s0,32(sp)
    80003174:	64e2                	ld	s1,24(sp)
    80003176:	6942                	ld	s2,16(sp)
    80003178:	69a2                	ld	s3,8(sp)
    8000317a:	6a02                	ld	s4,0(sp)
    8000317c:	6145                	addi	sp,sp,48
    8000317e:	8082                	ret

0000000080003180 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003180:	7179                	addi	sp,sp,-48
    80003182:	f406                	sd	ra,40(sp)
    80003184:	f022                	sd	s0,32(sp)
    80003186:	ec26                	sd	s1,24(sp)
    80003188:	e84a                	sd	s2,16(sp)
    8000318a:	e44e                	sd	s3,8(sp)
    8000318c:	1800                	addi	s0,sp,48
    8000318e:	892a                	mv	s2,a0
    80003190:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003192:	00015517          	auipc	a0,0x15
    80003196:	2ee50513          	addi	a0,a0,750 # 80018480 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	a62080e7          	jalr	-1438(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031a2:	0001d497          	auipc	s1,0x1d
    800031a6:	5964b483          	ld	s1,1430(s1) # 80020738 <bcache+0x82b8>
    800031aa:	0001d797          	auipc	a5,0x1d
    800031ae:	53e78793          	addi	a5,a5,1342 # 800206e8 <bcache+0x8268>
    800031b2:	02f48f63          	beq	s1,a5,800031f0 <bread+0x70>
    800031b6:	873e                	mv	a4,a5
    800031b8:	a021                	j	800031c0 <bread+0x40>
    800031ba:	68a4                	ld	s1,80(s1)
    800031bc:	02e48a63          	beq	s1,a4,800031f0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031c0:	449c                	lw	a5,8(s1)
    800031c2:	ff279ce3          	bne	a5,s2,800031ba <bread+0x3a>
    800031c6:	44dc                	lw	a5,12(s1)
    800031c8:	ff3799e3          	bne	a5,s3,800031ba <bread+0x3a>
      b->refcnt++;
    800031cc:	40bc                	lw	a5,64(s1)
    800031ce:	2785                	addiw	a5,a5,1
    800031d0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d2:	00015517          	auipc	a0,0x15
    800031d6:	2ae50513          	addi	a0,a0,686 # 80018480 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	ad6080e7          	jalr	-1322(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031e2:	01048513          	addi	a0,s1,16
    800031e6:	00001097          	auipc	ra,0x1
    800031ea:	45c080e7          	jalr	1116(ra) # 80004642 <acquiresleep>
      return b;
    800031ee:	a8b9                	j	8000324c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f0:	0001d497          	auipc	s1,0x1d
    800031f4:	5404b483          	ld	s1,1344(s1) # 80020730 <bcache+0x82b0>
    800031f8:	0001d797          	auipc	a5,0x1d
    800031fc:	4f078793          	addi	a5,a5,1264 # 800206e8 <bcache+0x8268>
    80003200:	00f48863          	beq	s1,a5,80003210 <bread+0x90>
    80003204:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	cf81                	beqz	a5,80003220 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000320a:	64a4                	ld	s1,72(s1)
    8000320c:	fee49de3          	bne	s1,a4,80003206 <bread+0x86>
  panic("bget: no buffers");
    80003210:	00005517          	auipc	a0,0x5
    80003214:	33850513          	addi	a0,a0,824 # 80008548 <syscalls+0xc0>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	328080e7          	jalr	808(ra) # 80000540 <panic>
      b->dev = dev;
    80003220:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003224:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003228:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000322c:	4785                	li	a5,1
    8000322e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003230:	00015517          	auipc	a0,0x15
    80003234:	25050513          	addi	a0,a0,592 # 80018480 <bcache>
    80003238:	ffffe097          	auipc	ra,0xffffe
    8000323c:	a78080e7          	jalr	-1416(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003240:	01048513          	addi	a0,s1,16
    80003244:	00001097          	auipc	ra,0x1
    80003248:	3fe080e7          	jalr	1022(ra) # 80004642 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000324c:	409c                	lw	a5,0(s1)
    8000324e:	cb89                	beqz	a5,80003260 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003250:	8526                	mv	a0,s1
    80003252:	70a2                	ld	ra,40(sp)
    80003254:	7402                	ld	s0,32(sp)
    80003256:	64e2                	ld	s1,24(sp)
    80003258:	6942                	ld	s2,16(sp)
    8000325a:	69a2                	ld	s3,8(sp)
    8000325c:	6145                	addi	sp,sp,48
    8000325e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003260:	4581                	li	a1,0
    80003262:	8526                	mv	a0,s1
    80003264:	00003097          	auipc	ra,0x3
    80003268:	f28080e7          	jalr	-216(ra) # 8000618c <virtio_disk_rw>
    b->valid = 1;
    8000326c:	4785                	li	a5,1
    8000326e:	c09c                	sw	a5,0(s1)
  return b;
    80003270:	b7c5                	j	80003250 <bread+0xd0>

0000000080003272 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000327e:	0541                	addi	a0,a0,16
    80003280:	00001097          	auipc	ra,0x1
    80003284:	45c080e7          	jalr	1116(ra) # 800046dc <holdingsleep>
    80003288:	cd01                	beqz	a0,800032a0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000328a:	4585                	li	a1,1
    8000328c:	8526                	mv	a0,s1
    8000328e:	00003097          	auipc	ra,0x3
    80003292:	efe080e7          	jalr	-258(ra) # 8000618c <virtio_disk_rw>
}
    80003296:	60e2                	ld	ra,24(sp)
    80003298:	6442                	ld	s0,16(sp)
    8000329a:	64a2                	ld	s1,8(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret
    panic("bwrite");
    800032a0:	00005517          	auipc	a0,0x5
    800032a4:	2c050513          	addi	a0,a0,704 # 80008560 <syscalls+0xd8>
    800032a8:	ffffd097          	auipc	ra,0xffffd
    800032ac:	298080e7          	jalr	664(ra) # 80000540 <panic>

00000000800032b0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032b0:	1101                	addi	sp,sp,-32
    800032b2:	ec06                	sd	ra,24(sp)
    800032b4:	e822                	sd	s0,16(sp)
    800032b6:	e426                	sd	s1,8(sp)
    800032b8:	e04a                	sd	s2,0(sp)
    800032ba:	1000                	addi	s0,sp,32
    800032bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032be:	01050913          	addi	s2,a0,16
    800032c2:	854a                	mv	a0,s2
    800032c4:	00001097          	auipc	ra,0x1
    800032c8:	418080e7          	jalr	1048(ra) # 800046dc <holdingsleep>
    800032cc:	c92d                	beqz	a0,8000333e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ce:	854a                	mv	a0,s2
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	3c8080e7          	jalr	968(ra) # 80004698 <releasesleep>

  acquire(&bcache.lock);
    800032d8:	00015517          	auipc	a0,0x15
    800032dc:	1a850513          	addi	a0,a0,424 # 80018480 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	91c080e7          	jalr	-1764(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032e8:	40bc                	lw	a5,64(s1)
    800032ea:	37fd                	addiw	a5,a5,-1
    800032ec:	0007871b          	sext.w	a4,a5
    800032f0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032f2:	eb05                	bnez	a4,80003322 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032f4:	68bc                	ld	a5,80(s1)
    800032f6:	64b8                	ld	a4,72(s1)
    800032f8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032fa:	64bc                	ld	a5,72(s1)
    800032fc:	68b8                	ld	a4,80(s1)
    800032fe:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003300:	0001d797          	auipc	a5,0x1d
    80003304:	18078793          	addi	a5,a5,384 # 80020480 <bcache+0x8000>
    80003308:	2b87b703          	ld	a4,696(a5)
    8000330c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000330e:	0001d717          	auipc	a4,0x1d
    80003312:	3da70713          	addi	a4,a4,986 # 800206e8 <bcache+0x8268>
    80003316:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003318:	2b87b703          	ld	a4,696(a5)
    8000331c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000331e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003322:	00015517          	auipc	a0,0x15
    80003326:	15e50513          	addi	a0,a0,350 # 80018480 <bcache>
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	986080e7          	jalr	-1658(ra) # 80000cb0 <release>
}
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	64a2                	ld	s1,8(sp)
    80003338:	6902                	ld	s2,0(sp)
    8000333a:	6105                	addi	sp,sp,32
    8000333c:	8082                	ret
    panic("brelse");
    8000333e:	00005517          	auipc	a0,0x5
    80003342:	22a50513          	addi	a0,a0,554 # 80008568 <syscalls+0xe0>
    80003346:	ffffd097          	auipc	ra,0xffffd
    8000334a:	1fa080e7          	jalr	506(ra) # 80000540 <panic>

000000008000334e <bpin>:

void
bpin(struct buf *b) {
    8000334e:	1101                	addi	sp,sp,-32
    80003350:	ec06                	sd	ra,24(sp)
    80003352:	e822                	sd	s0,16(sp)
    80003354:	e426                	sd	s1,8(sp)
    80003356:	1000                	addi	s0,sp,32
    80003358:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000335a:	00015517          	auipc	a0,0x15
    8000335e:	12650513          	addi	a0,a0,294 # 80018480 <bcache>
    80003362:	ffffe097          	auipc	ra,0xffffe
    80003366:	89a080e7          	jalr	-1894(ra) # 80000bfc <acquire>
  b->refcnt++;
    8000336a:	40bc                	lw	a5,64(s1)
    8000336c:	2785                	addiw	a5,a5,1
    8000336e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003370:	00015517          	auipc	a0,0x15
    80003374:	11050513          	addi	a0,a0,272 # 80018480 <bcache>
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	938080e7          	jalr	-1736(ra) # 80000cb0 <release>
}
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	64a2                	ld	s1,8(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret

000000008000338a <bunpin>:

void
bunpin(struct buf *b) {
    8000338a:	1101                	addi	sp,sp,-32
    8000338c:	ec06                	sd	ra,24(sp)
    8000338e:	e822                	sd	s0,16(sp)
    80003390:	e426                	sd	s1,8(sp)
    80003392:	1000                	addi	s0,sp,32
    80003394:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003396:	00015517          	auipc	a0,0x15
    8000339a:	0ea50513          	addi	a0,a0,234 # 80018480 <bcache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	85e080e7          	jalr	-1954(ra) # 80000bfc <acquire>
  b->refcnt--;
    800033a6:	40bc                	lw	a5,64(s1)
    800033a8:	37fd                	addiw	a5,a5,-1
    800033aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033ac:	00015517          	auipc	a0,0x15
    800033b0:	0d450513          	addi	a0,a0,212 # 80018480 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	8fc080e7          	jalr	-1796(ra) # 80000cb0 <release>
}
    800033bc:	60e2                	ld	ra,24(sp)
    800033be:	6442                	ld	s0,16(sp)
    800033c0:	64a2                	ld	s1,8(sp)
    800033c2:	6105                	addi	sp,sp,32
    800033c4:	8082                	ret

00000000800033c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	e04a                	sd	s2,0(sp)
    800033d0:	1000                	addi	s0,sp,32
    800033d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033d4:	00d5d59b          	srliw	a1,a1,0xd
    800033d8:	0001d797          	auipc	a5,0x1d
    800033dc:	7847a783          	lw	a5,1924(a5) # 80020b5c <sb+0x1c>
    800033e0:	9dbd                	addw	a1,a1,a5
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	d9e080e7          	jalr	-610(ra) # 80003180 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033ea:	0074f713          	andi	a4,s1,7
    800033ee:	4785                	li	a5,1
    800033f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033f4:	14ce                	slli	s1,s1,0x33
    800033f6:	90d9                	srli	s1,s1,0x36
    800033f8:	00950733          	add	a4,a0,s1
    800033fc:	05874703          	lbu	a4,88(a4)
    80003400:	00e7f6b3          	and	a3,a5,a4
    80003404:	c69d                	beqz	a3,80003432 <bfree+0x6c>
    80003406:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003408:	94aa                	add	s1,s1,a0
    8000340a:	fff7c793          	not	a5,a5
    8000340e:	8ff9                	and	a5,a5,a4
    80003410:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003414:	00001097          	auipc	ra,0x1
    80003418:	106080e7          	jalr	262(ra) # 8000451a <log_write>
  brelse(bp);
    8000341c:	854a                	mv	a0,s2
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	e92080e7          	jalr	-366(ra) # 800032b0 <brelse>
}
    80003426:	60e2                	ld	ra,24(sp)
    80003428:	6442                	ld	s0,16(sp)
    8000342a:	64a2                	ld	s1,8(sp)
    8000342c:	6902                	ld	s2,0(sp)
    8000342e:	6105                	addi	sp,sp,32
    80003430:	8082                	ret
    panic("freeing free block");
    80003432:	00005517          	auipc	a0,0x5
    80003436:	13e50513          	addi	a0,a0,318 # 80008570 <syscalls+0xe8>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	106080e7          	jalr	262(ra) # 80000540 <panic>

0000000080003442 <balloc>:
{
    80003442:	711d                	addi	sp,sp,-96
    80003444:	ec86                	sd	ra,88(sp)
    80003446:	e8a2                	sd	s0,80(sp)
    80003448:	e4a6                	sd	s1,72(sp)
    8000344a:	e0ca                	sd	s2,64(sp)
    8000344c:	fc4e                	sd	s3,56(sp)
    8000344e:	f852                	sd	s4,48(sp)
    80003450:	f456                	sd	s5,40(sp)
    80003452:	f05a                	sd	s6,32(sp)
    80003454:	ec5e                	sd	s7,24(sp)
    80003456:	e862                	sd	s8,16(sp)
    80003458:	e466                	sd	s9,8(sp)
    8000345a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000345c:	0001d797          	auipc	a5,0x1d
    80003460:	6e87a783          	lw	a5,1768(a5) # 80020b44 <sb+0x4>
    80003464:	cbd1                	beqz	a5,800034f8 <balloc+0xb6>
    80003466:	8baa                	mv	s7,a0
    80003468:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000346a:	0001db17          	auipc	s6,0x1d
    8000346e:	6d6b0b13          	addi	s6,s6,1750 # 80020b40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003474:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003476:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003478:	6c89                	lui	s9,0x2
    8000347a:	a831                	j	80003496 <balloc+0x54>
    brelse(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e32080e7          	jalr	-462(ra) # 800032b0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003486:	015c87bb          	addw	a5,s9,s5
    8000348a:	00078a9b          	sext.w	s5,a5
    8000348e:	004b2703          	lw	a4,4(s6)
    80003492:	06eaf363          	bgeu	s5,a4,800034f8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003496:	41fad79b          	sraiw	a5,s5,0x1f
    8000349a:	0137d79b          	srliw	a5,a5,0x13
    8000349e:	015787bb          	addw	a5,a5,s5
    800034a2:	40d7d79b          	sraiw	a5,a5,0xd
    800034a6:	01cb2583          	lw	a1,28(s6)
    800034aa:	9dbd                	addw	a1,a1,a5
    800034ac:	855e                	mv	a0,s7
    800034ae:	00000097          	auipc	ra,0x0
    800034b2:	cd2080e7          	jalr	-814(ra) # 80003180 <bread>
    800034b6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	004b2503          	lw	a0,4(s6)
    800034bc:	000a849b          	sext.w	s1,s5
    800034c0:	8662                	mv	a2,s8
    800034c2:	faa4fde3          	bgeu	s1,a0,8000347c <balloc+0x3a>
      m = 1 << (bi % 8);
    800034c6:	41f6579b          	sraiw	a5,a2,0x1f
    800034ca:	01d7d69b          	srliw	a3,a5,0x1d
    800034ce:	00c6873b          	addw	a4,a3,a2
    800034d2:	00777793          	andi	a5,a4,7
    800034d6:	9f95                	subw	a5,a5,a3
    800034d8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034dc:	4037571b          	sraiw	a4,a4,0x3
    800034e0:	00e906b3          	add	a3,s2,a4
    800034e4:	0586c683          	lbu	a3,88(a3)
    800034e8:	00d7f5b3          	and	a1,a5,a3
    800034ec:	cd91                	beqz	a1,80003508 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ee:	2605                	addiw	a2,a2,1
    800034f0:	2485                	addiw	s1,s1,1
    800034f2:	fd4618e3          	bne	a2,s4,800034c2 <balloc+0x80>
    800034f6:	b759                	j	8000347c <balloc+0x3a>
  panic("balloc: out of blocks");
    800034f8:	00005517          	auipc	a0,0x5
    800034fc:	09050513          	addi	a0,a0,144 # 80008588 <syscalls+0x100>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	040080e7          	jalr	64(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003508:	974a                	add	a4,a4,s2
    8000350a:	8fd5                	or	a5,a5,a3
    8000350c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	008080e7          	jalr	8(ra) # 8000451a <log_write>
        brelse(bp);
    8000351a:	854a                	mv	a0,s2
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	d94080e7          	jalr	-620(ra) # 800032b0 <brelse>
  bp = bread(dev, bno);
    80003524:	85a6                	mv	a1,s1
    80003526:	855e                	mv	a0,s7
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	c58080e7          	jalr	-936(ra) # 80003180 <bread>
    80003530:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003532:	40000613          	li	a2,1024
    80003536:	4581                	li	a1,0
    80003538:	05850513          	addi	a0,a0,88
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	7bc080e7          	jalr	1980(ra) # 80000cf8 <memset>
  log_write(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	fd4080e7          	jalr	-44(ra) # 8000451a <log_write>
  brelse(bp);
    8000354e:	854a                	mv	a0,s2
    80003550:	00000097          	auipc	ra,0x0
    80003554:	d60080e7          	jalr	-672(ra) # 800032b0 <brelse>
}
    80003558:	8526                	mv	a0,s1
    8000355a:	60e6                	ld	ra,88(sp)
    8000355c:	6446                	ld	s0,80(sp)
    8000355e:	64a6                	ld	s1,72(sp)
    80003560:	6906                	ld	s2,64(sp)
    80003562:	79e2                	ld	s3,56(sp)
    80003564:	7a42                	ld	s4,48(sp)
    80003566:	7aa2                	ld	s5,40(sp)
    80003568:	7b02                	ld	s6,32(sp)
    8000356a:	6be2                	ld	s7,24(sp)
    8000356c:	6c42                	ld	s8,16(sp)
    8000356e:	6ca2                	ld	s9,8(sp)
    80003570:	6125                	addi	sp,sp,96
    80003572:	8082                	ret

0000000080003574 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003574:	7179                	addi	sp,sp,-48
    80003576:	f406                	sd	ra,40(sp)
    80003578:	f022                	sd	s0,32(sp)
    8000357a:	ec26                	sd	s1,24(sp)
    8000357c:	e84a                	sd	s2,16(sp)
    8000357e:	e44e                	sd	s3,8(sp)
    80003580:	e052                	sd	s4,0(sp)
    80003582:	1800                	addi	s0,sp,48
    80003584:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003586:	47ad                	li	a5,11
    80003588:	04b7fe63          	bgeu	a5,a1,800035e4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000358c:	ff45849b          	addiw	s1,a1,-12
    80003590:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003594:	0ff00793          	li	a5,255
    80003598:	0ae7e463          	bltu	a5,a4,80003640 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000359c:	08052583          	lw	a1,128(a0)
    800035a0:	c5b5                	beqz	a1,8000360c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035a2:	00092503          	lw	a0,0(s2)
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	bda080e7          	jalr	-1062(ra) # 80003180 <bread>
    800035ae:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b4:	02049713          	slli	a4,s1,0x20
    800035b8:	01e75593          	srli	a1,a4,0x1e
    800035bc:	00b784b3          	add	s1,a5,a1
    800035c0:	0004a983          	lw	s3,0(s1)
    800035c4:	04098e63          	beqz	s3,80003620 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035c8:	8552                	mv	a0,s4
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	ce6080e7          	jalr	-794(ra) # 800032b0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d2:	854e                	mv	a0,s3
    800035d4:	70a2                	ld	ra,40(sp)
    800035d6:	7402                	ld	s0,32(sp)
    800035d8:	64e2                	ld	s1,24(sp)
    800035da:	6942                	ld	s2,16(sp)
    800035dc:	69a2                	ld	s3,8(sp)
    800035de:	6a02                	ld	s4,0(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e4:	02059793          	slli	a5,a1,0x20
    800035e8:	01e7d593          	srli	a1,a5,0x1e
    800035ec:	00b504b3          	add	s1,a0,a1
    800035f0:	0504a983          	lw	s3,80(s1)
    800035f4:	fc099fe3          	bnez	s3,800035d2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035f8:	4108                	lw	a0,0(a0)
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	e48080e7          	jalr	-440(ra) # 80003442 <balloc>
    80003602:	0005099b          	sext.w	s3,a0
    80003606:	0534a823          	sw	s3,80(s1)
    8000360a:	b7e1                	j	800035d2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000360c:	4108                	lw	a0,0(a0)
    8000360e:	00000097          	auipc	ra,0x0
    80003612:	e34080e7          	jalr	-460(ra) # 80003442 <balloc>
    80003616:	0005059b          	sext.w	a1,a0
    8000361a:	08b92023          	sw	a1,128(s2)
    8000361e:	b751                	j	800035a2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003620:	00092503          	lw	a0,0(s2)
    80003624:	00000097          	auipc	ra,0x0
    80003628:	e1e080e7          	jalr	-482(ra) # 80003442 <balloc>
    8000362c:	0005099b          	sext.w	s3,a0
    80003630:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003634:	8552                	mv	a0,s4
    80003636:	00001097          	auipc	ra,0x1
    8000363a:	ee4080e7          	jalr	-284(ra) # 8000451a <log_write>
    8000363e:	b769                	j	800035c8 <bmap+0x54>
  panic("bmap: out of range");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	f6050513          	addi	a0,a0,-160 # 800085a0 <syscalls+0x118>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ef8080e7          	jalr	-264(ra) # 80000540 <panic>

0000000080003650 <iget>:
{
    80003650:	7179                	addi	sp,sp,-48
    80003652:	f406                	sd	ra,40(sp)
    80003654:	f022                	sd	s0,32(sp)
    80003656:	ec26                	sd	s1,24(sp)
    80003658:	e84a                	sd	s2,16(sp)
    8000365a:	e44e                	sd	s3,8(sp)
    8000365c:	e052                	sd	s4,0(sp)
    8000365e:	1800                	addi	s0,sp,48
    80003660:	89aa                	mv	s3,a0
    80003662:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003664:	0001d517          	auipc	a0,0x1d
    80003668:	4fc50513          	addi	a0,a0,1276 # 80020b60 <icache>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	590080e7          	jalr	1424(ra) # 80000bfc <acquire>
  empty = 0;
    80003674:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003676:	0001d497          	auipc	s1,0x1d
    8000367a:	50248493          	addi	s1,s1,1282 # 80020b78 <icache+0x18>
    8000367e:	0001f697          	auipc	a3,0x1f
    80003682:	f8a68693          	addi	a3,a3,-118 # 80022608 <log>
    80003686:	a039                	j	80003694 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003688:	02090b63          	beqz	s2,800036be <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000368c:	08848493          	addi	s1,s1,136
    80003690:	02d48a63          	beq	s1,a3,800036c4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003694:	449c                	lw	a5,8(s1)
    80003696:	fef059e3          	blez	a5,80003688 <iget+0x38>
    8000369a:	4098                	lw	a4,0(s1)
    8000369c:	ff3716e3          	bne	a4,s3,80003688 <iget+0x38>
    800036a0:	40d8                	lw	a4,4(s1)
    800036a2:	ff4713e3          	bne	a4,s4,80003688 <iget+0x38>
      ip->ref++;
    800036a6:	2785                	addiw	a5,a5,1
    800036a8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036aa:	0001d517          	auipc	a0,0x1d
    800036ae:	4b650513          	addi	a0,a0,1206 # 80020b60 <icache>
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	5fe080e7          	jalr	1534(ra) # 80000cb0 <release>
      return ip;
    800036ba:	8926                	mv	s2,s1
    800036bc:	a03d                	j	800036ea <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036be:	f7f9                	bnez	a5,8000368c <iget+0x3c>
    800036c0:	8926                	mv	s2,s1
    800036c2:	b7e9                	j	8000368c <iget+0x3c>
  if(empty == 0)
    800036c4:	02090c63          	beqz	s2,800036fc <iget+0xac>
  ip->dev = dev;
    800036c8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036cc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d0:	4785                	li	a5,1
    800036d2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d6:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036da:	0001d517          	auipc	a0,0x1d
    800036de:	48650513          	addi	a0,a0,1158 # 80020b60 <icache>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	5ce080e7          	jalr	1486(ra) # 80000cb0 <release>
}
    800036ea:	854a                	mv	a0,s2
    800036ec:	70a2                	ld	ra,40(sp)
    800036ee:	7402                	ld	s0,32(sp)
    800036f0:	64e2                	ld	s1,24(sp)
    800036f2:	6942                	ld	s2,16(sp)
    800036f4:	69a2                	ld	s3,8(sp)
    800036f6:	6a02                	ld	s4,0(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret
    panic("iget: no inodes");
    800036fc:	00005517          	auipc	a0,0x5
    80003700:	ebc50513          	addi	a0,a0,-324 # 800085b8 <syscalls+0x130>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	e3c080e7          	jalr	-452(ra) # 80000540 <panic>

000000008000370c <fsinit>:
fsinit(int dev) {
    8000370c:	7179                	addi	sp,sp,-48
    8000370e:	f406                	sd	ra,40(sp)
    80003710:	f022                	sd	s0,32(sp)
    80003712:	ec26                	sd	s1,24(sp)
    80003714:	e84a                	sd	s2,16(sp)
    80003716:	e44e                	sd	s3,8(sp)
    80003718:	1800                	addi	s0,sp,48
    8000371a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000371c:	4585                	li	a1,1
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	a62080e7          	jalr	-1438(ra) # 80003180 <bread>
    80003726:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003728:	0001d997          	auipc	s3,0x1d
    8000372c:	41898993          	addi	s3,s3,1048 # 80020b40 <sb>
    80003730:	02000613          	li	a2,32
    80003734:	05850593          	addi	a1,a0,88
    80003738:	854e                	mv	a0,s3
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	61a080e7          	jalr	1562(ra) # 80000d54 <memmove>
  brelse(bp);
    80003742:	8526                	mv	a0,s1
    80003744:	00000097          	auipc	ra,0x0
    80003748:	b6c080e7          	jalr	-1172(ra) # 800032b0 <brelse>
  if(sb.magic != FSMAGIC)
    8000374c:	0009a703          	lw	a4,0(s3)
    80003750:	102037b7          	lui	a5,0x10203
    80003754:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003758:	02f71263          	bne	a4,a5,8000377c <fsinit+0x70>
  initlog(dev, &sb);
    8000375c:	0001d597          	auipc	a1,0x1d
    80003760:	3e458593          	addi	a1,a1,996 # 80020b40 <sb>
    80003764:	854a                	mv	a0,s2
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	b3a080e7          	jalr	-1222(ra) # 800042a0 <initlog>
}
    8000376e:	70a2                	ld	ra,40(sp)
    80003770:	7402                	ld	s0,32(sp)
    80003772:	64e2                	ld	s1,24(sp)
    80003774:	6942                	ld	s2,16(sp)
    80003776:	69a2                	ld	s3,8(sp)
    80003778:	6145                	addi	sp,sp,48
    8000377a:	8082                	ret
    panic("invalid file system");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	e4c50513          	addi	a0,a0,-436 # 800085c8 <syscalls+0x140>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	dbc080e7          	jalr	-580(ra) # 80000540 <panic>

000000008000378c <iinit>:
{
    8000378c:	7179                	addi	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000379a:	00005597          	auipc	a1,0x5
    8000379e:	e4658593          	addi	a1,a1,-442 # 800085e0 <syscalls+0x158>
    800037a2:	0001d517          	auipc	a0,0x1d
    800037a6:	3be50513          	addi	a0,a0,958 # 80020b60 <icache>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	3c2080e7          	jalr	962(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037b2:	0001d497          	auipc	s1,0x1d
    800037b6:	3d648493          	addi	s1,s1,982 # 80020b88 <icache+0x28>
    800037ba:	0001f997          	auipc	s3,0x1f
    800037be:	e5e98993          	addi	s3,s3,-418 # 80022618 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037c2:	00005917          	auipc	s2,0x5
    800037c6:	e2690913          	addi	s2,s2,-474 # 800085e8 <syscalls+0x160>
    800037ca:	85ca                	mv	a1,s2
    800037cc:	8526                	mv	a0,s1
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	e3a080e7          	jalr	-454(ra) # 80004608 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d6:	08848493          	addi	s1,s1,136
    800037da:	ff3498e3          	bne	s1,s3,800037ca <iinit+0x3e>
}
    800037de:	70a2                	ld	ra,40(sp)
    800037e0:	7402                	ld	s0,32(sp)
    800037e2:	64e2                	ld	s1,24(sp)
    800037e4:	6942                	ld	s2,16(sp)
    800037e6:	69a2                	ld	s3,8(sp)
    800037e8:	6145                	addi	sp,sp,48
    800037ea:	8082                	ret

00000000800037ec <ialloc>:
{
    800037ec:	715d                	addi	sp,sp,-80
    800037ee:	e486                	sd	ra,72(sp)
    800037f0:	e0a2                	sd	s0,64(sp)
    800037f2:	fc26                	sd	s1,56(sp)
    800037f4:	f84a                	sd	s2,48(sp)
    800037f6:	f44e                	sd	s3,40(sp)
    800037f8:	f052                	sd	s4,32(sp)
    800037fa:	ec56                	sd	s5,24(sp)
    800037fc:	e85a                	sd	s6,16(sp)
    800037fe:	e45e                	sd	s7,8(sp)
    80003800:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003802:	0001d717          	auipc	a4,0x1d
    80003806:	34a72703          	lw	a4,842(a4) # 80020b4c <sb+0xc>
    8000380a:	4785                	li	a5,1
    8000380c:	04e7fa63          	bgeu	a5,a4,80003860 <ialloc+0x74>
    80003810:	8aaa                	mv	s5,a0
    80003812:	8bae                	mv	s7,a1
    80003814:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003816:	0001da17          	auipc	s4,0x1d
    8000381a:	32aa0a13          	addi	s4,s4,810 # 80020b40 <sb>
    8000381e:	00048b1b          	sext.w	s6,s1
    80003822:	0044d793          	srli	a5,s1,0x4
    80003826:	018a2583          	lw	a1,24(s4)
    8000382a:	9dbd                	addw	a1,a1,a5
    8000382c:	8556                	mv	a0,s5
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	952080e7          	jalr	-1710(ra) # 80003180 <bread>
    80003836:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003838:	05850993          	addi	s3,a0,88
    8000383c:	00f4f793          	andi	a5,s1,15
    80003840:	079a                	slli	a5,a5,0x6
    80003842:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003844:	00099783          	lh	a5,0(s3)
    80003848:	c785                	beqz	a5,80003870 <ialloc+0x84>
    brelse(bp);
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	a66080e7          	jalr	-1434(ra) # 800032b0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003852:	0485                	addi	s1,s1,1
    80003854:	00ca2703          	lw	a4,12(s4)
    80003858:	0004879b          	sext.w	a5,s1
    8000385c:	fce7e1e3          	bltu	a5,a4,8000381e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	d9050513          	addi	a0,a0,-624 # 800085f0 <syscalls+0x168>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cd8080e7          	jalr	-808(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003870:	04000613          	li	a2,64
    80003874:	4581                	li	a1,0
    80003876:	854e                	mv	a0,s3
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	480080e7          	jalr	1152(ra) # 80000cf8 <memset>
      dip->type = type;
    80003880:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	c94080e7          	jalr	-876(ra) # 8000451a <log_write>
      brelse(bp);
    8000388e:	854a                	mv	a0,s2
    80003890:	00000097          	auipc	ra,0x0
    80003894:	a20080e7          	jalr	-1504(ra) # 800032b0 <brelse>
      return iget(dev, inum);
    80003898:	85da                	mv	a1,s6
    8000389a:	8556                	mv	a0,s5
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	db4080e7          	jalr	-588(ra) # 80003650 <iget>
}
    800038a4:	60a6                	ld	ra,72(sp)
    800038a6:	6406                	ld	s0,64(sp)
    800038a8:	74e2                	ld	s1,56(sp)
    800038aa:	7942                	ld	s2,48(sp)
    800038ac:	79a2                	ld	s3,40(sp)
    800038ae:	7a02                	ld	s4,32(sp)
    800038b0:	6ae2                	ld	s5,24(sp)
    800038b2:	6b42                	ld	s6,16(sp)
    800038b4:	6ba2                	ld	s7,8(sp)
    800038b6:	6161                	addi	sp,sp,80
    800038b8:	8082                	ret

00000000800038ba <iupdate>:
{
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	e04a                	sd	s2,0(sp)
    800038c4:	1000                	addi	s0,sp,32
    800038c6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c8:	415c                	lw	a5,4(a0)
    800038ca:	0047d79b          	srliw	a5,a5,0x4
    800038ce:	0001d597          	auipc	a1,0x1d
    800038d2:	28a5a583          	lw	a1,650(a1) # 80020b58 <sb+0x18>
    800038d6:	9dbd                	addw	a1,a1,a5
    800038d8:	4108                	lw	a0,0(a0)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	8a6080e7          	jalr	-1882(ra) # 80003180 <bread>
    800038e2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e4:	05850793          	addi	a5,a0,88
    800038e8:	40c8                	lw	a0,4(s1)
    800038ea:	893d                	andi	a0,a0,15
    800038ec:	051a                	slli	a0,a0,0x6
    800038ee:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f0:	04449703          	lh	a4,68(s1)
    800038f4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038f8:	04649703          	lh	a4,70(s1)
    800038fc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003900:	04849703          	lh	a4,72(s1)
    80003904:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003908:	04a49703          	lh	a4,74(s1)
    8000390c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003910:	44f8                	lw	a4,76(s1)
    80003912:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003914:	03400613          	li	a2,52
    80003918:	05048593          	addi	a1,s1,80
    8000391c:	0531                	addi	a0,a0,12
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	436080e7          	jalr	1078(ra) # 80000d54 <memmove>
  log_write(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00001097          	auipc	ra,0x1
    8000392c:	bf2080e7          	jalr	-1038(ra) # 8000451a <log_write>
  brelse(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	00000097          	auipc	ra,0x0
    80003936:	97e080e7          	jalr	-1666(ra) # 800032b0 <brelse>
}
    8000393a:	60e2                	ld	ra,24(sp)
    8000393c:	6442                	ld	s0,16(sp)
    8000393e:	64a2                	ld	s1,8(sp)
    80003940:	6902                	ld	s2,0(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret

0000000080003946 <idup>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	1000                	addi	s0,sp,32
    80003950:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003952:	0001d517          	auipc	a0,0x1d
    80003956:	20e50513          	addi	a0,a0,526 # 80020b60 <icache>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	2a2080e7          	jalr	674(ra) # 80000bfc <acquire>
  ip->ref++;
    80003962:	449c                	lw	a5,8(s1)
    80003964:	2785                	addiw	a5,a5,1
    80003966:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003968:	0001d517          	auipc	a0,0x1d
    8000396c:	1f850513          	addi	a0,a0,504 # 80020b60 <icache>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	340080e7          	jalr	832(ra) # 80000cb0 <release>
}
    80003978:	8526                	mv	a0,s1
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret

0000000080003984 <ilock>:
{
    80003984:	1101                	addi	sp,sp,-32
    80003986:	ec06                	sd	ra,24(sp)
    80003988:	e822                	sd	s0,16(sp)
    8000398a:	e426                	sd	s1,8(sp)
    8000398c:	e04a                	sd	s2,0(sp)
    8000398e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003990:	c115                	beqz	a0,800039b4 <ilock+0x30>
    80003992:	84aa                	mv	s1,a0
    80003994:	451c                	lw	a5,8(a0)
    80003996:	00f05f63          	blez	a5,800039b4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399a:	0541                	addi	a0,a0,16
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	ca6080e7          	jalr	-858(ra) # 80004642 <acquiresleep>
  if(ip->valid == 0){
    800039a4:	40bc                	lw	a5,64(s1)
    800039a6:	cf99                	beqz	a5,800039c4 <ilock+0x40>
}
    800039a8:	60e2                	ld	ra,24(sp)
    800039aa:	6442                	ld	s0,16(sp)
    800039ac:	64a2                	ld	s1,8(sp)
    800039ae:	6902                	ld	s2,0(sp)
    800039b0:	6105                	addi	sp,sp,32
    800039b2:	8082                	ret
    panic("ilock");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	c5450513          	addi	a0,a0,-940 # 80008608 <syscalls+0x180>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b84080e7          	jalr	-1148(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c4:	40dc                	lw	a5,4(s1)
    800039c6:	0047d79b          	srliw	a5,a5,0x4
    800039ca:	0001d597          	auipc	a1,0x1d
    800039ce:	18e5a583          	lw	a1,398(a1) # 80020b58 <sb+0x18>
    800039d2:	9dbd                	addw	a1,a1,a5
    800039d4:	4088                	lw	a0,0(s1)
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	7aa080e7          	jalr	1962(ra) # 80003180 <bread>
    800039de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e0:	05850593          	addi	a1,a0,88
    800039e4:	40dc                	lw	a5,4(s1)
    800039e6:	8bbd                	andi	a5,a5,15
    800039e8:	079a                	slli	a5,a5,0x6
    800039ea:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039ec:	00059783          	lh	a5,0(a1)
    800039f0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f4:	00259783          	lh	a5,2(a1)
    800039f8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039fc:	00459783          	lh	a5,4(a1)
    80003a00:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a04:	00659783          	lh	a5,6(a1)
    80003a08:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a0c:	459c                	lw	a5,8(a1)
    80003a0e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a10:	03400613          	li	a2,52
    80003a14:	05b1                	addi	a1,a1,12
    80003a16:	05048513          	addi	a0,s1,80
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	33a080e7          	jalr	826(ra) # 80000d54 <memmove>
    brelse(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	88c080e7          	jalr	-1908(ra) # 800032b0 <brelse>
    ip->valid = 1;
    80003a2c:	4785                	li	a5,1
    80003a2e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a30:	04449783          	lh	a5,68(s1)
    80003a34:	fbb5                	bnez	a5,800039a8 <ilock+0x24>
      panic("ilock: no type");
    80003a36:	00005517          	auipc	a0,0x5
    80003a3a:	bda50513          	addi	a0,a0,-1062 # 80008610 <syscalls+0x188>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	b02080e7          	jalr	-1278(ra) # 80000540 <panic>

0000000080003a46 <iunlock>:
{
    80003a46:	1101                	addi	sp,sp,-32
    80003a48:	ec06                	sd	ra,24(sp)
    80003a4a:	e822                	sd	s0,16(sp)
    80003a4c:	e426                	sd	s1,8(sp)
    80003a4e:	e04a                	sd	s2,0(sp)
    80003a50:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a52:	c905                	beqz	a0,80003a82 <iunlock+0x3c>
    80003a54:	84aa                	mv	s1,a0
    80003a56:	01050913          	addi	s2,a0,16
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	c80080e7          	jalr	-896(ra) # 800046dc <holdingsleep>
    80003a64:	cd19                	beqz	a0,80003a82 <iunlock+0x3c>
    80003a66:	449c                	lw	a5,8(s1)
    80003a68:	00f05d63          	blez	a5,80003a82 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00001097          	auipc	ra,0x1
    80003a72:	c2a080e7          	jalr	-982(ra) # 80004698 <releasesleep>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret
    panic("iunlock");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	b9e50513          	addi	a0,a0,-1122 # 80008620 <syscalls+0x198>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab6080e7          	jalr	-1354(ra) # 80000540 <panic>

0000000080003a92 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a92:	7179                	addi	sp,sp,-48
    80003a94:	f406                	sd	ra,40(sp)
    80003a96:	f022                	sd	s0,32(sp)
    80003a98:	ec26                	sd	s1,24(sp)
    80003a9a:	e84a                	sd	s2,16(sp)
    80003a9c:	e44e                	sd	s3,8(sp)
    80003a9e:	e052                	sd	s4,0(sp)
    80003aa0:	1800                	addi	s0,sp,48
    80003aa2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aa4:	05050493          	addi	s1,a0,80
    80003aa8:	08050913          	addi	s2,a0,128
    80003aac:	a021                	j	80003ab4 <itrunc+0x22>
    80003aae:	0491                	addi	s1,s1,4
    80003ab0:	01248d63          	beq	s1,s2,80003aca <itrunc+0x38>
    if(ip->addrs[i]){
    80003ab4:	408c                	lw	a1,0(s1)
    80003ab6:	dde5                	beqz	a1,80003aae <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ab8:	0009a503          	lw	a0,0(s3)
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	90a080e7          	jalr	-1782(ra) # 800033c6 <bfree>
      ip->addrs[i] = 0;
    80003ac4:	0004a023          	sw	zero,0(s1)
    80003ac8:	b7dd                	j	80003aae <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aca:	0809a583          	lw	a1,128(s3)
    80003ace:	e185                	bnez	a1,80003aee <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad4:	854e                	mv	a0,s3
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	de4080e7          	jalr	-540(ra) # 800038ba <iupdate>
}
    80003ade:	70a2                	ld	ra,40(sp)
    80003ae0:	7402                	ld	s0,32(sp)
    80003ae2:	64e2                	ld	s1,24(sp)
    80003ae4:	6942                	ld	s2,16(sp)
    80003ae6:	69a2                	ld	s3,8(sp)
    80003ae8:	6a02                	ld	s4,0(sp)
    80003aea:	6145                	addi	sp,sp,48
    80003aec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aee:	0009a503          	lw	a0,0(s3)
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	68e080e7          	jalr	1678(ra) # 80003180 <bread>
    80003afa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003afc:	05850493          	addi	s1,a0,88
    80003b00:	45850913          	addi	s2,a0,1112
    80003b04:	a021                	j	80003b0c <itrunc+0x7a>
    80003b06:	0491                	addi	s1,s1,4
    80003b08:	01248b63          	beq	s1,s2,80003b1e <itrunc+0x8c>
      if(a[j])
    80003b0c:	408c                	lw	a1,0(s1)
    80003b0e:	dde5                	beqz	a1,80003b06 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	8b2080e7          	jalr	-1870(ra) # 800033c6 <bfree>
    80003b1c:	b7ed                	j	80003b06 <itrunc+0x74>
    brelse(bp);
    80003b1e:	8552                	mv	a0,s4
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	790080e7          	jalr	1936(ra) # 800032b0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b28:	0809a583          	lw	a1,128(s3)
    80003b2c:	0009a503          	lw	a0,0(s3)
    80003b30:	00000097          	auipc	ra,0x0
    80003b34:	896080e7          	jalr	-1898(ra) # 800033c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b38:	0809a023          	sw	zero,128(s3)
    80003b3c:	bf51                	j	80003ad0 <itrunc+0x3e>

0000000080003b3e <iput>:
{
    80003b3e:	1101                	addi	sp,sp,-32
    80003b40:	ec06                	sd	ra,24(sp)
    80003b42:	e822                	sd	s0,16(sp)
    80003b44:	e426                	sd	s1,8(sp)
    80003b46:	e04a                	sd	s2,0(sp)
    80003b48:	1000                	addi	s0,sp,32
    80003b4a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b4c:	0001d517          	auipc	a0,0x1d
    80003b50:	01450513          	addi	a0,a0,20 # 80020b60 <icache>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	0a8080e7          	jalr	168(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b5c:	4498                	lw	a4,8(s1)
    80003b5e:	4785                	li	a5,1
    80003b60:	02f70363          	beq	a4,a5,80003b86 <iput+0x48>
  ip->ref--;
    80003b64:	449c                	lw	a5,8(s1)
    80003b66:	37fd                	addiw	a5,a5,-1
    80003b68:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b6a:	0001d517          	auipc	a0,0x1d
    80003b6e:	ff650513          	addi	a0,a0,-10 # 80020b60 <icache>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	13e080e7          	jalr	318(ra) # 80000cb0 <release>
}
    80003b7a:	60e2                	ld	ra,24(sp)
    80003b7c:	6442                	ld	s0,16(sp)
    80003b7e:	64a2                	ld	s1,8(sp)
    80003b80:	6902                	ld	s2,0(sp)
    80003b82:	6105                	addi	sp,sp,32
    80003b84:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b86:	40bc                	lw	a5,64(s1)
    80003b88:	dff1                	beqz	a5,80003b64 <iput+0x26>
    80003b8a:	04a49783          	lh	a5,74(s1)
    80003b8e:	fbf9                	bnez	a5,80003b64 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b90:	01048913          	addi	s2,s1,16
    80003b94:	854a                	mv	a0,s2
    80003b96:	00001097          	auipc	ra,0x1
    80003b9a:	aac080e7          	jalr	-1364(ra) # 80004642 <acquiresleep>
    release(&icache.lock);
    80003b9e:	0001d517          	auipc	a0,0x1d
    80003ba2:	fc250513          	addi	a0,a0,-62 # 80020b60 <icache>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	10a080e7          	jalr	266(ra) # 80000cb0 <release>
    itrunc(ip);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	ee2080e7          	jalr	-286(ra) # 80003a92 <itrunc>
    ip->type = 0;
    80003bb8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	cfc080e7          	jalr	-772(ra) # 800038ba <iupdate>
    ip->valid = 0;
    80003bc6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	acc080e7          	jalr	-1332(ra) # 80004698 <releasesleep>
    acquire(&icache.lock);
    80003bd4:	0001d517          	auipc	a0,0x1d
    80003bd8:	f8c50513          	addi	a0,a0,-116 # 80020b60 <icache>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	020080e7          	jalr	32(ra) # 80000bfc <acquire>
    80003be4:	b741                	j	80003b64 <iput+0x26>

0000000080003be6 <iunlockput>:
{
    80003be6:	1101                	addi	sp,sp,-32
    80003be8:	ec06                	sd	ra,24(sp)
    80003bea:	e822                	sd	s0,16(sp)
    80003bec:	e426                	sd	s1,8(sp)
    80003bee:	1000                	addi	s0,sp,32
    80003bf0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	e54080e7          	jalr	-428(ra) # 80003a46 <iunlock>
  iput(ip);
    80003bfa:	8526                	mv	a0,s1
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	f42080e7          	jalr	-190(ra) # 80003b3e <iput>
}
    80003c04:	60e2                	ld	ra,24(sp)
    80003c06:	6442                	ld	s0,16(sp)
    80003c08:	64a2                	ld	s1,8(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret

0000000080003c0e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c0e:	1141                	addi	sp,sp,-16
    80003c10:	e422                	sd	s0,8(sp)
    80003c12:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c14:	411c                	lw	a5,0(a0)
    80003c16:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c18:	415c                	lw	a5,4(a0)
    80003c1a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c1c:	04451783          	lh	a5,68(a0)
    80003c20:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c24:	04a51783          	lh	a5,74(a0)
    80003c28:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c2c:	04c56783          	lwu	a5,76(a0)
    80003c30:	e99c                	sd	a5,16(a1)
}
    80003c32:	6422                	ld	s0,8(sp)
    80003c34:	0141                	addi	sp,sp,16
    80003c36:	8082                	ret

0000000080003c38 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c38:	457c                	lw	a5,76(a0)
    80003c3a:	0ed7e863          	bltu	a5,a3,80003d2a <readi+0xf2>
{
    80003c3e:	7159                	addi	sp,sp,-112
    80003c40:	f486                	sd	ra,104(sp)
    80003c42:	f0a2                	sd	s0,96(sp)
    80003c44:	eca6                	sd	s1,88(sp)
    80003c46:	e8ca                	sd	s2,80(sp)
    80003c48:	e4ce                	sd	s3,72(sp)
    80003c4a:	e0d2                	sd	s4,64(sp)
    80003c4c:	fc56                	sd	s5,56(sp)
    80003c4e:	f85a                	sd	s6,48(sp)
    80003c50:	f45e                	sd	s7,40(sp)
    80003c52:	f062                	sd	s8,32(sp)
    80003c54:	ec66                	sd	s9,24(sp)
    80003c56:	e86a                	sd	s10,16(sp)
    80003c58:	e46e                	sd	s11,8(sp)
    80003c5a:	1880                	addi	s0,sp,112
    80003c5c:	8baa                	mv	s7,a0
    80003c5e:	8c2e                	mv	s8,a1
    80003c60:	8ab2                	mv	s5,a2
    80003c62:	84b6                	mv	s1,a3
    80003c64:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c66:	9f35                	addw	a4,a4,a3
    return 0;
    80003c68:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c6a:	08d76f63          	bltu	a4,a3,80003d08 <readi+0xd0>
  if(off + n > ip->size)
    80003c6e:	00e7f463          	bgeu	a5,a4,80003c76 <readi+0x3e>
    n = ip->size - off;
    80003c72:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c76:	0a0b0863          	beqz	s6,80003d26 <readi+0xee>
    80003c7a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c7c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c80:	5cfd                	li	s9,-1
    80003c82:	a82d                	j	80003cbc <readi+0x84>
    80003c84:	020a1d93          	slli	s11,s4,0x20
    80003c88:	020ddd93          	srli	s11,s11,0x20
    80003c8c:	05890793          	addi	a5,s2,88
    80003c90:	86ee                	mv	a3,s11
    80003c92:	963e                	add	a2,a2,a5
    80003c94:	85d6                	mv	a1,s5
    80003c96:	8562                	mv	a0,s8
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	ae8080e7          	jalr	-1304(ra) # 80002780 <either_copyout>
    80003ca0:	05950d63          	beq	a0,s9,80003cfa <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	60a080e7          	jalr	1546(ra) # 800032b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cae:	013a09bb          	addw	s3,s4,s3
    80003cb2:	009a04bb          	addw	s1,s4,s1
    80003cb6:	9aee                	add	s5,s5,s11
    80003cb8:	0569f663          	bgeu	s3,s6,80003d04 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cbc:	000ba903          	lw	s2,0(s7)
    80003cc0:	00a4d59b          	srliw	a1,s1,0xa
    80003cc4:	855e                	mv	a0,s7
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	8ae080e7          	jalr	-1874(ra) # 80003574 <bmap>
    80003cce:	0005059b          	sext.w	a1,a0
    80003cd2:	854a                	mv	a0,s2
    80003cd4:	fffff097          	auipc	ra,0xfffff
    80003cd8:	4ac080e7          	jalr	1196(ra) # 80003180 <bread>
    80003cdc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cde:	3ff4f613          	andi	a2,s1,1023
    80003ce2:	40cd07bb          	subw	a5,s10,a2
    80003ce6:	413b073b          	subw	a4,s6,s3
    80003cea:	8a3e                	mv	s4,a5
    80003cec:	2781                	sext.w	a5,a5
    80003cee:	0007069b          	sext.w	a3,a4
    80003cf2:	f8f6f9e3          	bgeu	a3,a5,80003c84 <readi+0x4c>
    80003cf6:	8a3a                	mv	s4,a4
    80003cf8:	b771                	j	80003c84 <readi+0x4c>
      brelse(bp);
    80003cfa:	854a                	mv	a0,s2
    80003cfc:	fffff097          	auipc	ra,0xfffff
    80003d00:	5b4080e7          	jalr	1460(ra) # 800032b0 <brelse>
  }
  return tot;
    80003d04:	0009851b          	sext.w	a0,s3
}
    80003d08:	70a6                	ld	ra,104(sp)
    80003d0a:	7406                	ld	s0,96(sp)
    80003d0c:	64e6                	ld	s1,88(sp)
    80003d0e:	6946                	ld	s2,80(sp)
    80003d10:	69a6                	ld	s3,72(sp)
    80003d12:	6a06                	ld	s4,64(sp)
    80003d14:	7ae2                	ld	s5,56(sp)
    80003d16:	7b42                	ld	s6,48(sp)
    80003d18:	7ba2                	ld	s7,40(sp)
    80003d1a:	7c02                	ld	s8,32(sp)
    80003d1c:	6ce2                	ld	s9,24(sp)
    80003d1e:	6d42                	ld	s10,16(sp)
    80003d20:	6da2                	ld	s11,8(sp)
    80003d22:	6165                	addi	sp,sp,112
    80003d24:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d26:	89da                	mv	s3,s6
    80003d28:	bff1                	j	80003d04 <readi+0xcc>
    return 0;
    80003d2a:	4501                	li	a0,0
}
    80003d2c:	8082                	ret

0000000080003d2e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d2e:	457c                	lw	a5,76(a0)
    80003d30:	10d7e663          	bltu	a5,a3,80003e3c <writei+0x10e>
{
    80003d34:	7159                	addi	sp,sp,-112
    80003d36:	f486                	sd	ra,104(sp)
    80003d38:	f0a2                	sd	s0,96(sp)
    80003d3a:	eca6                	sd	s1,88(sp)
    80003d3c:	e8ca                	sd	s2,80(sp)
    80003d3e:	e4ce                	sd	s3,72(sp)
    80003d40:	e0d2                	sd	s4,64(sp)
    80003d42:	fc56                	sd	s5,56(sp)
    80003d44:	f85a                	sd	s6,48(sp)
    80003d46:	f45e                	sd	s7,40(sp)
    80003d48:	f062                	sd	s8,32(sp)
    80003d4a:	ec66                	sd	s9,24(sp)
    80003d4c:	e86a                	sd	s10,16(sp)
    80003d4e:	e46e                	sd	s11,8(sp)
    80003d50:	1880                	addi	s0,sp,112
    80003d52:	8baa                	mv	s7,a0
    80003d54:	8c2e                	mv	s8,a1
    80003d56:	8ab2                	mv	s5,a2
    80003d58:	8936                	mv	s2,a3
    80003d5a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d5c:	00e687bb          	addw	a5,a3,a4
    80003d60:	0ed7e063          	bltu	a5,a3,80003e40 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d64:	00043737          	lui	a4,0x43
    80003d68:	0cf76e63          	bltu	a4,a5,80003e44 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6c:	0a0b0763          	beqz	s6,80003e1a <writei+0xec>
    80003d70:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d72:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d76:	5cfd                	li	s9,-1
    80003d78:	a091                	j	80003dbc <writei+0x8e>
    80003d7a:	02099d93          	slli	s11,s3,0x20
    80003d7e:	020ddd93          	srli	s11,s11,0x20
    80003d82:	05848793          	addi	a5,s1,88
    80003d86:	86ee                	mv	a3,s11
    80003d88:	8656                	mv	a2,s5
    80003d8a:	85e2                	mv	a1,s8
    80003d8c:	953e                	add	a0,a0,a5
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	a48080e7          	jalr	-1464(ra) # 800027d6 <either_copyin>
    80003d96:	07950263          	beq	a0,s9,80003dfa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d9a:	8526                	mv	a0,s1
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	77e080e7          	jalr	1918(ra) # 8000451a <log_write>
    brelse(bp);
    80003da4:	8526                	mv	a0,s1
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	50a080e7          	jalr	1290(ra) # 800032b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dae:	01498a3b          	addw	s4,s3,s4
    80003db2:	0129893b          	addw	s2,s3,s2
    80003db6:	9aee                	add	s5,s5,s11
    80003db8:	056a7663          	bgeu	s4,s6,80003e04 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dbc:	000ba483          	lw	s1,0(s7)
    80003dc0:	00a9559b          	srliw	a1,s2,0xa
    80003dc4:	855e                	mv	a0,s7
    80003dc6:	fffff097          	auipc	ra,0xfffff
    80003dca:	7ae080e7          	jalr	1966(ra) # 80003574 <bmap>
    80003dce:	0005059b          	sext.w	a1,a0
    80003dd2:	8526                	mv	a0,s1
    80003dd4:	fffff097          	auipc	ra,0xfffff
    80003dd8:	3ac080e7          	jalr	940(ra) # 80003180 <bread>
    80003ddc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dde:	3ff97513          	andi	a0,s2,1023
    80003de2:	40ad07bb          	subw	a5,s10,a0
    80003de6:	414b073b          	subw	a4,s6,s4
    80003dea:	89be                	mv	s3,a5
    80003dec:	2781                	sext.w	a5,a5
    80003dee:	0007069b          	sext.w	a3,a4
    80003df2:	f8f6f4e3          	bgeu	a3,a5,80003d7a <writei+0x4c>
    80003df6:	89ba                	mv	s3,a4
    80003df8:	b749                	j	80003d7a <writei+0x4c>
      brelse(bp);
    80003dfa:	8526                	mv	a0,s1
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	4b4080e7          	jalr	1204(ra) # 800032b0 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e04:	04cba783          	lw	a5,76(s7)
    80003e08:	0127f463          	bgeu	a5,s2,80003e10 <writei+0xe2>
      ip->size = off;
    80003e0c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e10:	855e                	mv	a0,s7
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	aa8080e7          	jalr	-1368(ra) # 800038ba <iupdate>
  }

  return n;
    80003e1a:	000b051b          	sext.w	a0,s6
}
    80003e1e:	70a6                	ld	ra,104(sp)
    80003e20:	7406                	ld	s0,96(sp)
    80003e22:	64e6                	ld	s1,88(sp)
    80003e24:	6946                	ld	s2,80(sp)
    80003e26:	69a6                	ld	s3,72(sp)
    80003e28:	6a06                	ld	s4,64(sp)
    80003e2a:	7ae2                	ld	s5,56(sp)
    80003e2c:	7b42                	ld	s6,48(sp)
    80003e2e:	7ba2                	ld	s7,40(sp)
    80003e30:	7c02                	ld	s8,32(sp)
    80003e32:	6ce2                	ld	s9,24(sp)
    80003e34:	6d42                	ld	s10,16(sp)
    80003e36:	6da2                	ld	s11,8(sp)
    80003e38:	6165                	addi	sp,sp,112
    80003e3a:	8082                	ret
    return -1;
    80003e3c:	557d                	li	a0,-1
}
    80003e3e:	8082                	ret
    return -1;
    80003e40:	557d                	li	a0,-1
    80003e42:	bff1                	j	80003e1e <writei+0xf0>
    return -1;
    80003e44:	557d                	li	a0,-1
    80003e46:	bfe1                	j	80003e1e <writei+0xf0>

0000000080003e48 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e48:	1141                	addi	sp,sp,-16
    80003e4a:	e406                	sd	ra,8(sp)
    80003e4c:	e022                	sd	s0,0(sp)
    80003e4e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e50:	4639                	li	a2,14
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	f7e080e7          	jalr	-130(ra) # 80000dd0 <strncmp>
}
    80003e5a:	60a2                	ld	ra,8(sp)
    80003e5c:	6402                	ld	s0,0(sp)
    80003e5e:	0141                	addi	sp,sp,16
    80003e60:	8082                	ret

0000000080003e62 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e62:	7139                	addi	sp,sp,-64
    80003e64:	fc06                	sd	ra,56(sp)
    80003e66:	f822                	sd	s0,48(sp)
    80003e68:	f426                	sd	s1,40(sp)
    80003e6a:	f04a                	sd	s2,32(sp)
    80003e6c:	ec4e                	sd	s3,24(sp)
    80003e6e:	e852                	sd	s4,16(sp)
    80003e70:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e72:	04451703          	lh	a4,68(a0)
    80003e76:	4785                	li	a5,1
    80003e78:	00f71a63          	bne	a4,a5,80003e8c <dirlookup+0x2a>
    80003e7c:	892a                	mv	s2,a0
    80003e7e:	89ae                	mv	s3,a1
    80003e80:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	457c                	lw	a5,76(a0)
    80003e84:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e86:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	e79d                	bnez	a5,80003eb6 <dirlookup+0x54>
    80003e8a:	a8a5                	j	80003f02 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e8c:	00004517          	auipc	a0,0x4
    80003e90:	79c50513          	addi	a0,a0,1948 # 80008628 <syscalls+0x1a0>
    80003e94:	ffffc097          	auipc	ra,0xffffc
    80003e98:	6ac080e7          	jalr	1708(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e9c:	00004517          	auipc	a0,0x4
    80003ea0:	7a450513          	addi	a0,a0,1956 # 80008640 <syscalls+0x1b8>
    80003ea4:	ffffc097          	auipc	ra,0xffffc
    80003ea8:	69c080e7          	jalr	1692(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eac:	24c1                	addiw	s1,s1,16
    80003eae:	04c92783          	lw	a5,76(s2)
    80003eb2:	04f4f763          	bgeu	s1,a5,80003f00 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb6:	4741                	li	a4,16
    80003eb8:	86a6                	mv	a3,s1
    80003eba:	fc040613          	addi	a2,s0,-64
    80003ebe:	4581                	li	a1,0
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	d76080e7          	jalr	-650(ra) # 80003c38 <readi>
    80003eca:	47c1                	li	a5,16
    80003ecc:	fcf518e3          	bne	a0,a5,80003e9c <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed0:	fc045783          	lhu	a5,-64(s0)
    80003ed4:	dfe1                	beqz	a5,80003eac <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed6:	fc240593          	addi	a1,s0,-62
    80003eda:	854e                	mv	a0,s3
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	f6c080e7          	jalr	-148(ra) # 80003e48 <namecmp>
    80003ee4:	f561                	bnez	a0,80003eac <dirlookup+0x4a>
      if(poff)
    80003ee6:	000a0463          	beqz	s4,80003eee <dirlookup+0x8c>
        *poff = off;
    80003eea:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eee:	fc045583          	lhu	a1,-64(s0)
    80003ef2:	00092503          	lw	a0,0(s2)
    80003ef6:	fffff097          	auipc	ra,0xfffff
    80003efa:	75a080e7          	jalr	1882(ra) # 80003650 <iget>
    80003efe:	a011                	j	80003f02 <dirlookup+0xa0>
  return 0;
    80003f00:	4501                	li	a0,0
}
    80003f02:	70e2                	ld	ra,56(sp)
    80003f04:	7442                	ld	s0,48(sp)
    80003f06:	74a2                	ld	s1,40(sp)
    80003f08:	7902                	ld	s2,32(sp)
    80003f0a:	69e2                	ld	s3,24(sp)
    80003f0c:	6a42                	ld	s4,16(sp)
    80003f0e:	6121                	addi	sp,sp,64
    80003f10:	8082                	ret

0000000080003f12 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f12:	711d                	addi	sp,sp,-96
    80003f14:	ec86                	sd	ra,88(sp)
    80003f16:	e8a2                	sd	s0,80(sp)
    80003f18:	e4a6                	sd	s1,72(sp)
    80003f1a:	e0ca                	sd	s2,64(sp)
    80003f1c:	fc4e                	sd	s3,56(sp)
    80003f1e:	f852                	sd	s4,48(sp)
    80003f20:	f456                	sd	s5,40(sp)
    80003f22:	f05a                	sd	s6,32(sp)
    80003f24:	ec5e                	sd	s7,24(sp)
    80003f26:	e862                	sd	s8,16(sp)
    80003f28:	e466                	sd	s9,8(sp)
    80003f2a:	1080                	addi	s0,sp,96
    80003f2c:	84aa                	mv	s1,a0
    80003f2e:	8aae                	mv	s5,a1
    80003f30:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f32:	00054703          	lbu	a4,0(a0)
    80003f36:	02f00793          	li	a5,47
    80003f3a:	02f70363          	beq	a4,a5,80003f60 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f3e:	ffffe097          	auipc	ra,0xffffe
    80003f42:	bee080e7          	jalr	-1042(ra) # 80001b2c <myproc>
    80003f46:	15053503          	ld	a0,336(a0)
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	9fc080e7          	jalr	-1540(ra) # 80003946 <idup>
    80003f52:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f54:	02f00913          	li	s2,47
  len = path - s;
    80003f58:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f5a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f5c:	4b85                	li	s7,1
    80003f5e:	a865                	j	80004016 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f60:	4585                	li	a1,1
    80003f62:	4505                	li	a0,1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	6ec080e7          	jalr	1772(ra) # 80003650 <iget>
    80003f6c:	89aa                	mv	s3,a0
    80003f6e:	b7dd                	j	80003f54 <namex+0x42>
      iunlockput(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	c74080e7          	jalr	-908(ra) # 80003be6 <iunlockput>
      return 0;
    80003f7a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f7c:	854e                	mv	a0,s3
    80003f7e:	60e6                	ld	ra,88(sp)
    80003f80:	6446                	ld	s0,80(sp)
    80003f82:	64a6                	ld	s1,72(sp)
    80003f84:	6906                	ld	s2,64(sp)
    80003f86:	79e2                	ld	s3,56(sp)
    80003f88:	7a42                	ld	s4,48(sp)
    80003f8a:	7aa2                	ld	s5,40(sp)
    80003f8c:	7b02                	ld	s6,32(sp)
    80003f8e:	6be2                	ld	s7,24(sp)
    80003f90:	6c42                	ld	s8,16(sp)
    80003f92:	6ca2                	ld	s9,8(sp)
    80003f94:	6125                	addi	sp,sp,96
    80003f96:	8082                	ret
      iunlock(ip);
    80003f98:	854e                	mv	a0,s3
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	aac080e7          	jalr	-1364(ra) # 80003a46 <iunlock>
      return ip;
    80003fa2:	bfe9                	j	80003f7c <namex+0x6a>
      iunlockput(ip);
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	c40080e7          	jalr	-960(ra) # 80003be6 <iunlockput>
      return 0;
    80003fae:	89e6                	mv	s3,s9
    80003fb0:	b7f1                	j	80003f7c <namex+0x6a>
  len = path - s;
    80003fb2:	40b48633          	sub	a2,s1,a1
    80003fb6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fba:	099c5463          	bge	s8,s9,80004042 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fbe:	4639                	li	a2,14
    80003fc0:	8552                	mv	a0,s4
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	d92080e7          	jalr	-622(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	01279763          	bne	a5,s2,80003fdc <namex+0xca>
    path++;
    80003fd2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd4:	0004c783          	lbu	a5,0(s1)
    80003fd8:	ff278de3          	beq	a5,s2,80003fd2 <namex+0xc0>
    ilock(ip);
    80003fdc:	854e                	mv	a0,s3
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	9a6080e7          	jalr	-1626(ra) # 80003984 <ilock>
    if(ip->type != T_DIR){
    80003fe6:	04499783          	lh	a5,68(s3)
    80003fea:	f97793e3          	bne	a5,s7,80003f70 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fee:	000a8563          	beqz	s5,80003ff8 <namex+0xe6>
    80003ff2:	0004c783          	lbu	a5,0(s1)
    80003ff6:	d3cd                	beqz	a5,80003f98 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff8:	865a                	mv	a2,s6
    80003ffa:	85d2                	mv	a1,s4
    80003ffc:	854e                	mv	a0,s3
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	e64080e7          	jalr	-412(ra) # 80003e62 <dirlookup>
    80004006:	8caa                	mv	s9,a0
    80004008:	dd51                	beqz	a0,80003fa4 <namex+0x92>
    iunlockput(ip);
    8000400a:	854e                	mv	a0,s3
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	bda080e7          	jalr	-1062(ra) # 80003be6 <iunlockput>
    ip = next;
    80004014:	89e6                	mv	s3,s9
  while(*path == '/')
    80004016:	0004c783          	lbu	a5,0(s1)
    8000401a:	05279763          	bne	a5,s2,80004068 <namex+0x156>
    path++;
    8000401e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004020:	0004c783          	lbu	a5,0(s1)
    80004024:	ff278de3          	beq	a5,s2,8000401e <namex+0x10c>
  if(*path == 0)
    80004028:	c79d                	beqz	a5,80004056 <namex+0x144>
    path++;
    8000402a:	85a6                	mv	a1,s1
  len = path - s;
    8000402c:	8cda                	mv	s9,s6
    8000402e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004030:	01278963          	beq	a5,s2,80004042 <namex+0x130>
    80004034:	dfbd                	beqz	a5,80003fb2 <namex+0xa0>
    path++;
    80004036:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004038:	0004c783          	lbu	a5,0(s1)
    8000403c:	ff279ce3          	bne	a5,s2,80004034 <namex+0x122>
    80004040:	bf8d                	j	80003fb2 <namex+0xa0>
    memmove(name, s, len);
    80004042:	2601                	sext.w	a2,a2
    80004044:	8552                	mv	a0,s4
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	d0e080e7          	jalr	-754(ra) # 80000d54 <memmove>
    name[len] = 0;
    8000404e:	9cd2                	add	s9,s9,s4
    80004050:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004054:	bf9d                	j	80003fca <namex+0xb8>
  if(nameiparent){
    80004056:	f20a83e3          	beqz	s5,80003f7c <namex+0x6a>
    iput(ip);
    8000405a:	854e                	mv	a0,s3
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	ae2080e7          	jalr	-1310(ra) # 80003b3e <iput>
    return 0;
    80004064:	4981                	li	s3,0
    80004066:	bf19                	j	80003f7c <namex+0x6a>
  if(*path == 0)
    80004068:	d7fd                	beqz	a5,80004056 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000406a:	0004c783          	lbu	a5,0(s1)
    8000406e:	85a6                	mv	a1,s1
    80004070:	b7d1                	j	80004034 <namex+0x122>

0000000080004072 <dirlink>:
{
    80004072:	7139                	addi	sp,sp,-64
    80004074:	fc06                	sd	ra,56(sp)
    80004076:	f822                	sd	s0,48(sp)
    80004078:	f426                	sd	s1,40(sp)
    8000407a:	f04a                	sd	s2,32(sp)
    8000407c:	ec4e                	sd	s3,24(sp)
    8000407e:	e852                	sd	s4,16(sp)
    80004080:	0080                	addi	s0,sp,64
    80004082:	892a                	mv	s2,a0
    80004084:	8a2e                	mv	s4,a1
    80004086:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004088:	4601                	li	a2,0
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	dd8080e7          	jalr	-552(ra) # 80003e62 <dirlookup>
    80004092:	e93d                	bnez	a0,80004108 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	04c92483          	lw	s1,76(s2)
    80004098:	c49d                	beqz	s1,800040c6 <dirlink+0x54>
    8000409a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409c:	4741                	li	a4,16
    8000409e:	86a6                	mv	a3,s1
    800040a0:	fc040613          	addi	a2,s0,-64
    800040a4:	4581                	li	a1,0
    800040a6:	854a                	mv	a0,s2
    800040a8:	00000097          	auipc	ra,0x0
    800040ac:	b90080e7          	jalr	-1136(ra) # 80003c38 <readi>
    800040b0:	47c1                	li	a5,16
    800040b2:	06f51163          	bne	a0,a5,80004114 <dirlink+0xa2>
    if(de.inum == 0)
    800040b6:	fc045783          	lhu	a5,-64(s0)
    800040ba:	c791                	beqz	a5,800040c6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040bc:	24c1                	addiw	s1,s1,16
    800040be:	04c92783          	lw	a5,76(s2)
    800040c2:	fcf4ede3          	bltu	s1,a5,8000409c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c6:	4639                	li	a2,14
    800040c8:	85d2                	mv	a1,s4
    800040ca:	fc240513          	addi	a0,s0,-62
    800040ce:	ffffd097          	auipc	ra,0xffffd
    800040d2:	d3e080e7          	jalr	-706(ra) # 80000e0c <strncpy>
  de.inum = inum;
    800040d6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040da:	4741                	li	a4,16
    800040dc:	86a6                	mv	a3,s1
    800040de:	fc040613          	addi	a2,s0,-64
    800040e2:	4581                	li	a1,0
    800040e4:	854a                	mv	a0,s2
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	c48080e7          	jalr	-952(ra) # 80003d2e <writei>
    800040ee:	872a                	mv	a4,a0
    800040f0:	47c1                	li	a5,16
  return 0;
    800040f2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f4:	02f71863          	bne	a4,a5,80004124 <dirlink+0xb2>
}
    800040f8:	70e2                	ld	ra,56(sp)
    800040fa:	7442                	ld	s0,48(sp)
    800040fc:	74a2                	ld	s1,40(sp)
    800040fe:	7902                	ld	s2,32(sp)
    80004100:	69e2                	ld	s3,24(sp)
    80004102:	6a42                	ld	s4,16(sp)
    80004104:	6121                	addi	sp,sp,64
    80004106:	8082                	ret
    iput(ip);
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	a36080e7          	jalr	-1482(ra) # 80003b3e <iput>
    return -1;
    80004110:	557d                	li	a0,-1
    80004112:	b7dd                	j	800040f8 <dirlink+0x86>
      panic("dirlink read");
    80004114:	00004517          	auipc	a0,0x4
    80004118:	53c50513          	addi	a0,a0,1340 # 80008650 <syscalls+0x1c8>
    8000411c:	ffffc097          	auipc	ra,0xffffc
    80004120:	424080e7          	jalr	1060(ra) # 80000540 <panic>
    panic("dirlink");
    80004124:	00004517          	auipc	a0,0x4
    80004128:	64c50513          	addi	a0,a0,1612 # 80008770 <syscalls+0x2e8>
    8000412c:	ffffc097          	auipc	ra,0xffffc
    80004130:	414080e7          	jalr	1044(ra) # 80000540 <panic>

0000000080004134 <namei>:

struct inode*
namei(char *path)
{
    80004134:	1101                	addi	sp,sp,-32
    80004136:	ec06                	sd	ra,24(sp)
    80004138:	e822                	sd	s0,16(sp)
    8000413a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000413c:	fe040613          	addi	a2,s0,-32
    80004140:	4581                	li	a1,0
    80004142:	00000097          	auipc	ra,0x0
    80004146:	dd0080e7          	jalr	-560(ra) # 80003f12 <namex>
}
    8000414a:	60e2                	ld	ra,24(sp)
    8000414c:	6442                	ld	s0,16(sp)
    8000414e:	6105                	addi	sp,sp,32
    80004150:	8082                	ret

0000000080004152 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004152:	1141                	addi	sp,sp,-16
    80004154:	e406                	sd	ra,8(sp)
    80004156:	e022                	sd	s0,0(sp)
    80004158:	0800                	addi	s0,sp,16
    8000415a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000415c:	4585                	li	a1,1
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	db4080e7          	jalr	-588(ra) # 80003f12 <namex>
}
    80004166:	60a2                	ld	ra,8(sp)
    80004168:	6402                	ld	s0,0(sp)
    8000416a:	0141                	addi	sp,sp,16
    8000416c:	8082                	ret

000000008000416e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000416e:	1101                	addi	sp,sp,-32
    80004170:	ec06                	sd	ra,24(sp)
    80004172:	e822                	sd	s0,16(sp)
    80004174:	e426                	sd	s1,8(sp)
    80004176:	e04a                	sd	s2,0(sp)
    80004178:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000417a:	0001e917          	auipc	s2,0x1e
    8000417e:	48e90913          	addi	s2,s2,1166 # 80022608 <log>
    80004182:	01892583          	lw	a1,24(s2)
    80004186:	02892503          	lw	a0,40(s2)
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	ff6080e7          	jalr	-10(ra) # 80003180 <bread>
    80004192:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004194:	02c92683          	lw	a3,44(s2)
    80004198:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000419a:	02d05863          	blez	a3,800041ca <write_head+0x5c>
    8000419e:	0001e797          	auipc	a5,0x1e
    800041a2:	49a78793          	addi	a5,a5,1178 # 80022638 <log+0x30>
    800041a6:	05c50713          	addi	a4,a0,92
    800041aa:	36fd                	addiw	a3,a3,-1
    800041ac:	02069613          	slli	a2,a3,0x20
    800041b0:	01e65693          	srli	a3,a2,0x1e
    800041b4:	0001e617          	auipc	a2,0x1e
    800041b8:	48860613          	addi	a2,a2,1160 # 8002263c <log+0x34>
    800041bc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041be:	4390                	lw	a2,0(a5)
    800041c0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	0791                	addi	a5,a5,4
    800041c4:	0711                	addi	a4,a4,4
    800041c6:	fed79ce3          	bne	a5,a3,800041be <write_head+0x50>
  }
  bwrite(buf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	0a6080e7          	jalr	166(ra) # 80003272 <bwrite>
  brelse(buf);
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	0da080e7          	jalr	218(ra) # 800032b0 <brelse>
}
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6902                	ld	s2,0(sp)
    800041e6:	6105                	addi	sp,sp,32
    800041e8:	8082                	ret

00000000800041ea <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ea:	0001e797          	auipc	a5,0x1e
    800041ee:	44a7a783          	lw	a5,1098(a5) # 80022634 <log+0x2c>
    800041f2:	0af05663          	blez	a5,8000429e <install_trans+0xb4>
{
    800041f6:	7139                	addi	sp,sp,-64
    800041f8:	fc06                	sd	ra,56(sp)
    800041fa:	f822                	sd	s0,48(sp)
    800041fc:	f426                	sd	s1,40(sp)
    800041fe:	f04a                	sd	s2,32(sp)
    80004200:	ec4e                	sd	s3,24(sp)
    80004202:	e852                	sd	s4,16(sp)
    80004204:	e456                	sd	s5,8(sp)
    80004206:	0080                	addi	s0,sp,64
    80004208:	0001ea97          	auipc	s5,0x1e
    8000420c:	430a8a93          	addi	s5,s5,1072 # 80022638 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004210:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004212:	0001e997          	auipc	s3,0x1e
    80004216:	3f698993          	addi	s3,s3,1014 # 80022608 <log>
    8000421a:	0189a583          	lw	a1,24(s3)
    8000421e:	014585bb          	addw	a1,a1,s4
    80004222:	2585                	addiw	a1,a1,1
    80004224:	0289a503          	lw	a0,40(s3)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	f58080e7          	jalr	-168(ra) # 80003180 <bread>
    80004230:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004232:	000aa583          	lw	a1,0(s5)
    80004236:	0289a503          	lw	a0,40(s3)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	f46080e7          	jalr	-186(ra) # 80003180 <bread>
    80004242:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004244:	40000613          	li	a2,1024
    80004248:	05890593          	addi	a1,s2,88
    8000424c:	05850513          	addi	a0,a0,88
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	b04080e7          	jalr	-1276(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	018080e7          	jalr	24(ra) # 80003272 <bwrite>
    bunpin(dbuf);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	126080e7          	jalr	294(ra) # 8000338a <bunpin>
    brelse(lbuf);
    8000426c:	854a                	mv	a0,s2
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	042080e7          	jalr	66(ra) # 800032b0 <brelse>
    brelse(dbuf);
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	038080e7          	jalr	56(ra) # 800032b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004280:	2a05                	addiw	s4,s4,1
    80004282:	0a91                	addi	s5,s5,4
    80004284:	02c9a783          	lw	a5,44(s3)
    80004288:	f8fa49e3          	blt	s4,a5,8000421a <install_trans+0x30>
}
    8000428c:	70e2                	ld	ra,56(sp)
    8000428e:	7442                	ld	s0,48(sp)
    80004290:	74a2                	ld	s1,40(sp)
    80004292:	7902                	ld	s2,32(sp)
    80004294:	69e2                	ld	s3,24(sp)
    80004296:	6a42                	ld	s4,16(sp)
    80004298:	6aa2                	ld	s5,8(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret
    8000429e:	8082                	ret

00000000800042a0 <initlog>:
{
    800042a0:	7179                	addi	sp,sp,-48
    800042a2:	f406                	sd	ra,40(sp)
    800042a4:	f022                	sd	s0,32(sp)
    800042a6:	ec26                	sd	s1,24(sp)
    800042a8:	e84a                	sd	s2,16(sp)
    800042aa:	e44e                	sd	s3,8(sp)
    800042ac:	1800                	addi	s0,sp,48
    800042ae:	892a                	mv	s2,a0
    800042b0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b2:	0001e497          	auipc	s1,0x1e
    800042b6:	35648493          	addi	s1,s1,854 # 80022608 <log>
    800042ba:	00004597          	auipc	a1,0x4
    800042be:	3a658593          	addi	a1,a1,934 # 80008660 <syscalls+0x1d8>
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	8a8080e7          	jalr	-1880(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800042cc:	0149a583          	lw	a1,20(s3)
    800042d0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d2:	0109a783          	lw	a5,16(s3)
    800042d6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042dc:	854a                	mv	a0,s2
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	ea2080e7          	jalr	-350(ra) # 80003180 <bread>
  log.lh.n = lh->n;
    800042e6:	4d34                	lw	a3,88(a0)
    800042e8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ea:	02d05663          	blez	a3,80004316 <initlog+0x76>
    800042ee:	05c50793          	addi	a5,a0,92
    800042f2:	0001e717          	auipc	a4,0x1e
    800042f6:	34670713          	addi	a4,a4,838 # 80022638 <log+0x30>
    800042fa:	36fd                	addiw	a3,a3,-1
    800042fc:	02069613          	slli	a2,a3,0x20
    80004300:	01e65693          	srli	a3,a2,0x1e
    80004304:	06050613          	addi	a2,a0,96
    80004308:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000430a:	4390                	lw	a2,0(a5)
    8000430c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	0791                	addi	a5,a5,4
    80004310:	0711                	addi	a4,a4,4
    80004312:	fed79ce3          	bne	a5,a3,8000430a <initlog+0x6a>
  brelse(buf);
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	f9a080e7          	jalr	-102(ra) # 800032b0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	ecc080e7          	jalr	-308(ra) # 800041ea <install_trans>
  log.lh.n = 0;
    80004326:	0001e797          	auipc	a5,0x1e
    8000432a:	3007a723          	sw	zero,782(a5) # 80022634 <log+0x2c>
  write_head(); // clear the log
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	e40080e7          	jalr	-448(ra) # 8000416e <write_head>
}
    80004336:	70a2                	ld	ra,40(sp)
    80004338:	7402                	ld	s0,32(sp)
    8000433a:	64e2                	ld	s1,24(sp)
    8000433c:	6942                	ld	s2,16(sp)
    8000433e:	69a2                	ld	s3,8(sp)
    80004340:	6145                	addi	sp,sp,48
    80004342:	8082                	ret

0000000080004344 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004344:	1101                	addi	sp,sp,-32
    80004346:	ec06                	sd	ra,24(sp)
    80004348:	e822                	sd	s0,16(sp)
    8000434a:	e426                	sd	s1,8(sp)
    8000434c:	e04a                	sd	s2,0(sp)
    8000434e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004350:	0001e517          	auipc	a0,0x1e
    80004354:	2b850513          	addi	a0,a0,696 # 80022608 <log>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	8a4080e7          	jalr	-1884(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004360:	0001e497          	auipc	s1,0x1e
    80004364:	2a848493          	addi	s1,s1,680 # 80022608 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004368:	4979                	li	s2,30
    8000436a:	a039                	j	80004378 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000436c:	85a6                	mv	a1,s1
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	180080e7          	jalr	384(ra) # 800024f0 <sleep>
    if(log.committing){
    80004378:	50dc                	lw	a5,36(s1)
    8000437a:	fbed                	bnez	a5,8000436c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437c:	509c                	lw	a5,32(s1)
    8000437e:	0017871b          	addiw	a4,a5,1
    80004382:	0007069b          	sext.w	a3,a4
    80004386:	0027179b          	slliw	a5,a4,0x2
    8000438a:	9fb9                	addw	a5,a5,a4
    8000438c:	0017979b          	slliw	a5,a5,0x1
    80004390:	54d8                	lw	a4,44(s1)
    80004392:	9fb9                	addw	a5,a5,a4
    80004394:	00f95963          	bge	s2,a5,800043a6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004398:	85a6                	mv	a1,s1
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffe097          	auipc	ra,0xffffe
    800043a0:	154080e7          	jalr	340(ra) # 800024f0 <sleep>
    800043a4:	bfd1                	j	80004378 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a6:	0001e517          	auipc	a0,0x1e
    800043aa:	26250513          	addi	a0,a0,610 # 80022608 <log>
    800043ae:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	900080e7          	jalr	-1792(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	64a2                	ld	s1,8(sp)
    800043be:	6902                	ld	s2,0(sp)
    800043c0:	6105                	addi	sp,sp,32
    800043c2:	8082                	ret

00000000800043c4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c4:	7139                	addi	sp,sp,-64
    800043c6:	fc06                	sd	ra,56(sp)
    800043c8:	f822                	sd	s0,48(sp)
    800043ca:	f426                	sd	s1,40(sp)
    800043cc:	f04a                	sd	s2,32(sp)
    800043ce:	ec4e                	sd	s3,24(sp)
    800043d0:	e852                	sd	s4,16(sp)
    800043d2:	e456                	sd	s5,8(sp)
    800043d4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d6:	0001e497          	auipc	s1,0x1e
    800043da:	23248493          	addi	s1,s1,562 # 80022608 <log>
    800043de:	8526                	mv	a0,s1
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	81c080e7          	jalr	-2020(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800043e8:	509c                	lw	a5,32(s1)
    800043ea:	37fd                	addiw	a5,a5,-1
    800043ec:	0007891b          	sext.w	s2,a5
    800043f0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f2:	50dc                	lw	a5,36(s1)
    800043f4:	e7b9                	bnez	a5,80004442 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f6:	04091e63          	bnez	s2,80004452 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043fa:	0001e497          	auipc	s1,0x1e
    800043fe:	20e48493          	addi	s1,s1,526 # 80022608 <log>
    80004402:	4785                	li	a5,1
    80004404:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004406:	8526                	mv	a0,s1
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	8a8080e7          	jalr	-1880(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004410:	54dc                	lw	a5,44(s1)
    80004412:	06f04763          	bgtz	a5,80004480 <end_op+0xbc>
    acquire(&log.lock);
    80004416:	0001e497          	auipc	s1,0x1e
    8000441a:	1f248493          	addi	s1,s1,498 # 80022608 <log>
    8000441e:	8526                	mv	a0,s1
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7dc080e7          	jalr	2012(ra) # 80000bfc <acquire>
    log.committing = 0;
    80004428:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000442c:	8526                	mv	a0,s1
    8000442e:	ffffe097          	auipc	ra,0xffffe
    80004432:	25c080e7          	jalr	604(ra) # 8000268a <wakeup>
    release(&log.lock);
    80004436:	8526                	mv	a0,s1
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	878080e7          	jalr	-1928(ra) # 80000cb0 <release>
}
    80004440:	a03d                	j	8000446e <end_op+0xaa>
    panic("log.committing");
    80004442:	00004517          	auipc	a0,0x4
    80004446:	22650513          	addi	a0,a0,550 # 80008668 <syscalls+0x1e0>
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
    wakeup(&log);
    80004452:	0001e497          	auipc	s1,0x1e
    80004456:	1b648493          	addi	s1,s1,438 # 80022608 <log>
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffe097          	auipc	ra,0xffffe
    80004460:	22e080e7          	jalr	558(ra) # 8000268a <wakeup>
  release(&log.lock);
    80004464:	8526                	mv	a0,s1
    80004466:	ffffd097          	auipc	ra,0xffffd
    8000446a:	84a080e7          	jalr	-1974(ra) # 80000cb0 <release>
}
    8000446e:	70e2                	ld	ra,56(sp)
    80004470:	7442                	ld	s0,48(sp)
    80004472:	74a2                	ld	s1,40(sp)
    80004474:	7902                	ld	s2,32(sp)
    80004476:	69e2                	ld	s3,24(sp)
    80004478:	6a42                	ld	s4,16(sp)
    8000447a:	6aa2                	ld	s5,8(sp)
    8000447c:	6121                	addi	sp,sp,64
    8000447e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004480:	0001ea97          	auipc	s5,0x1e
    80004484:	1b8a8a93          	addi	s5,s5,440 # 80022638 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004488:	0001ea17          	auipc	s4,0x1e
    8000448c:	180a0a13          	addi	s4,s4,384 # 80022608 <log>
    80004490:	018a2583          	lw	a1,24(s4)
    80004494:	012585bb          	addw	a1,a1,s2
    80004498:	2585                	addiw	a1,a1,1
    8000449a:	028a2503          	lw	a0,40(s4)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	ce2080e7          	jalr	-798(ra) # 80003180 <bread>
    800044a6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a8:	000aa583          	lw	a1,0(s5)
    800044ac:	028a2503          	lw	a0,40(s4)
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	cd0080e7          	jalr	-816(ra) # 80003180 <bread>
    800044b8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ba:	40000613          	li	a2,1024
    800044be:	05850593          	addi	a1,a0,88
    800044c2:	05848513          	addi	a0,s1,88
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	88e080e7          	jalr	-1906(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800044ce:	8526                	mv	a0,s1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	da2080e7          	jalr	-606(ra) # 80003272 <bwrite>
    brelse(from);
    800044d8:	854e                	mv	a0,s3
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	dd6080e7          	jalr	-554(ra) # 800032b0 <brelse>
    brelse(to);
    800044e2:	8526                	mv	a0,s1
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	dcc080e7          	jalr	-564(ra) # 800032b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ec:	2905                	addiw	s2,s2,1
    800044ee:	0a91                	addi	s5,s5,4
    800044f0:	02ca2783          	lw	a5,44(s4)
    800044f4:	f8f94ee3          	blt	s2,a5,80004490 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f8:	00000097          	auipc	ra,0x0
    800044fc:	c76080e7          	jalr	-906(ra) # 8000416e <write_head>
    install_trans(); // Now install writes to home locations
    80004500:	00000097          	auipc	ra,0x0
    80004504:	cea080e7          	jalr	-790(ra) # 800041ea <install_trans>
    log.lh.n = 0;
    80004508:	0001e797          	auipc	a5,0x1e
    8000450c:	1207a623          	sw	zero,300(a5) # 80022634 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004510:	00000097          	auipc	ra,0x0
    80004514:	c5e080e7          	jalr	-930(ra) # 8000416e <write_head>
    80004518:	bdfd                	j	80004416 <end_op+0x52>

000000008000451a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451a:	1101                	addi	sp,sp,-32
    8000451c:	ec06                	sd	ra,24(sp)
    8000451e:	e822                	sd	s0,16(sp)
    80004520:	e426                	sd	s1,8(sp)
    80004522:	e04a                	sd	s2,0(sp)
    80004524:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004526:	0001e717          	auipc	a4,0x1e
    8000452a:	10e72703          	lw	a4,270(a4) # 80022634 <log+0x2c>
    8000452e:	47f5                	li	a5,29
    80004530:	08e7c063          	blt	a5,a4,800045b0 <log_write+0x96>
    80004534:	84aa                	mv	s1,a0
    80004536:	0001e797          	auipc	a5,0x1e
    8000453a:	0ee7a783          	lw	a5,238(a5) # 80022624 <log+0x1c>
    8000453e:	37fd                	addiw	a5,a5,-1
    80004540:	06f75863          	bge	a4,a5,800045b0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004544:	0001e797          	auipc	a5,0x1e
    80004548:	0e47a783          	lw	a5,228(a5) # 80022628 <log+0x20>
    8000454c:	06f05a63          	blez	a5,800045c0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004550:	0001e917          	auipc	s2,0x1e
    80004554:	0b890913          	addi	s2,s2,184 # 80022608 <log>
    80004558:	854a                	mv	a0,s2
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	6a2080e7          	jalr	1698(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004562:	02c92603          	lw	a2,44(s2)
    80004566:	06c05563          	blez	a2,800045d0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456a:	44cc                	lw	a1,12(s1)
    8000456c:	0001e717          	auipc	a4,0x1e
    80004570:	0cc70713          	addi	a4,a4,204 # 80022638 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004574:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004576:	4314                	lw	a3,0(a4)
    80004578:	04b68d63          	beq	a3,a1,800045d2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000457c:	2785                	addiw	a5,a5,1
    8000457e:	0711                	addi	a4,a4,4
    80004580:	fec79be3          	bne	a5,a2,80004576 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004584:	0621                	addi	a2,a2,8
    80004586:	060a                	slli	a2,a2,0x2
    80004588:	0001e797          	auipc	a5,0x1e
    8000458c:	08078793          	addi	a5,a5,128 # 80022608 <log>
    80004590:	963e                	add	a2,a2,a5
    80004592:	44dc                	lw	a5,12(s1)
    80004594:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004596:	8526                	mv	a0,s1
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	db6080e7          	jalr	-586(ra) # 8000334e <bpin>
    log.lh.n++;
    800045a0:	0001e717          	auipc	a4,0x1e
    800045a4:	06870713          	addi	a4,a4,104 # 80022608 <log>
    800045a8:	575c                	lw	a5,44(a4)
    800045aa:	2785                	addiw	a5,a5,1
    800045ac:	d75c                	sw	a5,44(a4)
    800045ae:	a83d                	j	800045ec <log_write+0xd2>
    panic("too big a transaction");
    800045b0:	00004517          	auipc	a0,0x4
    800045b4:	0c850513          	addi	a0,a0,200 # 80008678 <syscalls+0x1f0>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	f88080e7          	jalr	-120(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	0d050513          	addi	a0,a0,208 # 80008690 <syscalls+0x208>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f78080e7          	jalr	-136(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d2:	00878713          	addi	a4,a5,8
    800045d6:	00271693          	slli	a3,a4,0x2
    800045da:	0001e717          	auipc	a4,0x1e
    800045de:	02e70713          	addi	a4,a4,46 # 80022608 <log>
    800045e2:	9736                	add	a4,a4,a3
    800045e4:	44d4                	lw	a3,12(s1)
    800045e6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e8:	faf607e3          	beq	a2,a5,80004596 <log_write+0x7c>
  }
  release(&log.lock);
    800045ec:	0001e517          	auipc	a0,0x1e
    800045f0:	01c50513          	addi	a0,a0,28 # 80022608 <log>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	6bc080e7          	jalr	1724(ra) # 80000cb0 <release>
}
    800045fc:	60e2                	ld	ra,24(sp)
    800045fe:	6442                	ld	s0,16(sp)
    80004600:	64a2                	ld	s1,8(sp)
    80004602:	6902                	ld	s2,0(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	e04a                	sd	s2,0(sp)
    80004612:	1000                	addi	s0,sp,32
    80004614:	84aa                	mv	s1,a0
    80004616:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004618:	00004597          	auipc	a1,0x4
    8000461c:	09858593          	addi	a1,a1,152 # 800086b0 <syscalls+0x228>
    80004620:	0521                	addi	a0,a0,8
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	54a080e7          	jalr	1354(ra) # 80000b6c <initlock>
  lk->name = name;
    8000462a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000462e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004632:	0204a423          	sw	zero,40(s1)
}
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6902                	ld	s2,0(sp)
    8000463e:	6105                	addi	sp,sp,32
    80004640:	8082                	ret

0000000080004642 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004642:	1101                	addi	sp,sp,-32
    80004644:	ec06                	sd	ra,24(sp)
    80004646:	e822                	sd	s0,16(sp)
    80004648:	e426                	sd	s1,8(sp)
    8000464a:	e04a                	sd	s2,0(sp)
    8000464c:	1000                	addi	s0,sp,32
    8000464e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004650:	00850913          	addi	s2,a0,8
    80004654:	854a                	mv	a0,s2
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	5a6080e7          	jalr	1446(ra) # 80000bfc <acquire>
  while (lk->locked) {
    8000465e:	409c                	lw	a5,0(s1)
    80004660:	cb89                	beqz	a5,80004672 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004662:	85ca                	mv	a1,s2
    80004664:	8526                	mv	a0,s1
    80004666:	ffffe097          	auipc	ra,0xffffe
    8000466a:	e8a080e7          	jalr	-374(ra) # 800024f0 <sleep>
  while (lk->locked) {
    8000466e:	409c                	lw	a5,0(s1)
    80004670:	fbed                	bnez	a5,80004662 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004672:	4785                	li	a5,1
    80004674:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004676:	ffffd097          	auipc	ra,0xffffd
    8000467a:	4b6080e7          	jalr	1206(ra) # 80001b2c <myproc>
    8000467e:	5d1c                	lw	a5,56(a0)
    80004680:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	62c080e7          	jalr	1580(ra) # 80000cb0 <release>
}
    8000468c:	60e2                	ld	ra,24(sp)
    8000468e:	6442                	ld	s0,16(sp)
    80004690:	64a2                	ld	s1,8(sp)
    80004692:	6902                	ld	s2,0(sp)
    80004694:	6105                	addi	sp,sp,32
    80004696:	8082                	ret

0000000080004698 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004698:	1101                	addi	sp,sp,-32
    8000469a:	ec06                	sd	ra,24(sp)
    8000469c:	e822                	sd	s0,16(sp)
    8000469e:	e426                	sd	s1,8(sp)
    800046a0:	e04a                	sd	s2,0(sp)
    800046a2:	1000                	addi	s0,sp,32
    800046a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a6:	00850913          	addi	s2,a0,8
    800046aa:	854a                	mv	a0,s2
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	550080e7          	jalr	1360(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800046b4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046bc:	8526                	mv	a0,s1
    800046be:	ffffe097          	auipc	ra,0xffffe
    800046c2:	fcc080e7          	jalr	-52(ra) # 8000268a <wakeup>
  release(&lk->lk);
    800046c6:	854a                	mv	a0,s2
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5e8080e7          	jalr	1512(ra) # 80000cb0 <release>
}
    800046d0:	60e2                	ld	ra,24(sp)
    800046d2:	6442                	ld	s0,16(sp)
    800046d4:	64a2                	ld	s1,8(sp)
    800046d6:	6902                	ld	s2,0(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046dc:	7179                	addi	sp,sp,-48
    800046de:	f406                	sd	ra,40(sp)
    800046e0:	f022                	sd	s0,32(sp)
    800046e2:	ec26                	sd	s1,24(sp)
    800046e4:	e84a                	sd	s2,16(sp)
    800046e6:	e44e                	sd	s3,8(sp)
    800046e8:	1800                	addi	s0,sp,48
    800046ea:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ec:	00850913          	addi	s2,a0,8
    800046f0:	854a                	mv	a0,s2
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	50a080e7          	jalr	1290(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fa:	409c                	lw	a5,0(s1)
    800046fc:	ef99                	bnez	a5,8000471a <holdingsleep+0x3e>
    800046fe:	4481                	li	s1,0
  release(&lk->lk);
    80004700:	854a                	mv	a0,s2
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	5ae080e7          	jalr	1454(ra) # 80000cb0 <release>
  return r;
}
    8000470a:	8526                	mv	a0,s1
    8000470c:	70a2                	ld	ra,40(sp)
    8000470e:	7402                	ld	s0,32(sp)
    80004710:	64e2                	ld	s1,24(sp)
    80004712:	6942                	ld	s2,16(sp)
    80004714:	69a2                	ld	s3,8(sp)
    80004716:	6145                	addi	sp,sp,48
    80004718:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000471a:	0284a983          	lw	s3,40(s1)
    8000471e:	ffffd097          	auipc	ra,0xffffd
    80004722:	40e080e7          	jalr	1038(ra) # 80001b2c <myproc>
    80004726:	5d04                	lw	s1,56(a0)
    80004728:	413484b3          	sub	s1,s1,s3
    8000472c:	0014b493          	seqz	s1,s1
    80004730:	bfc1                	j	80004700 <holdingsleep+0x24>

0000000080004732 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004732:	1141                	addi	sp,sp,-16
    80004734:	e406                	sd	ra,8(sp)
    80004736:	e022                	sd	s0,0(sp)
    80004738:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000473a:	00004597          	auipc	a1,0x4
    8000473e:	f8658593          	addi	a1,a1,-122 # 800086c0 <syscalls+0x238>
    80004742:	0001e517          	auipc	a0,0x1e
    80004746:	00e50513          	addi	a0,a0,14 # 80022750 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	422080e7          	jalr	1058(ra) # 80000b6c <initlock>
}
    80004752:	60a2                	ld	ra,8(sp)
    80004754:	6402                	ld	s0,0(sp)
    80004756:	0141                	addi	sp,sp,16
    80004758:	8082                	ret

000000008000475a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000475a:	1101                	addi	sp,sp,-32
    8000475c:	ec06                	sd	ra,24(sp)
    8000475e:	e822                	sd	s0,16(sp)
    80004760:	e426                	sd	s1,8(sp)
    80004762:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004764:	0001e517          	auipc	a0,0x1e
    80004768:	fec50513          	addi	a0,a0,-20 # 80022750 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	490080e7          	jalr	1168(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004774:	0001e497          	auipc	s1,0x1e
    80004778:	ff448493          	addi	s1,s1,-12 # 80022768 <ftable+0x18>
    8000477c:	0001f717          	auipc	a4,0x1f
    80004780:	f8c70713          	addi	a4,a4,-116 # 80023708 <ftable+0xfb8>
    if(f->ref == 0){
    80004784:	40dc                	lw	a5,4(s1)
    80004786:	cf99                	beqz	a5,800047a4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004788:	02848493          	addi	s1,s1,40
    8000478c:	fee49ce3          	bne	s1,a4,80004784 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004790:	0001e517          	auipc	a0,0x1e
    80004794:	fc050513          	addi	a0,a0,-64 # 80022750 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	518080e7          	jalr	1304(ra) # 80000cb0 <release>
  return 0;
    800047a0:	4481                	li	s1,0
    800047a2:	a819                	j	800047b8 <filealloc+0x5e>
      f->ref = 1;
    800047a4:	4785                	li	a5,1
    800047a6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a8:	0001e517          	auipc	a0,0x1e
    800047ac:	fa850513          	addi	a0,a0,-88 # 80022750 <ftable>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	500080e7          	jalr	1280(ra) # 80000cb0 <release>
}
    800047b8:	8526                	mv	a0,s1
    800047ba:	60e2                	ld	ra,24(sp)
    800047bc:	6442                	ld	s0,16(sp)
    800047be:	64a2                	ld	s1,8(sp)
    800047c0:	6105                	addi	sp,sp,32
    800047c2:	8082                	ret

00000000800047c4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c4:	1101                	addi	sp,sp,-32
    800047c6:	ec06                	sd	ra,24(sp)
    800047c8:	e822                	sd	s0,16(sp)
    800047ca:	e426                	sd	s1,8(sp)
    800047cc:	1000                	addi	s0,sp,32
    800047ce:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d0:	0001e517          	auipc	a0,0x1e
    800047d4:	f8050513          	addi	a0,a0,-128 # 80022750 <ftable>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	424080e7          	jalr	1060(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047e0:	40dc                	lw	a5,4(s1)
    800047e2:	02f05263          	blez	a5,80004806 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e6:	2785                	addiw	a5,a5,1
    800047e8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ea:	0001e517          	auipc	a0,0x1e
    800047ee:	f6650513          	addi	a0,a0,-154 # 80022750 <ftable>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	4be080e7          	jalr	1214(ra) # 80000cb0 <release>
  return f;
}
    800047fa:	8526                	mv	a0,s1
    800047fc:	60e2                	ld	ra,24(sp)
    800047fe:	6442                	ld	s0,16(sp)
    80004800:	64a2                	ld	s1,8(sp)
    80004802:	6105                	addi	sp,sp,32
    80004804:	8082                	ret
    panic("filedup");
    80004806:	00004517          	auipc	a0,0x4
    8000480a:	ec250513          	addi	a0,a0,-318 # 800086c8 <syscalls+0x240>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	d32080e7          	jalr	-718(ra) # 80000540 <panic>

0000000080004816 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004816:	7139                	addi	sp,sp,-64
    80004818:	fc06                	sd	ra,56(sp)
    8000481a:	f822                	sd	s0,48(sp)
    8000481c:	f426                	sd	s1,40(sp)
    8000481e:	f04a                	sd	s2,32(sp)
    80004820:	ec4e                	sd	s3,24(sp)
    80004822:	e852                	sd	s4,16(sp)
    80004824:	e456                	sd	s5,8(sp)
    80004826:	0080                	addi	s0,sp,64
    80004828:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000482a:	0001e517          	auipc	a0,0x1e
    8000482e:	f2650513          	addi	a0,a0,-218 # 80022750 <ftable>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	3ca080e7          	jalr	970(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000483a:	40dc                	lw	a5,4(s1)
    8000483c:	06f05163          	blez	a5,8000489e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004840:	37fd                	addiw	a5,a5,-1
    80004842:	0007871b          	sext.w	a4,a5
    80004846:	c0dc                	sw	a5,4(s1)
    80004848:	06e04363          	bgtz	a4,800048ae <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000484c:	0004a903          	lw	s2,0(s1)
    80004850:	0094ca83          	lbu	s5,9(s1)
    80004854:	0104ba03          	ld	s4,16(s1)
    80004858:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000485c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004860:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004864:	0001e517          	auipc	a0,0x1e
    80004868:	eec50513          	addi	a0,a0,-276 # 80022750 <ftable>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	444080e7          	jalr	1092(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    80004874:	4785                	li	a5,1
    80004876:	04f90d63          	beq	s2,a5,800048d0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000487a:	3979                	addiw	s2,s2,-2
    8000487c:	4785                	li	a5,1
    8000487e:	0527e063          	bltu	a5,s2,800048be <fileclose+0xa8>
    begin_op();
    80004882:	00000097          	auipc	ra,0x0
    80004886:	ac2080e7          	jalr	-1342(ra) # 80004344 <begin_op>
    iput(ff.ip);
    8000488a:	854e                	mv	a0,s3
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	2b2080e7          	jalr	690(ra) # 80003b3e <iput>
    end_op();
    80004894:	00000097          	auipc	ra,0x0
    80004898:	b30080e7          	jalr	-1232(ra) # 800043c4 <end_op>
    8000489c:	a00d                	j	800048be <fileclose+0xa8>
    panic("fileclose");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	e3250513          	addi	a0,a0,-462 # 800086d0 <syscalls+0x248>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c9a080e7          	jalr	-870(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048ae:	0001e517          	auipc	a0,0x1e
    800048b2:	ea250513          	addi	a0,a0,-350 # 80022750 <ftable>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	3fa080e7          	jalr	1018(ra) # 80000cb0 <release>
  }
}
    800048be:	70e2                	ld	ra,56(sp)
    800048c0:	7442                	ld	s0,48(sp)
    800048c2:	74a2                	ld	s1,40(sp)
    800048c4:	7902                	ld	s2,32(sp)
    800048c6:	69e2                	ld	s3,24(sp)
    800048c8:	6a42                	ld	s4,16(sp)
    800048ca:	6aa2                	ld	s5,8(sp)
    800048cc:	6121                	addi	sp,sp,64
    800048ce:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d0:	85d6                	mv	a1,s5
    800048d2:	8552                	mv	a0,s4
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	372080e7          	jalr	882(ra) # 80004c46 <pipeclose>
    800048dc:	b7cd                	j	800048be <fileclose+0xa8>

00000000800048de <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048de:	715d                	addi	sp,sp,-80
    800048e0:	e486                	sd	ra,72(sp)
    800048e2:	e0a2                	sd	s0,64(sp)
    800048e4:	fc26                	sd	s1,56(sp)
    800048e6:	f84a                	sd	s2,48(sp)
    800048e8:	f44e                	sd	s3,40(sp)
    800048ea:	0880                	addi	s0,sp,80
    800048ec:	84aa                	mv	s1,a0
    800048ee:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f0:	ffffd097          	auipc	ra,0xffffd
    800048f4:	23c080e7          	jalr	572(ra) # 80001b2c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f8:	409c                	lw	a5,0(s1)
    800048fa:	37f9                	addiw	a5,a5,-2
    800048fc:	4705                	li	a4,1
    800048fe:	04f76763          	bltu	a4,a5,8000494c <filestat+0x6e>
    80004902:	892a                	mv	s2,a0
    ilock(f->ip);
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	07e080e7          	jalr	126(ra) # 80003984 <ilock>
    stati(f->ip, &st);
    8000490e:	fb840593          	addi	a1,s0,-72
    80004912:	6c88                	ld	a0,24(s1)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	2fa080e7          	jalr	762(ra) # 80003c0e <stati>
    iunlock(f->ip);
    8000491c:	6c88                	ld	a0,24(s1)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	128080e7          	jalr	296(ra) # 80003a46 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004926:	46e1                	li	a3,24
    80004928:	fb840613          	addi	a2,s0,-72
    8000492c:	85ce                	mv	a1,s3
    8000492e:	05093503          	ld	a0,80(s2)
    80004932:	ffffd097          	auipc	ra,0xffffd
    80004936:	d78080e7          	jalr	-648(ra) # 800016aa <copyout>
    8000493a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000493e:	60a6                	ld	ra,72(sp)
    80004940:	6406                	ld	s0,64(sp)
    80004942:	74e2                	ld	s1,56(sp)
    80004944:	7942                	ld	s2,48(sp)
    80004946:	79a2                	ld	s3,40(sp)
    80004948:	6161                	addi	sp,sp,80
    8000494a:	8082                	ret
  return -1;
    8000494c:	557d                	li	a0,-1
    8000494e:	bfc5                	j	8000493e <filestat+0x60>

0000000080004950 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004950:	7179                	addi	sp,sp,-48
    80004952:	f406                	sd	ra,40(sp)
    80004954:	f022                	sd	s0,32(sp)
    80004956:	ec26                	sd	s1,24(sp)
    80004958:	e84a                	sd	s2,16(sp)
    8000495a:	e44e                	sd	s3,8(sp)
    8000495c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000495e:	00854783          	lbu	a5,8(a0)
    80004962:	c3d5                	beqz	a5,80004a06 <fileread+0xb6>
    80004964:	84aa                	mv	s1,a0
    80004966:	89ae                	mv	s3,a1
    80004968:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000496a:	411c                	lw	a5,0(a0)
    8000496c:	4705                	li	a4,1
    8000496e:	04e78963          	beq	a5,a4,800049c0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004972:	470d                	li	a4,3
    80004974:	04e78d63          	beq	a5,a4,800049ce <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004978:	4709                	li	a4,2
    8000497a:	06e79e63          	bne	a5,a4,800049f6 <fileread+0xa6>
    ilock(f->ip);
    8000497e:	6d08                	ld	a0,24(a0)
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	004080e7          	jalr	4(ra) # 80003984 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004988:	874a                	mv	a4,s2
    8000498a:	5094                	lw	a3,32(s1)
    8000498c:	864e                	mv	a2,s3
    8000498e:	4585                	li	a1,1
    80004990:	6c88                	ld	a0,24(s1)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	2a6080e7          	jalr	678(ra) # 80003c38 <readi>
    8000499a:	892a                	mv	s2,a0
    8000499c:	00a05563          	blez	a0,800049a6 <fileread+0x56>
      f->off += r;
    800049a0:	509c                	lw	a5,32(s1)
    800049a2:	9fa9                	addw	a5,a5,a0
    800049a4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a6:	6c88                	ld	a0,24(s1)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	09e080e7          	jalr	158(ra) # 80003a46 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b0:	854a                	mv	a0,s2
    800049b2:	70a2                	ld	ra,40(sp)
    800049b4:	7402                	ld	s0,32(sp)
    800049b6:	64e2                	ld	s1,24(sp)
    800049b8:	6942                	ld	s2,16(sp)
    800049ba:	69a2                	ld	s3,8(sp)
    800049bc:	6145                	addi	sp,sp,48
    800049be:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c0:	6908                	ld	a0,16(a0)
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	3f4080e7          	jalr	1012(ra) # 80004db6 <piperead>
    800049ca:	892a                	mv	s2,a0
    800049cc:	b7d5                	j	800049b0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049ce:	02451783          	lh	a5,36(a0)
    800049d2:	03079693          	slli	a3,a5,0x30
    800049d6:	92c1                	srli	a3,a3,0x30
    800049d8:	4725                	li	a4,9
    800049da:	02d76863          	bltu	a4,a3,80004a0a <fileread+0xba>
    800049de:	0792                	slli	a5,a5,0x4
    800049e0:	0001e717          	auipc	a4,0x1e
    800049e4:	cd070713          	addi	a4,a4,-816 # 800226b0 <devsw>
    800049e8:	97ba                	add	a5,a5,a4
    800049ea:	639c                	ld	a5,0(a5)
    800049ec:	c38d                	beqz	a5,80004a0e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ee:	4505                	li	a0,1
    800049f0:	9782                	jalr	a5
    800049f2:	892a                	mv	s2,a0
    800049f4:	bf75                	j	800049b0 <fileread+0x60>
    panic("fileread");
    800049f6:	00004517          	auipc	a0,0x4
    800049fa:	cea50513          	addi	a0,a0,-790 # 800086e0 <syscalls+0x258>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b42080e7          	jalr	-1214(ra) # 80000540 <panic>
    return -1;
    80004a06:	597d                	li	s2,-1
    80004a08:	b765                	j	800049b0 <fileread+0x60>
      return -1;
    80004a0a:	597d                	li	s2,-1
    80004a0c:	b755                	j	800049b0 <fileread+0x60>
    80004a0e:	597d                	li	s2,-1
    80004a10:	b745                	j	800049b0 <fileread+0x60>

0000000080004a12 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a12:	00954783          	lbu	a5,9(a0)
    80004a16:	14078563          	beqz	a5,80004b60 <filewrite+0x14e>
{
    80004a1a:	715d                	addi	sp,sp,-80
    80004a1c:	e486                	sd	ra,72(sp)
    80004a1e:	e0a2                	sd	s0,64(sp)
    80004a20:	fc26                	sd	s1,56(sp)
    80004a22:	f84a                	sd	s2,48(sp)
    80004a24:	f44e                	sd	s3,40(sp)
    80004a26:	f052                	sd	s4,32(sp)
    80004a28:	ec56                	sd	s5,24(sp)
    80004a2a:	e85a                	sd	s6,16(sp)
    80004a2c:	e45e                	sd	s7,8(sp)
    80004a2e:	e062                	sd	s8,0(sp)
    80004a30:	0880                	addi	s0,sp,80
    80004a32:	892a                	mv	s2,a0
    80004a34:	8aae                	mv	s5,a1
    80004a36:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a38:	411c                	lw	a5,0(a0)
    80004a3a:	4705                	li	a4,1
    80004a3c:	02e78263          	beq	a5,a4,80004a60 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a40:	470d                	li	a4,3
    80004a42:	02e78563          	beq	a5,a4,80004a6c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a46:	4709                	li	a4,2
    80004a48:	10e79463          	bne	a5,a4,80004b50 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a4c:	0ec05e63          	blez	a2,80004b48 <filewrite+0x136>
    int i = 0;
    80004a50:	4981                	li	s3,0
    80004a52:	6b05                	lui	s6,0x1
    80004a54:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a58:	6b85                	lui	s7,0x1
    80004a5a:	c00b8b9b          	addiw	s7,s7,-1024
    80004a5e:	a851                	j	80004af2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a60:	6908                	ld	a0,16(a0)
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	254080e7          	jalr	596(ra) # 80004cb6 <pipewrite>
    80004a6a:	a85d                	j	80004b20 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a6c:	02451783          	lh	a5,36(a0)
    80004a70:	03079693          	slli	a3,a5,0x30
    80004a74:	92c1                	srli	a3,a3,0x30
    80004a76:	4725                	li	a4,9
    80004a78:	0ed76663          	bltu	a4,a3,80004b64 <filewrite+0x152>
    80004a7c:	0792                	slli	a5,a5,0x4
    80004a7e:	0001e717          	auipc	a4,0x1e
    80004a82:	c3270713          	addi	a4,a4,-974 # 800226b0 <devsw>
    80004a86:	97ba                	add	a5,a5,a4
    80004a88:	679c                	ld	a5,8(a5)
    80004a8a:	cff9                	beqz	a5,80004b68 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a8c:	4505                	li	a0,1
    80004a8e:	9782                	jalr	a5
    80004a90:	a841                	j	80004b20 <filewrite+0x10e>
    80004a92:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	8ae080e7          	jalr	-1874(ra) # 80004344 <begin_op>
      ilock(f->ip);
    80004a9e:	01893503          	ld	a0,24(s2)
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	ee2080e7          	jalr	-286(ra) # 80003984 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aaa:	8762                	mv	a4,s8
    80004aac:	02092683          	lw	a3,32(s2)
    80004ab0:	01598633          	add	a2,s3,s5
    80004ab4:	4585                	li	a1,1
    80004ab6:	01893503          	ld	a0,24(s2)
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	274080e7          	jalr	628(ra) # 80003d2e <writei>
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	02a05f63          	blez	a0,80004b02 <filewrite+0xf0>
        f->off += r;
    80004ac8:	02092783          	lw	a5,32(s2)
    80004acc:	9fa9                	addw	a5,a5,a0
    80004ace:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad2:	01893503          	ld	a0,24(s2)
    80004ad6:	fffff097          	auipc	ra,0xfffff
    80004ada:	f70080e7          	jalr	-144(ra) # 80003a46 <iunlock>
      end_op();
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	8e6080e7          	jalr	-1818(ra) # 800043c4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ae6:	049c1963          	bne	s8,s1,80004b38 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004aea:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aee:	0349d663          	bge	s3,s4,80004b1a <filewrite+0x108>
      int n1 = n - i;
    80004af2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004af6:	84be                	mv	s1,a5
    80004af8:	2781                	sext.w	a5,a5
    80004afa:	f8fb5ce3          	bge	s6,a5,80004a92 <filewrite+0x80>
    80004afe:	84de                	mv	s1,s7
    80004b00:	bf49                	j	80004a92 <filewrite+0x80>
      iunlock(f->ip);
    80004b02:	01893503          	ld	a0,24(s2)
    80004b06:	fffff097          	auipc	ra,0xfffff
    80004b0a:	f40080e7          	jalr	-192(ra) # 80003a46 <iunlock>
      end_op();
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	8b6080e7          	jalr	-1866(ra) # 800043c4 <end_op>
      if(r < 0)
    80004b16:	fc04d8e3          	bgez	s1,80004ae6 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b1a:	8552                	mv	a0,s4
    80004b1c:	033a1863          	bne	s4,s3,80004b4c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b20:	60a6                	ld	ra,72(sp)
    80004b22:	6406                	ld	s0,64(sp)
    80004b24:	74e2                	ld	s1,56(sp)
    80004b26:	7942                	ld	s2,48(sp)
    80004b28:	79a2                	ld	s3,40(sp)
    80004b2a:	7a02                	ld	s4,32(sp)
    80004b2c:	6ae2                	ld	s5,24(sp)
    80004b2e:	6b42                	ld	s6,16(sp)
    80004b30:	6ba2                	ld	s7,8(sp)
    80004b32:	6c02                	ld	s8,0(sp)
    80004b34:	6161                	addi	sp,sp,80
    80004b36:	8082                	ret
        panic("short filewrite");
    80004b38:	00004517          	auipc	a0,0x4
    80004b3c:	bb850513          	addi	a0,a0,-1096 # 800086f0 <syscalls+0x268>
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	a00080e7          	jalr	-1536(ra) # 80000540 <panic>
    int i = 0;
    80004b48:	4981                	li	s3,0
    80004b4a:	bfc1                	j	80004b1a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b4c:	557d                	li	a0,-1
    80004b4e:	bfc9                	j	80004b20 <filewrite+0x10e>
    panic("filewrite");
    80004b50:	00004517          	auipc	a0,0x4
    80004b54:	bb050513          	addi	a0,a0,-1104 # 80008700 <syscalls+0x278>
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	9e8080e7          	jalr	-1560(ra) # 80000540 <panic>
    return -1;
    80004b60:	557d                	li	a0,-1
}
    80004b62:	8082                	ret
      return -1;
    80004b64:	557d                	li	a0,-1
    80004b66:	bf6d                	j	80004b20 <filewrite+0x10e>
    80004b68:	557d                	li	a0,-1
    80004b6a:	bf5d                	j	80004b20 <filewrite+0x10e>

0000000080004b6c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b6c:	7179                	addi	sp,sp,-48
    80004b6e:	f406                	sd	ra,40(sp)
    80004b70:	f022                	sd	s0,32(sp)
    80004b72:	ec26                	sd	s1,24(sp)
    80004b74:	e84a                	sd	s2,16(sp)
    80004b76:	e44e                	sd	s3,8(sp)
    80004b78:	e052                	sd	s4,0(sp)
    80004b7a:	1800                	addi	s0,sp,48
    80004b7c:	84aa                	mv	s1,a0
    80004b7e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b80:	0005b023          	sd	zero,0(a1)
    80004b84:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	bd2080e7          	jalr	-1070(ra) # 8000475a <filealloc>
    80004b90:	e088                	sd	a0,0(s1)
    80004b92:	c551                	beqz	a0,80004c1e <pipealloc+0xb2>
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	bc6080e7          	jalr	-1082(ra) # 8000475a <filealloc>
    80004b9c:	00aa3023          	sd	a0,0(s4)
    80004ba0:	c92d                	beqz	a0,80004c12 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	f6a080e7          	jalr	-150(ra) # 80000b0c <kalloc>
    80004baa:	892a                	mv	s2,a0
    80004bac:	c125                	beqz	a0,80004c0c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bae:	4985                	li	s3,1
    80004bb0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bb4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bb8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bbc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bc0:	00004597          	auipc	a1,0x4
    80004bc4:	b5058593          	addi	a1,a1,-1200 # 80008710 <syscalls+0x288>
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	fa4080e7          	jalr	-92(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004bd0:	609c                	ld	a5,0(s1)
    80004bd2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bd6:	609c                	ld	a5,0(s1)
    80004bd8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bdc:	609c                	ld	a5,0(s1)
    80004bde:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004be2:	609c                	ld	a5,0(s1)
    80004be4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004be8:	000a3783          	ld	a5,0(s4)
    80004bec:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bf0:	000a3783          	ld	a5,0(s4)
    80004bf4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bf8:	000a3783          	ld	a5,0(s4)
    80004bfc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c00:	000a3783          	ld	a5,0(s4)
    80004c04:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c08:	4501                	li	a0,0
    80004c0a:	a025                	j	80004c32 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c0c:	6088                	ld	a0,0(s1)
    80004c0e:	e501                	bnez	a0,80004c16 <pipealloc+0xaa>
    80004c10:	a039                	j	80004c1e <pipealloc+0xb2>
    80004c12:	6088                	ld	a0,0(s1)
    80004c14:	c51d                	beqz	a0,80004c42 <pipealloc+0xd6>
    fileclose(*f0);
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	c00080e7          	jalr	-1024(ra) # 80004816 <fileclose>
  if(*f1)
    80004c1e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c22:	557d                	li	a0,-1
  if(*f1)
    80004c24:	c799                	beqz	a5,80004c32 <pipealloc+0xc6>
    fileclose(*f1);
    80004c26:	853e                	mv	a0,a5
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	bee080e7          	jalr	-1042(ra) # 80004816 <fileclose>
  return -1;
    80004c30:	557d                	li	a0,-1
}
    80004c32:	70a2                	ld	ra,40(sp)
    80004c34:	7402                	ld	s0,32(sp)
    80004c36:	64e2                	ld	s1,24(sp)
    80004c38:	6942                	ld	s2,16(sp)
    80004c3a:	69a2                	ld	s3,8(sp)
    80004c3c:	6a02                	ld	s4,0(sp)
    80004c3e:	6145                	addi	sp,sp,48
    80004c40:	8082                	ret
  return -1;
    80004c42:	557d                	li	a0,-1
    80004c44:	b7fd                	j	80004c32 <pipealloc+0xc6>

0000000080004c46 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c46:	1101                	addi	sp,sp,-32
    80004c48:	ec06                	sd	ra,24(sp)
    80004c4a:	e822                	sd	s0,16(sp)
    80004c4c:	e426                	sd	s1,8(sp)
    80004c4e:	e04a                	sd	s2,0(sp)
    80004c50:	1000                	addi	s0,sp,32
    80004c52:	84aa                	mv	s1,a0
    80004c54:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	fa6080e7          	jalr	-90(ra) # 80000bfc <acquire>
  if(writable){
    80004c5e:	02090d63          	beqz	s2,80004c98 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c62:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c66:	21848513          	addi	a0,s1,536
    80004c6a:	ffffe097          	auipc	ra,0xffffe
    80004c6e:	a20080e7          	jalr	-1504(ra) # 8000268a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c72:	2204b783          	ld	a5,544(s1)
    80004c76:	eb95                	bnez	a5,80004caa <pipeclose+0x64>
    release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	036080e7          	jalr	54(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	d8c080e7          	jalr	-628(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c8c:	60e2                	ld	ra,24(sp)
    80004c8e:	6442                	ld	s0,16(sp)
    80004c90:	64a2                	ld	s1,8(sp)
    80004c92:	6902                	ld	s2,0(sp)
    80004c94:	6105                	addi	sp,sp,32
    80004c96:	8082                	ret
    pi->readopen = 0;
    80004c98:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c9c:	21c48513          	addi	a0,s1,540
    80004ca0:	ffffe097          	auipc	ra,0xffffe
    80004ca4:	9ea080e7          	jalr	-1558(ra) # 8000268a <wakeup>
    80004ca8:	b7e9                	j	80004c72 <pipeclose+0x2c>
    release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	004080e7          	jalr	4(ra) # 80000cb0 <release>
}
    80004cb4:	bfe1                	j	80004c8c <pipeclose+0x46>

0000000080004cb6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cb6:	711d                	addi	sp,sp,-96
    80004cb8:	ec86                	sd	ra,88(sp)
    80004cba:	e8a2                	sd	s0,80(sp)
    80004cbc:	e4a6                	sd	s1,72(sp)
    80004cbe:	e0ca                	sd	s2,64(sp)
    80004cc0:	fc4e                	sd	s3,56(sp)
    80004cc2:	f852                	sd	s4,48(sp)
    80004cc4:	f456                	sd	s5,40(sp)
    80004cc6:	f05a                	sd	s6,32(sp)
    80004cc8:	ec5e                	sd	s7,24(sp)
    80004cca:	e862                	sd	s8,16(sp)
    80004ccc:	1080                	addi	s0,sp,96
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	8b2e                	mv	s6,a1
    80004cd2:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	e58080e7          	jalr	-424(ra) # 80001b2c <myproc>
    80004cdc:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f1c080e7          	jalr	-228(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004ce8:	09505763          	blez	s5,80004d76 <pipewrite+0xc0>
    80004cec:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cee:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cf2:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf6:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cf8:	2184a783          	lw	a5,536(s1)
    80004cfc:	21c4a703          	lw	a4,540(s1)
    80004d00:	2007879b          	addiw	a5,a5,512
    80004d04:	02f71b63          	bne	a4,a5,80004d3a <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d08:	2204a783          	lw	a5,544(s1)
    80004d0c:	c3d1                	beqz	a5,80004d90 <pipewrite+0xda>
    80004d0e:	03092783          	lw	a5,48(s2)
    80004d12:	efbd                	bnez	a5,80004d90 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d14:	8552                	mv	a0,s4
    80004d16:	ffffe097          	auipc	ra,0xffffe
    80004d1a:	974080e7          	jalr	-1676(ra) # 8000268a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d1e:	85a6                	mv	a1,s1
    80004d20:	854e                	mv	a0,s3
    80004d22:	ffffd097          	auipc	ra,0xffffd
    80004d26:	7ce080e7          	jalr	1998(ra) # 800024f0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d2a:	2184a783          	lw	a5,536(s1)
    80004d2e:	21c4a703          	lw	a4,540(s1)
    80004d32:	2007879b          	addiw	a5,a5,512
    80004d36:	fcf709e3          	beq	a4,a5,80004d08 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3a:	4685                	li	a3,1
    80004d3c:	865a                	mv	a2,s6
    80004d3e:	faf40593          	addi	a1,s0,-81
    80004d42:	05093503          	ld	a0,80(s2)
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	9f0080e7          	jalr	-1552(ra) # 80001736 <copyin>
    80004d4e:	03850563          	beq	a0,s8,80004d78 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d52:	21c4a783          	lw	a5,540(s1)
    80004d56:	0017871b          	addiw	a4,a5,1
    80004d5a:	20e4ae23          	sw	a4,540(s1)
    80004d5e:	1ff7f793          	andi	a5,a5,511
    80004d62:	97a6                	add	a5,a5,s1
    80004d64:	faf44703          	lbu	a4,-81(s0)
    80004d68:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d6c:	2b85                	addiw	s7,s7,1
    80004d6e:	0b05                	addi	s6,s6,1
    80004d70:	f97a94e3          	bne	s5,s7,80004cf8 <pipewrite+0x42>
    80004d74:	a011                	j	80004d78 <pipewrite+0xc2>
    80004d76:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d78:	21848513          	addi	a0,s1,536
    80004d7c:	ffffe097          	auipc	ra,0xffffe
    80004d80:	90e080e7          	jalr	-1778(ra) # 8000268a <wakeup>
  release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f2a080e7          	jalr	-214(ra) # 80000cb0 <release>
  return i;
    80004d8e:	a039                	j	80004d9c <pipewrite+0xe6>
        release(&pi->lock);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	f1e080e7          	jalr	-226(ra) # 80000cb0 <release>
        return -1;
    80004d9a:	5bfd                	li	s7,-1
}
    80004d9c:	855e                	mv	a0,s7
    80004d9e:	60e6                	ld	ra,88(sp)
    80004da0:	6446                	ld	s0,80(sp)
    80004da2:	64a6                	ld	s1,72(sp)
    80004da4:	6906                	ld	s2,64(sp)
    80004da6:	79e2                	ld	s3,56(sp)
    80004da8:	7a42                	ld	s4,48(sp)
    80004daa:	7aa2                	ld	s5,40(sp)
    80004dac:	7b02                	ld	s6,32(sp)
    80004dae:	6be2                	ld	s7,24(sp)
    80004db0:	6c42                	ld	s8,16(sp)
    80004db2:	6125                	addi	sp,sp,96
    80004db4:	8082                	ret

0000000080004db6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004db6:	715d                	addi	sp,sp,-80
    80004db8:	e486                	sd	ra,72(sp)
    80004dba:	e0a2                	sd	s0,64(sp)
    80004dbc:	fc26                	sd	s1,56(sp)
    80004dbe:	f84a                	sd	s2,48(sp)
    80004dc0:	f44e                	sd	s3,40(sp)
    80004dc2:	f052                	sd	s4,32(sp)
    80004dc4:	ec56                	sd	s5,24(sp)
    80004dc6:	e85a                	sd	s6,16(sp)
    80004dc8:	0880                	addi	s0,sp,80
    80004dca:	84aa                	mv	s1,a0
    80004dcc:	892e                	mv	s2,a1
    80004dce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	d5c080e7          	jalr	-676(ra) # 80001b2c <myproc>
    80004dd8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	e20080e7          	jalr	-480(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de4:	2184a703          	lw	a4,536(s1)
    80004de8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dec:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df0:	02f71463          	bne	a4,a5,80004e18 <piperead+0x62>
    80004df4:	2244a783          	lw	a5,548(s1)
    80004df8:	c385                	beqz	a5,80004e18 <piperead+0x62>
    if(pr->killed){
    80004dfa:	030a2783          	lw	a5,48(s4)
    80004dfe:	ebc1                	bnez	a5,80004e8e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e00:	85a6                	mv	a1,s1
    80004e02:	854e                	mv	a0,s3
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	6ec080e7          	jalr	1772(ra) # 800024f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e0c:	2184a703          	lw	a4,536(s1)
    80004e10:	21c4a783          	lw	a5,540(s1)
    80004e14:	fef700e3          	beq	a4,a5,80004df4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e18:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e1a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1c:	05505363          	blez	s5,80004e62 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e20:	2184a783          	lw	a5,536(s1)
    80004e24:	21c4a703          	lw	a4,540(s1)
    80004e28:	02f70d63          	beq	a4,a5,80004e62 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e2c:	0017871b          	addiw	a4,a5,1
    80004e30:	20e4ac23          	sw	a4,536(s1)
    80004e34:	1ff7f793          	andi	a5,a5,511
    80004e38:	97a6                	add	a5,a5,s1
    80004e3a:	0187c783          	lbu	a5,24(a5)
    80004e3e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e42:	4685                	li	a3,1
    80004e44:	fbf40613          	addi	a2,s0,-65
    80004e48:	85ca                	mv	a1,s2
    80004e4a:	050a3503          	ld	a0,80(s4)
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	85c080e7          	jalr	-1956(ra) # 800016aa <copyout>
    80004e56:	01650663          	beq	a0,s6,80004e62 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5a:	2985                	addiw	s3,s3,1
    80004e5c:	0905                	addi	s2,s2,1
    80004e5e:	fd3a91e3          	bne	s5,s3,80004e20 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e62:	21c48513          	addi	a0,s1,540
    80004e66:	ffffe097          	auipc	ra,0xffffe
    80004e6a:	824080e7          	jalr	-2012(ra) # 8000268a <wakeup>
  release(&pi->lock);
    80004e6e:	8526                	mv	a0,s1
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	e40080e7          	jalr	-448(ra) # 80000cb0 <release>
  return i;
}
    80004e78:	854e                	mv	a0,s3
    80004e7a:	60a6                	ld	ra,72(sp)
    80004e7c:	6406                	ld	s0,64(sp)
    80004e7e:	74e2                	ld	s1,56(sp)
    80004e80:	7942                	ld	s2,48(sp)
    80004e82:	79a2                	ld	s3,40(sp)
    80004e84:	7a02                	ld	s4,32(sp)
    80004e86:	6ae2                	ld	s5,24(sp)
    80004e88:	6b42                	ld	s6,16(sp)
    80004e8a:	6161                	addi	sp,sp,80
    80004e8c:	8082                	ret
      release(&pi->lock);
    80004e8e:	8526                	mv	a0,s1
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	e20080e7          	jalr	-480(ra) # 80000cb0 <release>
      return -1;
    80004e98:	59fd                	li	s3,-1
    80004e9a:	bff9                	j	80004e78 <piperead+0xc2>

0000000080004e9c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e9c:	de010113          	addi	sp,sp,-544
    80004ea0:	20113c23          	sd	ra,536(sp)
    80004ea4:	20813823          	sd	s0,528(sp)
    80004ea8:	20913423          	sd	s1,520(sp)
    80004eac:	21213023          	sd	s2,512(sp)
    80004eb0:	ffce                	sd	s3,504(sp)
    80004eb2:	fbd2                	sd	s4,496(sp)
    80004eb4:	f7d6                	sd	s5,488(sp)
    80004eb6:	f3da                	sd	s6,480(sp)
    80004eb8:	efde                	sd	s7,472(sp)
    80004eba:	ebe2                	sd	s8,464(sp)
    80004ebc:	e7e6                	sd	s9,456(sp)
    80004ebe:	e3ea                	sd	s10,448(sp)
    80004ec0:	ff6e                	sd	s11,440(sp)
    80004ec2:	1400                	addi	s0,sp,544
    80004ec4:	892a                	mv	s2,a0
    80004ec6:	dea43423          	sd	a0,-536(s0)
    80004eca:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	c5e080e7          	jalr	-930(ra) # 80001b2c <myproc>
    80004ed6:	84aa                	mv	s1,a0

  begin_op();
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	46c080e7          	jalr	1132(ra) # 80004344 <begin_op>

  if((ip = namei(path)) == 0){
    80004ee0:	854a                	mv	a0,s2
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	252080e7          	jalr	594(ra) # 80004134 <namei>
    80004eea:	c93d                	beqz	a0,80004f60 <exec+0xc4>
    80004eec:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	a96080e7          	jalr	-1386(ra) # 80003984 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ef6:	04000713          	li	a4,64
    80004efa:	4681                	li	a3,0
    80004efc:	e4840613          	addi	a2,s0,-440
    80004f00:	4581                	li	a1,0
    80004f02:	8556                	mv	a0,s5
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	d34080e7          	jalr	-716(ra) # 80003c38 <readi>
    80004f0c:	04000793          	li	a5,64
    80004f10:	00f51a63          	bne	a0,a5,80004f24 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f14:	e4842703          	lw	a4,-440(s0)
    80004f18:	464c47b7          	lui	a5,0x464c4
    80004f1c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f20:	04f70663          	beq	a4,a5,80004f6c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f24:	8556                	mv	a0,s5
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	cc0080e7          	jalr	-832(ra) # 80003be6 <iunlockput>
    end_op();
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	496080e7          	jalr	1174(ra) # 800043c4 <end_op>
  }
  return -1;
    80004f36:	557d                	li	a0,-1
}
    80004f38:	21813083          	ld	ra,536(sp)
    80004f3c:	21013403          	ld	s0,528(sp)
    80004f40:	20813483          	ld	s1,520(sp)
    80004f44:	20013903          	ld	s2,512(sp)
    80004f48:	79fe                	ld	s3,504(sp)
    80004f4a:	7a5e                	ld	s4,496(sp)
    80004f4c:	7abe                	ld	s5,488(sp)
    80004f4e:	7b1e                	ld	s6,480(sp)
    80004f50:	6bfe                	ld	s7,472(sp)
    80004f52:	6c5e                	ld	s8,464(sp)
    80004f54:	6cbe                	ld	s9,456(sp)
    80004f56:	6d1e                	ld	s10,448(sp)
    80004f58:	7dfa                	ld	s11,440(sp)
    80004f5a:	22010113          	addi	sp,sp,544
    80004f5e:	8082                	ret
    end_op();
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	464080e7          	jalr	1124(ra) # 800043c4 <end_op>
    return -1;
    80004f68:	557d                	li	a0,-1
    80004f6a:	b7f9                	j	80004f38 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	c84080e7          	jalr	-892(ra) # 80001bf2 <proc_pagetable>
    80004f76:	8b2a                	mv	s6,a0
    80004f78:	d555                	beqz	a0,80004f24 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7a:	e6842783          	lw	a5,-408(s0)
    80004f7e:	e8045703          	lhu	a4,-384(s0)
    80004f82:	c735                	beqz	a4,80004fee <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f84:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f86:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f8a:	6a05                	lui	s4,0x1
    80004f8c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f90:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f94:	6d85                	lui	s11,0x1
    80004f96:	7d7d                	lui	s10,0xfffff
    80004f98:	ac1d                	j	800051ce <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f9a:	00003517          	auipc	a0,0x3
    80004f9e:	77e50513          	addi	a0,a0,1918 # 80008718 <syscalls+0x290>
    80004fa2:	ffffb097          	auipc	ra,0xffffb
    80004fa6:	59e080e7          	jalr	1438(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004faa:	874a                	mv	a4,s2
    80004fac:	009c86bb          	addw	a3,s9,s1
    80004fb0:	4581                	li	a1,0
    80004fb2:	8556                	mv	a0,s5
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	c84080e7          	jalr	-892(ra) # 80003c38 <readi>
    80004fbc:	2501                	sext.w	a0,a0
    80004fbe:	1aa91863          	bne	s2,a0,8000516e <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fc2:	009d84bb          	addw	s1,s11,s1
    80004fc6:	013d09bb          	addw	s3,s10,s3
    80004fca:	1f74f263          	bgeu	s1,s7,800051ae <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fce:	02049593          	slli	a1,s1,0x20
    80004fd2:	9181                	srli	a1,a1,0x20
    80004fd4:	95e2                	add	a1,a1,s8
    80004fd6:	855a                	mv	a0,s6
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	09e080e7          	jalr	158(ra) # 80001076 <walkaddr>
    80004fe0:	862a                	mv	a2,a0
    if(pa == 0)
    80004fe2:	dd45                	beqz	a0,80004f9a <exec+0xfe>
      n = PGSIZE;
    80004fe4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fe6:	fd49f2e3          	bgeu	s3,s4,80004faa <exec+0x10e>
      n = sz - i;
    80004fea:	894e                	mv	s2,s3
    80004fec:	bf7d                	j	80004faa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fee:	4481                	li	s1,0
  iunlockput(ip);
    80004ff0:	8556                	mv	a0,s5
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	bf4080e7          	jalr	-1036(ra) # 80003be6 <iunlockput>
  end_op();
    80004ffa:	fffff097          	auipc	ra,0xfffff
    80004ffe:	3ca080e7          	jalr	970(ra) # 800043c4 <end_op>
  p = myproc();
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	b2a080e7          	jalr	-1238(ra) # 80001b2c <myproc>
    8000500a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000500c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005010:	6785                	lui	a5,0x1
    80005012:	17fd                	addi	a5,a5,-1
    80005014:	94be                	add	s1,s1,a5
    80005016:	77fd                	lui	a5,0xfffff
    80005018:	8fe5                	and	a5,a5,s1
    8000501a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000501e:	6609                	lui	a2,0x2
    80005020:	963e                	add	a2,a2,a5
    80005022:	85be                	mv	a1,a5
    80005024:	855a                	mv	a0,s6
    80005026:	ffffc097          	auipc	ra,0xffffc
    8000502a:	434080e7          	jalr	1076(ra) # 8000145a <uvmalloc>
    8000502e:	8c2a                	mv	s8,a0
  ip = 0;
    80005030:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005032:	12050e63          	beqz	a0,8000516e <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005036:	75f9                	lui	a1,0xffffe
    80005038:	95aa                	add	a1,a1,a0
    8000503a:	855a                	mv	a0,s6
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	63c080e7          	jalr	1596(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80005044:	7afd                	lui	s5,0xfffff
    80005046:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005048:	df043783          	ld	a5,-528(s0)
    8000504c:	6388                	ld	a0,0(a5)
    8000504e:	c925                	beqz	a0,800050be <exec+0x222>
    80005050:	e8840993          	addi	s3,s0,-376
    80005054:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005058:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000505a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	e20080e7          	jalr	-480(ra) # 80000e7c <strlen>
    80005064:	0015079b          	addiw	a5,a0,1
    80005068:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000506c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005070:	13596363          	bltu	s2,s5,80005196 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005074:	df043d83          	ld	s11,-528(s0)
    80005078:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000507c:	8552                	mv	a0,s4
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	dfe080e7          	jalr	-514(ra) # 80000e7c <strlen>
    80005086:	0015069b          	addiw	a3,a0,1
    8000508a:	8652                	mv	a2,s4
    8000508c:	85ca                	mv	a1,s2
    8000508e:	855a                	mv	a0,s6
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	61a080e7          	jalr	1562(ra) # 800016aa <copyout>
    80005098:	10054363          	bltz	a0,8000519e <exec+0x302>
    ustack[argc] = sp;
    8000509c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a0:	0485                	addi	s1,s1,1
    800050a2:	008d8793          	addi	a5,s11,8
    800050a6:	def43823          	sd	a5,-528(s0)
    800050aa:	008db503          	ld	a0,8(s11)
    800050ae:	c911                	beqz	a0,800050c2 <exec+0x226>
    if(argc >= MAXARG)
    800050b0:	09a1                	addi	s3,s3,8
    800050b2:	fb3c95e3          	bne	s9,s3,8000505c <exec+0x1c0>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	a84d                	j	8000516e <exec+0x2d2>
  sp = sz;
    800050be:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800050c2:	00349793          	slli	a5,s1,0x3
    800050c6:	f9040713          	addi	a4,s0,-112
    800050ca:	97ba                	add	a5,a5,a4
    800050cc:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050d0:	00148693          	addi	a3,s1,1
    800050d4:	068e                	slli	a3,a3,0x3
    800050d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050de:	01597663          	bgeu	s2,s5,800050ea <exec+0x24e>
  sz = sz1;
    800050e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e6:	4a81                	li	s5,0
    800050e8:	a059                	j	8000516e <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ea:	e8840613          	addi	a2,s0,-376
    800050ee:	85ca                	mv	a1,s2
    800050f0:	855a                	mv	a0,s6
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	5b8080e7          	jalr	1464(ra) # 800016aa <copyout>
    800050fa:	0a054663          	bltz	a0,800051a6 <exec+0x30a>
  p->trapframe->a1 = sp;
    800050fe:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005102:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005106:	de843783          	ld	a5,-536(s0)
    8000510a:	0007c703          	lbu	a4,0(a5)
    8000510e:	cf11                	beqz	a4,8000512a <exec+0x28e>
    80005110:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005112:	02f00693          	li	a3,47
    80005116:	a039                	j	80005124 <exec+0x288>
      last = s+1;
    80005118:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000511c:	0785                	addi	a5,a5,1
    8000511e:	fff7c703          	lbu	a4,-1(a5)
    80005122:	c701                	beqz	a4,8000512a <exec+0x28e>
    if(*s == '/')
    80005124:	fed71ce3          	bne	a4,a3,8000511c <exec+0x280>
    80005128:	bfc5                	j	80005118 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000512a:	4641                	li	a2,16
    8000512c:	de843583          	ld	a1,-536(s0)
    80005130:	158b8513          	addi	a0,s7,344
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	d16080e7          	jalr	-746(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    8000513c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005140:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005144:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005148:	058bb783          	ld	a5,88(s7)
    8000514c:	e6043703          	ld	a4,-416(s0)
    80005150:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005152:	058bb783          	ld	a5,88(s7)
    80005156:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000515a:	85ea                	mv	a1,s10
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	b32080e7          	jalr	-1230(ra) # 80001c8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005164:	0004851b          	sext.w	a0,s1
    80005168:	bbc1                	j	80004f38 <exec+0x9c>
    8000516a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000516e:	df843583          	ld	a1,-520(s0)
    80005172:	855a                	mv	a0,s6
    80005174:	ffffd097          	auipc	ra,0xffffd
    80005178:	b1a080e7          	jalr	-1254(ra) # 80001c8e <proc_freepagetable>
  if(ip){
    8000517c:	da0a94e3          	bnez	s5,80004f24 <exec+0x88>
  return -1;
    80005180:	557d                	li	a0,-1
    80005182:	bb5d                	j	80004f38 <exec+0x9c>
    80005184:	de943c23          	sd	s1,-520(s0)
    80005188:	b7dd                	j	8000516e <exec+0x2d2>
    8000518a:	de943c23          	sd	s1,-520(s0)
    8000518e:	b7c5                	j	8000516e <exec+0x2d2>
    80005190:	de943c23          	sd	s1,-520(s0)
    80005194:	bfe9                	j	8000516e <exec+0x2d2>
  sz = sz1;
    80005196:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000519a:	4a81                	li	s5,0
    8000519c:	bfc9                	j	8000516e <exec+0x2d2>
  sz = sz1;
    8000519e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a2:	4a81                	li	s5,0
    800051a4:	b7e9                	j	8000516e <exec+0x2d2>
  sz = sz1;
    800051a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051aa:	4a81                	li	s5,0
    800051ac:	b7c9                	j	8000516e <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051ae:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b2:	e0843783          	ld	a5,-504(s0)
    800051b6:	0017869b          	addiw	a3,a5,1
    800051ba:	e0d43423          	sd	a3,-504(s0)
    800051be:	e0043783          	ld	a5,-512(s0)
    800051c2:	0387879b          	addiw	a5,a5,56
    800051c6:	e8045703          	lhu	a4,-384(s0)
    800051ca:	e2e6d3e3          	bge	a3,a4,80004ff0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051ce:	2781                	sext.w	a5,a5
    800051d0:	e0f43023          	sd	a5,-512(s0)
    800051d4:	03800713          	li	a4,56
    800051d8:	86be                	mv	a3,a5
    800051da:	e1040613          	addi	a2,s0,-496
    800051de:	4581                	li	a1,0
    800051e0:	8556                	mv	a0,s5
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	a56080e7          	jalr	-1450(ra) # 80003c38 <readi>
    800051ea:	03800793          	li	a5,56
    800051ee:	f6f51ee3          	bne	a0,a5,8000516a <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051f2:	e1042783          	lw	a5,-496(s0)
    800051f6:	4705                	li	a4,1
    800051f8:	fae79de3          	bne	a5,a4,800051b2 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051fc:	e3843603          	ld	a2,-456(s0)
    80005200:	e3043783          	ld	a5,-464(s0)
    80005204:	f8f660e3          	bltu	a2,a5,80005184 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005208:	e2043783          	ld	a5,-480(s0)
    8000520c:	963e                	add	a2,a2,a5
    8000520e:	f6f66ee3          	bltu	a2,a5,8000518a <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005212:	85a6                	mv	a1,s1
    80005214:	855a                	mv	a0,s6
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	244080e7          	jalr	580(ra) # 8000145a <uvmalloc>
    8000521e:	dea43c23          	sd	a0,-520(s0)
    80005222:	d53d                	beqz	a0,80005190 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005224:	e2043c03          	ld	s8,-480(s0)
    80005228:	de043783          	ld	a5,-544(s0)
    8000522c:	00fc77b3          	and	a5,s8,a5
    80005230:	ff9d                	bnez	a5,8000516e <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005232:	e1842c83          	lw	s9,-488(s0)
    80005236:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000523a:	f60b8ae3          	beqz	s7,800051ae <exec+0x312>
    8000523e:	89de                	mv	s3,s7
    80005240:	4481                	li	s1,0
    80005242:	b371                	j	80004fce <exec+0x132>

0000000080005244 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005244:	7179                	addi	sp,sp,-48
    80005246:	f406                	sd	ra,40(sp)
    80005248:	f022                	sd	s0,32(sp)
    8000524a:	ec26                	sd	s1,24(sp)
    8000524c:	e84a                	sd	s2,16(sp)
    8000524e:	1800                	addi	s0,sp,48
    80005250:	892e                	mv	s2,a1
    80005252:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005254:	fdc40593          	addi	a1,s0,-36
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	b8e080e7          	jalr	-1138(ra) # 80002de6 <argint>
    80005260:	04054063          	bltz	a0,800052a0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005264:	fdc42703          	lw	a4,-36(s0)
    80005268:	47bd                	li	a5,15
    8000526a:	02e7ed63          	bltu	a5,a4,800052a4 <argfd+0x60>
    8000526e:	ffffd097          	auipc	ra,0xffffd
    80005272:	8be080e7          	jalr	-1858(ra) # 80001b2c <myproc>
    80005276:	fdc42703          	lw	a4,-36(s0)
    8000527a:	01a70793          	addi	a5,a4,26
    8000527e:	078e                	slli	a5,a5,0x3
    80005280:	953e                	add	a0,a0,a5
    80005282:	611c                	ld	a5,0(a0)
    80005284:	c395                	beqz	a5,800052a8 <argfd+0x64>
    return -1;
  if(pfd)
    80005286:	00090463          	beqz	s2,8000528e <argfd+0x4a>
    *pfd = fd;
    8000528a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000528e:	4501                	li	a0,0
  if(pf)
    80005290:	c091                	beqz	s1,80005294 <argfd+0x50>
    *pf = f;
    80005292:	e09c                	sd	a5,0(s1)
}
    80005294:	70a2                	ld	ra,40(sp)
    80005296:	7402                	ld	s0,32(sp)
    80005298:	64e2                	ld	s1,24(sp)
    8000529a:	6942                	ld	s2,16(sp)
    8000529c:	6145                	addi	sp,sp,48
    8000529e:	8082                	ret
    return -1;
    800052a0:	557d                	li	a0,-1
    800052a2:	bfcd                	j	80005294 <argfd+0x50>
    return -1;
    800052a4:	557d                	li	a0,-1
    800052a6:	b7fd                	j	80005294 <argfd+0x50>
    800052a8:	557d                	li	a0,-1
    800052aa:	b7ed                	j	80005294 <argfd+0x50>

00000000800052ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ac:	1101                	addi	sp,sp,-32
    800052ae:	ec06                	sd	ra,24(sp)
    800052b0:	e822                	sd	s0,16(sp)
    800052b2:	e426                	sd	s1,8(sp)
    800052b4:	1000                	addi	s0,sp,32
    800052b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052b8:	ffffd097          	auipc	ra,0xffffd
    800052bc:	874080e7          	jalr	-1932(ra) # 80001b2c <myproc>
    800052c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052c2:	0d050793          	addi	a5,a0,208
    800052c6:	4501                	li	a0,0
    800052c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ca:	6398                	ld	a4,0(a5)
    800052cc:	cb19                	beqz	a4,800052e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052ce:	2505                	addiw	a0,a0,1
    800052d0:	07a1                	addi	a5,a5,8
    800052d2:	fed51ce3          	bne	a0,a3,800052ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052d6:	557d                	li	a0,-1
}
    800052d8:	60e2                	ld	ra,24(sp)
    800052da:	6442                	ld	s0,16(sp)
    800052dc:	64a2                	ld	s1,8(sp)
    800052de:	6105                	addi	sp,sp,32
    800052e0:	8082                	ret
      p->ofile[fd] = f;
    800052e2:	01a50793          	addi	a5,a0,26
    800052e6:	078e                	slli	a5,a5,0x3
    800052e8:	963e                	add	a2,a2,a5
    800052ea:	e204                	sd	s1,0(a2)
      return fd;
    800052ec:	b7f5                	j	800052d8 <fdalloc+0x2c>

00000000800052ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ee:	715d                	addi	sp,sp,-80
    800052f0:	e486                	sd	ra,72(sp)
    800052f2:	e0a2                	sd	s0,64(sp)
    800052f4:	fc26                	sd	s1,56(sp)
    800052f6:	f84a                	sd	s2,48(sp)
    800052f8:	f44e                	sd	s3,40(sp)
    800052fa:	f052                	sd	s4,32(sp)
    800052fc:	ec56                	sd	s5,24(sp)
    800052fe:	0880                	addi	s0,sp,80
    80005300:	89ae                	mv	s3,a1
    80005302:	8ab2                	mv	s5,a2
    80005304:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005306:	fb040593          	addi	a1,s0,-80
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	e48080e7          	jalr	-440(ra) # 80004152 <nameiparent>
    80005312:	892a                	mv	s2,a0
    80005314:	12050e63          	beqz	a0,80005450 <create+0x162>
    return 0;

  ilock(dp);
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	66c080e7          	jalr	1644(ra) # 80003984 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005320:	4601                	li	a2,0
    80005322:	fb040593          	addi	a1,s0,-80
    80005326:	854a                	mv	a0,s2
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	b3a080e7          	jalr	-1222(ra) # 80003e62 <dirlookup>
    80005330:	84aa                	mv	s1,a0
    80005332:	c921                	beqz	a0,80005382 <create+0x94>
    iunlockput(dp);
    80005334:	854a                	mv	a0,s2
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	8b0080e7          	jalr	-1872(ra) # 80003be6 <iunlockput>
    ilock(ip);
    8000533e:	8526                	mv	a0,s1
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	644080e7          	jalr	1604(ra) # 80003984 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005348:	2981                	sext.w	s3,s3
    8000534a:	4789                	li	a5,2
    8000534c:	02f99463          	bne	s3,a5,80005374 <create+0x86>
    80005350:	0444d783          	lhu	a5,68(s1)
    80005354:	37f9                	addiw	a5,a5,-2
    80005356:	17c2                	slli	a5,a5,0x30
    80005358:	93c1                	srli	a5,a5,0x30
    8000535a:	4705                	li	a4,1
    8000535c:	00f76c63          	bltu	a4,a5,80005374 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005360:	8526                	mv	a0,s1
    80005362:	60a6                	ld	ra,72(sp)
    80005364:	6406                	ld	s0,64(sp)
    80005366:	74e2                	ld	s1,56(sp)
    80005368:	7942                	ld	s2,48(sp)
    8000536a:	79a2                	ld	s3,40(sp)
    8000536c:	7a02                	ld	s4,32(sp)
    8000536e:	6ae2                	ld	s5,24(sp)
    80005370:	6161                	addi	sp,sp,80
    80005372:	8082                	ret
    iunlockput(ip);
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	870080e7          	jalr	-1936(ra) # 80003be6 <iunlockput>
    return 0;
    8000537e:	4481                	li	s1,0
    80005380:	b7c5                	j	80005360 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005382:	85ce                	mv	a1,s3
    80005384:	00092503          	lw	a0,0(s2)
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	464080e7          	jalr	1124(ra) # 800037ec <ialloc>
    80005390:	84aa                	mv	s1,a0
    80005392:	c521                	beqz	a0,800053da <create+0xec>
  ilock(ip);
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	5f0080e7          	jalr	1520(ra) # 80003984 <ilock>
  ip->major = major;
    8000539c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053a0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053a4:	4a05                	li	s4,1
    800053a6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053aa:	8526                	mv	a0,s1
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	50e080e7          	jalr	1294(ra) # 800038ba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053b4:	2981                	sext.w	s3,s3
    800053b6:	03498a63          	beq	s3,s4,800053ea <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053ba:	40d0                	lw	a2,4(s1)
    800053bc:	fb040593          	addi	a1,s0,-80
    800053c0:	854a                	mv	a0,s2
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	cb0080e7          	jalr	-848(ra) # 80004072 <dirlink>
    800053ca:	06054b63          	bltz	a0,80005440 <create+0x152>
  iunlockput(dp);
    800053ce:	854a                	mv	a0,s2
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	816080e7          	jalr	-2026(ra) # 80003be6 <iunlockput>
  return ip;
    800053d8:	b761                	j	80005360 <create+0x72>
    panic("create: ialloc");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	35e50513          	addi	a0,a0,862 # 80008738 <syscalls+0x2b0>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053ea:	04a95783          	lhu	a5,74(s2)
    800053ee:	2785                	addiw	a5,a5,1
    800053f0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053f4:	854a                	mv	a0,s2
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	4c4080e7          	jalr	1220(ra) # 800038ba <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053fe:	40d0                	lw	a2,4(s1)
    80005400:	00003597          	auipc	a1,0x3
    80005404:	34858593          	addi	a1,a1,840 # 80008748 <syscalls+0x2c0>
    80005408:	8526                	mv	a0,s1
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	c68080e7          	jalr	-920(ra) # 80004072 <dirlink>
    80005412:	00054f63          	bltz	a0,80005430 <create+0x142>
    80005416:	00492603          	lw	a2,4(s2)
    8000541a:	00003597          	auipc	a1,0x3
    8000541e:	33658593          	addi	a1,a1,822 # 80008750 <syscalls+0x2c8>
    80005422:	8526                	mv	a0,s1
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	c4e080e7          	jalr	-946(ra) # 80004072 <dirlink>
    8000542c:	f80557e3          	bgez	a0,800053ba <create+0xcc>
      panic("create dots");
    80005430:	00003517          	auipc	a0,0x3
    80005434:	32850513          	addi	a0,a0,808 # 80008758 <syscalls+0x2d0>
    80005438:	ffffb097          	auipc	ra,0xffffb
    8000543c:	108080e7          	jalr	264(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005440:	00003517          	auipc	a0,0x3
    80005444:	32850513          	addi	a0,a0,808 # 80008768 <syscalls+0x2e0>
    80005448:	ffffb097          	auipc	ra,0xffffb
    8000544c:	0f8080e7          	jalr	248(ra) # 80000540 <panic>
    return 0;
    80005450:	84aa                	mv	s1,a0
    80005452:	b739                	j	80005360 <create+0x72>

0000000080005454 <sys_dup>:
{
    80005454:	7179                	addi	sp,sp,-48
    80005456:	f406                	sd	ra,40(sp)
    80005458:	f022                	sd	s0,32(sp)
    8000545a:	ec26                	sd	s1,24(sp)
    8000545c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000545e:	fd840613          	addi	a2,s0,-40
    80005462:	4581                	li	a1,0
    80005464:	4501                	li	a0,0
    80005466:	00000097          	auipc	ra,0x0
    8000546a:	dde080e7          	jalr	-546(ra) # 80005244 <argfd>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005470:	02054363          	bltz	a0,80005496 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005474:	fd843503          	ld	a0,-40(s0)
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	e34080e7          	jalr	-460(ra) # 800052ac <fdalloc>
    80005480:	84aa                	mv	s1,a0
    return -1;
    80005482:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005484:	00054963          	bltz	a0,80005496 <sys_dup+0x42>
  filedup(f);
    80005488:	fd843503          	ld	a0,-40(s0)
    8000548c:	fffff097          	auipc	ra,0xfffff
    80005490:	338080e7          	jalr	824(ra) # 800047c4 <filedup>
  return fd;
    80005494:	87a6                	mv	a5,s1
}
    80005496:	853e                	mv	a0,a5
    80005498:	70a2                	ld	ra,40(sp)
    8000549a:	7402                	ld	s0,32(sp)
    8000549c:	64e2                	ld	s1,24(sp)
    8000549e:	6145                	addi	sp,sp,48
    800054a0:	8082                	ret

00000000800054a2 <sys_read>:
{
    800054a2:	7179                	addi	sp,sp,-48
    800054a4:	f406                	sd	ra,40(sp)
    800054a6:	f022                	sd	s0,32(sp)
    800054a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054aa:	fe840613          	addi	a2,s0,-24
    800054ae:	4581                	li	a1,0
    800054b0:	4501                	li	a0,0
    800054b2:	00000097          	auipc	ra,0x0
    800054b6:	d92080e7          	jalr	-622(ra) # 80005244 <argfd>
    return -1;
    800054ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054bc:	04054163          	bltz	a0,800054fe <sys_read+0x5c>
    800054c0:	fe440593          	addi	a1,s0,-28
    800054c4:	4509                	li	a0,2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	920080e7          	jalr	-1760(ra) # 80002de6 <argint>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d0:	02054763          	bltz	a0,800054fe <sys_read+0x5c>
    800054d4:	fd840593          	addi	a1,s0,-40
    800054d8:	4505                	li	a0,1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	92e080e7          	jalr	-1746(ra) # 80002e08 <argaddr>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	00054d63          	bltz	a0,800054fe <sys_read+0x5c>
  return fileread(f, p, n);
    800054e8:	fe442603          	lw	a2,-28(s0)
    800054ec:	fd843583          	ld	a1,-40(s0)
    800054f0:	fe843503          	ld	a0,-24(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	45c080e7          	jalr	1116(ra) # 80004950 <fileread>
    800054fc:	87aa                	mv	a5,a0
}
    800054fe:	853e                	mv	a0,a5
    80005500:	70a2                	ld	ra,40(sp)
    80005502:	7402                	ld	s0,32(sp)
    80005504:	6145                	addi	sp,sp,48
    80005506:	8082                	ret

0000000080005508 <sys_write>:
{
    80005508:	7179                	addi	sp,sp,-48
    8000550a:	f406                	sd	ra,40(sp)
    8000550c:	f022                	sd	s0,32(sp)
    8000550e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005510:	fe840613          	addi	a2,s0,-24
    80005514:	4581                	li	a1,0
    80005516:	4501                	li	a0,0
    80005518:	00000097          	auipc	ra,0x0
    8000551c:	d2c080e7          	jalr	-724(ra) # 80005244 <argfd>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005522:	04054163          	bltz	a0,80005564 <sys_write+0x5c>
    80005526:	fe440593          	addi	a1,s0,-28
    8000552a:	4509                	li	a0,2
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	8ba080e7          	jalr	-1862(ra) # 80002de6 <argint>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005536:	02054763          	bltz	a0,80005564 <sys_write+0x5c>
    8000553a:	fd840593          	addi	a1,s0,-40
    8000553e:	4505                	li	a0,1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	8c8080e7          	jalr	-1848(ra) # 80002e08 <argaddr>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554a:	00054d63          	bltz	a0,80005564 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000554e:	fe442603          	lw	a2,-28(s0)
    80005552:	fd843583          	ld	a1,-40(s0)
    80005556:	fe843503          	ld	a0,-24(s0)
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	4b8080e7          	jalr	1208(ra) # 80004a12 <filewrite>
    80005562:	87aa                	mv	a5,a0
}
    80005564:	853e                	mv	a0,a5
    80005566:	70a2                	ld	ra,40(sp)
    80005568:	7402                	ld	s0,32(sp)
    8000556a:	6145                	addi	sp,sp,48
    8000556c:	8082                	ret

000000008000556e <sys_close>:
{
    8000556e:	1101                	addi	sp,sp,-32
    80005570:	ec06                	sd	ra,24(sp)
    80005572:	e822                	sd	s0,16(sp)
    80005574:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005576:	fe040613          	addi	a2,s0,-32
    8000557a:	fec40593          	addi	a1,s0,-20
    8000557e:	4501                	li	a0,0
    80005580:	00000097          	auipc	ra,0x0
    80005584:	cc4080e7          	jalr	-828(ra) # 80005244 <argfd>
    return -1;
    80005588:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000558a:	02054463          	bltz	a0,800055b2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000558e:	ffffc097          	auipc	ra,0xffffc
    80005592:	59e080e7          	jalr	1438(ra) # 80001b2c <myproc>
    80005596:	fec42783          	lw	a5,-20(s0)
    8000559a:	07e9                	addi	a5,a5,26
    8000559c:	078e                	slli	a5,a5,0x3
    8000559e:	97aa                	add	a5,a5,a0
    800055a0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055a4:	fe043503          	ld	a0,-32(s0)
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	26e080e7          	jalr	622(ra) # 80004816 <fileclose>
  return 0;
    800055b0:	4781                	li	a5,0
}
    800055b2:	853e                	mv	a0,a5
    800055b4:	60e2                	ld	ra,24(sp)
    800055b6:	6442                	ld	s0,16(sp)
    800055b8:	6105                	addi	sp,sp,32
    800055ba:	8082                	ret

00000000800055bc <sys_fstat>:
{
    800055bc:	1101                	addi	sp,sp,-32
    800055be:	ec06                	sd	ra,24(sp)
    800055c0:	e822                	sd	s0,16(sp)
    800055c2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c4:	fe840613          	addi	a2,s0,-24
    800055c8:	4581                	li	a1,0
    800055ca:	4501                	li	a0,0
    800055cc:	00000097          	auipc	ra,0x0
    800055d0:	c78080e7          	jalr	-904(ra) # 80005244 <argfd>
    return -1;
    800055d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d6:	02054563          	bltz	a0,80005600 <sys_fstat+0x44>
    800055da:	fe040593          	addi	a1,s0,-32
    800055de:	4505                	li	a0,1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	828080e7          	jalr	-2008(ra) # 80002e08 <argaddr>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ea:	00054b63          	bltz	a0,80005600 <sys_fstat+0x44>
  return filestat(f, st);
    800055ee:	fe043583          	ld	a1,-32(s0)
    800055f2:	fe843503          	ld	a0,-24(s0)
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	2e8080e7          	jalr	744(ra) # 800048de <filestat>
    800055fe:	87aa                	mv	a5,a0
}
    80005600:	853e                	mv	a0,a5
    80005602:	60e2                	ld	ra,24(sp)
    80005604:	6442                	ld	s0,16(sp)
    80005606:	6105                	addi	sp,sp,32
    80005608:	8082                	ret

000000008000560a <sys_link>:
{
    8000560a:	7169                	addi	sp,sp,-304
    8000560c:	f606                	sd	ra,296(sp)
    8000560e:	f222                	sd	s0,288(sp)
    80005610:	ee26                	sd	s1,280(sp)
    80005612:	ea4a                	sd	s2,272(sp)
    80005614:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005616:	08000613          	li	a2,128
    8000561a:	ed040593          	addi	a1,s0,-304
    8000561e:	4501                	li	a0,0
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	80a080e7          	jalr	-2038(ra) # 80002e2a <argstr>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562a:	10054e63          	bltz	a0,80005746 <sys_link+0x13c>
    8000562e:	08000613          	li	a2,128
    80005632:	f5040593          	addi	a1,s0,-176
    80005636:	4505                	li	a0,1
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	7f2080e7          	jalr	2034(ra) # 80002e2a <argstr>
    return -1;
    80005640:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005642:	10054263          	bltz	a0,80005746 <sys_link+0x13c>
  begin_op();
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	cfe080e7          	jalr	-770(ra) # 80004344 <begin_op>
  if((ip = namei(old)) == 0){
    8000564e:	ed040513          	addi	a0,s0,-304
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	ae2080e7          	jalr	-1310(ra) # 80004134 <namei>
    8000565a:	84aa                	mv	s1,a0
    8000565c:	c551                	beqz	a0,800056e8 <sys_link+0xde>
  ilock(ip);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	326080e7          	jalr	806(ra) # 80003984 <ilock>
  if(ip->type == T_DIR){
    80005666:	04449703          	lh	a4,68(s1)
    8000566a:	4785                	li	a5,1
    8000566c:	08f70463          	beq	a4,a5,800056f4 <sys_link+0xea>
  ip->nlink++;
    80005670:	04a4d783          	lhu	a5,74(s1)
    80005674:	2785                	addiw	a5,a5,1
    80005676:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	23e080e7          	jalr	574(ra) # 800038ba <iupdate>
  iunlock(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	3c0080e7          	jalr	960(ra) # 80003a46 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000568e:	fd040593          	addi	a1,s0,-48
    80005692:	f5040513          	addi	a0,s0,-176
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	abc080e7          	jalr	-1348(ra) # 80004152 <nameiparent>
    8000569e:	892a                	mv	s2,a0
    800056a0:	c935                	beqz	a0,80005714 <sys_link+0x10a>
  ilock(dp);
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	2e2080e7          	jalr	738(ra) # 80003984 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056aa:	00092703          	lw	a4,0(s2)
    800056ae:	409c                	lw	a5,0(s1)
    800056b0:	04f71d63          	bne	a4,a5,8000570a <sys_link+0x100>
    800056b4:	40d0                	lw	a2,4(s1)
    800056b6:	fd040593          	addi	a1,s0,-48
    800056ba:	854a                	mv	a0,s2
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9b6080e7          	jalr	-1610(ra) # 80004072 <dirlink>
    800056c4:	04054363          	bltz	a0,8000570a <sys_link+0x100>
  iunlockput(dp);
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	51c080e7          	jalr	1308(ra) # 80003be6 <iunlockput>
  iput(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	46a080e7          	jalr	1130(ra) # 80003b3e <iput>
  end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	ce8080e7          	jalr	-792(ra) # 800043c4 <end_op>
  return 0;
    800056e4:	4781                	li	a5,0
    800056e6:	a085                	j	80005746 <sys_link+0x13c>
    end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	cdc080e7          	jalr	-804(ra) # 800043c4 <end_op>
    return -1;
    800056f0:	57fd                	li	a5,-1
    800056f2:	a891                	j	80005746 <sys_link+0x13c>
    iunlockput(ip);
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	4f0080e7          	jalr	1264(ra) # 80003be6 <iunlockput>
    end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	cc6080e7          	jalr	-826(ra) # 800043c4 <end_op>
    return -1;
    80005706:	57fd                	li	a5,-1
    80005708:	a83d                	j	80005746 <sys_link+0x13c>
    iunlockput(dp);
    8000570a:	854a                	mv	a0,s2
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	4da080e7          	jalr	1242(ra) # 80003be6 <iunlockput>
  ilock(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	26e080e7          	jalr	622(ra) # 80003984 <ilock>
  ip->nlink--;
    8000571e:	04a4d783          	lhu	a5,74(s1)
    80005722:	37fd                	addiw	a5,a5,-1
    80005724:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	190080e7          	jalr	400(ra) # 800038ba <iupdate>
  iunlockput(ip);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	4b2080e7          	jalr	1202(ra) # 80003be6 <iunlockput>
  end_op();
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	c88080e7          	jalr	-888(ra) # 800043c4 <end_op>
  return -1;
    80005744:	57fd                	li	a5,-1
}
    80005746:	853e                	mv	a0,a5
    80005748:	70b2                	ld	ra,296(sp)
    8000574a:	7412                	ld	s0,288(sp)
    8000574c:	64f2                	ld	s1,280(sp)
    8000574e:	6952                	ld	s2,272(sp)
    80005750:	6155                	addi	sp,sp,304
    80005752:	8082                	ret

0000000080005754 <sys_unlink>:
{
    80005754:	7151                	addi	sp,sp,-240
    80005756:	f586                	sd	ra,232(sp)
    80005758:	f1a2                	sd	s0,224(sp)
    8000575a:	eda6                	sd	s1,216(sp)
    8000575c:	e9ca                	sd	s2,208(sp)
    8000575e:	e5ce                	sd	s3,200(sp)
    80005760:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005762:	08000613          	li	a2,128
    80005766:	f3040593          	addi	a1,s0,-208
    8000576a:	4501                	li	a0,0
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	6be080e7          	jalr	1726(ra) # 80002e2a <argstr>
    80005774:	18054163          	bltz	a0,800058f6 <sys_unlink+0x1a2>
  begin_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	bcc080e7          	jalr	-1076(ra) # 80004344 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	f3040513          	addi	a0,s0,-208
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	9ca080e7          	jalr	-1590(ra) # 80004152 <nameiparent>
    80005790:	84aa                	mv	s1,a0
    80005792:	c979                	beqz	a0,80005868 <sys_unlink+0x114>
  ilock(dp);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	1f0080e7          	jalr	496(ra) # 80003984 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000579c:	00003597          	auipc	a1,0x3
    800057a0:	fac58593          	addi	a1,a1,-84 # 80008748 <syscalls+0x2c0>
    800057a4:	fb040513          	addi	a0,s0,-80
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	6a0080e7          	jalr	1696(ra) # 80003e48 <namecmp>
    800057b0:	14050a63          	beqz	a0,80005904 <sys_unlink+0x1b0>
    800057b4:	00003597          	auipc	a1,0x3
    800057b8:	f9c58593          	addi	a1,a1,-100 # 80008750 <syscalls+0x2c8>
    800057bc:	fb040513          	addi	a0,s0,-80
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	688080e7          	jalr	1672(ra) # 80003e48 <namecmp>
    800057c8:	12050e63          	beqz	a0,80005904 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057cc:	f2c40613          	addi	a2,s0,-212
    800057d0:	fb040593          	addi	a1,s0,-80
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	68c080e7          	jalr	1676(ra) # 80003e62 <dirlookup>
    800057de:	892a                	mv	s2,a0
    800057e0:	12050263          	beqz	a0,80005904 <sys_unlink+0x1b0>
  ilock(ip);
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	1a0080e7          	jalr	416(ra) # 80003984 <ilock>
  if(ip->nlink < 1)
    800057ec:	04a91783          	lh	a5,74(s2)
    800057f0:	08f05263          	blez	a5,80005874 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057f4:	04491703          	lh	a4,68(s2)
    800057f8:	4785                	li	a5,1
    800057fa:	08f70563          	beq	a4,a5,80005884 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057fe:	4641                	li	a2,16
    80005800:	4581                	li	a1,0
    80005802:	fc040513          	addi	a0,s0,-64
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	4f2080e7          	jalr	1266(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000580e:	4741                	li	a4,16
    80005810:	f2c42683          	lw	a3,-212(s0)
    80005814:	fc040613          	addi	a2,s0,-64
    80005818:	4581                	li	a1,0
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	512080e7          	jalr	1298(ra) # 80003d2e <writei>
    80005824:	47c1                	li	a5,16
    80005826:	0af51563          	bne	a0,a5,800058d0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000582a:	04491703          	lh	a4,68(s2)
    8000582e:	4785                	li	a5,1
    80005830:	0af70863          	beq	a4,a5,800058e0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	3b0080e7          	jalr	944(ra) # 80003be6 <iunlockput>
  ip->nlink--;
    8000583e:	04a95783          	lhu	a5,74(s2)
    80005842:	37fd                	addiw	a5,a5,-1
    80005844:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	070080e7          	jalr	112(ra) # 800038ba <iupdate>
  iunlockput(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	392080e7          	jalr	914(ra) # 80003be6 <iunlockput>
  end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	b68080e7          	jalr	-1176(ra) # 800043c4 <end_op>
  return 0;
    80005864:	4501                	li	a0,0
    80005866:	a84d                	j	80005918 <sys_unlink+0x1c4>
    end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	b5c080e7          	jalr	-1188(ra) # 800043c4 <end_op>
    return -1;
    80005870:	557d                	li	a0,-1
    80005872:	a05d                	j	80005918 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005874:	00003517          	auipc	a0,0x3
    80005878:	f0450513          	addi	a0,a0,-252 # 80008778 <syscalls+0x2f0>
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	cc4080e7          	jalr	-828(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005884:	04c92703          	lw	a4,76(s2)
    80005888:	02000793          	li	a5,32
    8000588c:	f6e7f9e3          	bgeu	a5,a4,800057fe <sys_unlink+0xaa>
    80005890:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005894:	4741                	li	a4,16
    80005896:	86ce                	mv	a3,s3
    80005898:	f1840613          	addi	a2,s0,-232
    8000589c:	4581                	li	a1,0
    8000589e:	854a                	mv	a0,s2
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	398080e7          	jalr	920(ra) # 80003c38 <readi>
    800058a8:	47c1                	li	a5,16
    800058aa:	00f51b63          	bne	a0,a5,800058c0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058ae:	f1845783          	lhu	a5,-232(s0)
    800058b2:	e7a1                	bnez	a5,800058fa <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b4:	29c1                	addiw	s3,s3,16
    800058b6:	04c92783          	lw	a5,76(s2)
    800058ba:	fcf9ede3          	bltu	s3,a5,80005894 <sys_unlink+0x140>
    800058be:	b781                	j	800057fe <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058c0:	00003517          	auipc	a0,0x3
    800058c4:	ed050513          	addi	a0,a0,-304 # 80008790 <syscalls+0x308>
    800058c8:	ffffb097          	auipc	ra,0xffffb
    800058cc:	c78080e7          	jalr	-904(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058d0:	00003517          	auipc	a0,0x3
    800058d4:	ed850513          	addi	a0,a0,-296 # 800087a8 <syscalls+0x320>
    800058d8:	ffffb097          	auipc	ra,0xffffb
    800058dc:	c68080e7          	jalr	-920(ra) # 80000540 <panic>
    dp->nlink--;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	37fd                	addiw	a5,a5,-1
    800058e6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	fce080e7          	jalr	-50(ra) # 800038ba <iupdate>
    800058f4:	b781                	j	80005834 <sys_unlink+0xe0>
    return -1;
    800058f6:	557d                	li	a0,-1
    800058f8:	a005                	j	80005918 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058fa:	854a                	mv	a0,s2
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	2ea080e7          	jalr	746(ra) # 80003be6 <iunlockput>
  iunlockput(dp);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	2e0080e7          	jalr	736(ra) # 80003be6 <iunlockput>
  end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	ab6080e7          	jalr	-1354(ra) # 800043c4 <end_op>
  return -1;
    80005916:	557d                	li	a0,-1
}
    80005918:	70ae                	ld	ra,232(sp)
    8000591a:	740e                	ld	s0,224(sp)
    8000591c:	64ee                	ld	s1,216(sp)
    8000591e:	694e                	ld	s2,208(sp)
    80005920:	69ae                	ld	s3,200(sp)
    80005922:	616d                	addi	sp,sp,240
    80005924:	8082                	ret

0000000080005926 <sys_open>:

uint64
sys_open(void)
{
    80005926:	7131                	addi	sp,sp,-192
    80005928:	fd06                	sd	ra,184(sp)
    8000592a:	f922                	sd	s0,176(sp)
    8000592c:	f526                	sd	s1,168(sp)
    8000592e:	f14a                	sd	s2,160(sp)
    80005930:	ed4e                	sd	s3,152(sp)
    80005932:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005934:	08000613          	li	a2,128
    80005938:	f5040593          	addi	a1,s0,-176
    8000593c:	4501                	li	a0,0
    8000593e:	ffffd097          	auipc	ra,0xffffd
    80005942:	4ec080e7          	jalr	1260(ra) # 80002e2a <argstr>
    return -1;
    80005946:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005948:	0c054163          	bltz	a0,80005a0a <sys_open+0xe4>
    8000594c:	f4c40593          	addi	a1,s0,-180
    80005950:	4505                	li	a0,1
    80005952:	ffffd097          	auipc	ra,0xffffd
    80005956:	494080e7          	jalr	1172(ra) # 80002de6 <argint>
    8000595a:	0a054863          	bltz	a0,80005a0a <sys_open+0xe4>

  begin_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	9e6080e7          	jalr	-1562(ra) # 80004344 <begin_op>

  if(omode & O_CREATE){
    80005966:	f4c42783          	lw	a5,-180(s0)
    8000596a:	2007f793          	andi	a5,a5,512
    8000596e:	cbdd                	beqz	a5,80005a24 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005970:	4681                	li	a3,0
    80005972:	4601                	li	a2,0
    80005974:	4589                	li	a1,2
    80005976:	f5040513          	addi	a0,s0,-176
    8000597a:	00000097          	auipc	ra,0x0
    8000597e:	974080e7          	jalr	-1676(ra) # 800052ee <create>
    80005982:	892a                	mv	s2,a0
    if(ip == 0){
    80005984:	c959                	beqz	a0,80005a1a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005986:	04491703          	lh	a4,68(s2)
    8000598a:	478d                	li	a5,3
    8000598c:	00f71763          	bne	a4,a5,8000599a <sys_open+0x74>
    80005990:	04695703          	lhu	a4,70(s2)
    80005994:	47a5                	li	a5,9
    80005996:	0ce7ec63          	bltu	a5,a4,80005a6e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	dc0080e7          	jalr	-576(ra) # 8000475a <filealloc>
    800059a2:	89aa                	mv	s3,a0
    800059a4:	10050263          	beqz	a0,80005aa8 <sys_open+0x182>
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	904080e7          	jalr	-1788(ra) # 800052ac <fdalloc>
    800059b0:	84aa                	mv	s1,a0
    800059b2:	0e054663          	bltz	a0,80005a9e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059b6:	04491703          	lh	a4,68(s2)
    800059ba:	478d                	li	a5,3
    800059bc:	0cf70463          	beq	a4,a5,80005a84 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059c0:	4789                	li	a5,2
    800059c2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059c6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059ca:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059ce:	f4c42783          	lw	a5,-180(s0)
    800059d2:	0017c713          	xori	a4,a5,1
    800059d6:	8b05                	andi	a4,a4,1
    800059d8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059dc:	0037f713          	andi	a4,a5,3
    800059e0:	00e03733          	snez	a4,a4
    800059e4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059e8:	4007f793          	andi	a5,a5,1024
    800059ec:	c791                	beqz	a5,800059f8 <sys_open+0xd2>
    800059ee:	04491703          	lh	a4,68(s2)
    800059f2:	4789                	li	a5,2
    800059f4:	08f70f63          	beq	a4,a5,80005a92 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059f8:	854a                	mv	a0,s2
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	04c080e7          	jalr	76(ra) # 80003a46 <iunlock>
  end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	9c2080e7          	jalr	-1598(ra) # 800043c4 <end_op>

  return fd;
}
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	70ea                	ld	ra,184(sp)
    80005a0e:	744a                	ld	s0,176(sp)
    80005a10:	74aa                	ld	s1,168(sp)
    80005a12:	790a                	ld	s2,160(sp)
    80005a14:	69ea                	ld	s3,152(sp)
    80005a16:	6129                	addi	sp,sp,192
    80005a18:	8082                	ret
      end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	9aa080e7          	jalr	-1622(ra) # 800043c4 <end_op>
      return -1;
    80005a22:	b7e5                	j	80005a0a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a24:	f5040513          	addi	a0,s0,-176
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	70c080e7          	jalr	1804(ra) # 80004134 <namei>
    80005a30:	892a                	mv	s2,a0
    80005a32:	c905                	beqz	a0,80005a62 <sys_open+0x13c>
    ilock(ip);
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	f50080e7          	jalr	-176(ra) # 80003984 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a3c:	04491703          	lh	a4,68(s2)
    80005a40:	4785                	li	a5,1
    80005a42:	f4f712e3          	bne	a4,a5,80005986 <sys_open+0x60>
    80005a46:	f4c42783          	lw	a5,-180(s0)
    80005a4a:	dba1                	beqz	a5,8000599a <sys_open+0x74>
      iunlockput(ip);
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	198080e7          	jalr	408(ra) # 80003be6 <iunlockput>
      end_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	96e080e7          	jalr	-1682(ra) # 800043c4 <end_op>
      return -1;
    80005a5e:	54fd                	li	s1,-1
    80005a60:	b76d                	j	80005a0a <sys_open+0xe4>
      end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	962080e7          	jalr	-1694(ra) # 800043c4 <end_op>
      return -1;
    80005a6a:	54fd                	li	s1,-1
    80005a6c:	bf79                	j	80005a0a <sys_open+0xe4>
    iunlockput(ip);
    80005a6e:	854a                	mv	a0,s2
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	176080e7          	jalr	374(ra) # 80003be6 <iunlockput>
    end_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	94c080e7          	jalr	-1716(ra) # 800043c4 <end_op>
    return -1;
    80005a80:	54fd                	li	s1,-1
    80005a82:	b761                	j	80005a0a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a84:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a88:	04691783          	lh	a5,70(s2)
    80005a8c:	02f99223          	sh	a5,36(s3)
    80005a90:	bf2d                	j	800059ca <sys_open+0xa4>
    itrunc(ip);
    80005a92:	854a                	mv	a0,s2
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	ffe080e7          	jalr	-2(ra) # 80003a92 <itrunc>
    80005a9c:	bfb1                	j	800059f8 <sys_open+0xd2>
      fileclose(f);
    80005a9e:	854e                	mv	a0,s3
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	d76080e7          	jalr	-650(ra) # 80004816 <fileclose>
    iunlockput(ip);
    80005aa8:	854a                	mv	a0,s2
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	13c080e7          	jalr	316(ra) # 80003be6 <iunlockput>
    end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	912080e7          	jalr	-1774(ra) # 800043c4 <end_op>
    return -1;
    80005aba:	54fd                	li	s1,-1
    80005abc:	b7b9                	j	80005a0a <sys_open+0xe4>

0000000080005abe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005abe:	7175                	addi	sp,sp,-144
    80005ac0:	e506                	sd	ra,136(sp)
    80005ac2:	e122                	sd	s0,128(sp)
    80005ac4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	87e080e7          	jalr	-1922(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ace:	08000613          	li	a2,128
    80005ad2:	f7040593          	addi	a1,s0,-144
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	352080e7          	jalr	850(ra) # 80002e2a <argstr>
    80005ae0:	02054963          	bltz	a0,80005b12 <sys_mkdir+0x54>
    80005ae4:	4681                	li	a3,0
    80005ae6:	4601                	li	a2,0
    80005ae8:	4585                	li	a1,1
    80005aea:	f7040513          	addi	a0,s0,-144
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	800080e7          	jalr	-2048(ra) # 800052ee <create>
    80005af6:	cd11                	beqz	a0,80005b12 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	0ee080e7          	jalr	238(ra) # 80003be6 <iunlockput>
  end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	8c4080e7          	jalr	-1852(ra) # 800043c4 <end_op>
  return 0;
    80005b08:	4501                	li	a0,0
}
    80005b0a:	60aa                	ld	ra,136(sp)
    80005b0c:	640a                	ld	s0,128(sp)
    80005b0e:	6149                	addi	sp,sp,144
    80005b10:	8082                	ret
    end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	8b2080e7          	jalr	-1870(ra) # 800043c4 <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
    80005b1c:	b7fd                	j	80005b0a <sys_mkdir+0x4c>

0000000080005b1e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b1e:	7135                	addi	sp,sp,-160
    80005b20:	ed06                	sd	ra,152(sp)
    80005b22:	e922                	sd	s0,144(sp)
    80005b24:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	81e080e7          	jalr	-2018(ra) # 80004344 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b2e:	08000613          	li	a2,128
    80005b32:	f7040593          	addi	a1,s0,-144
    80005b36:	4501                	li	a0,0
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	2f2080e7          	jalr	754(ra) # 80002e2a <argstr>
    80005b40:	04054a63          	bltz	a0,80005b94 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b44:	f6c40593          	addi	a1,s0,-148
    80005b48:	4505                	li	a0,1
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	29c080e7          	jalr	668(ra) # 80002de6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b52:	04054163          	bltz	a0,80005b94 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b56:	f6840593          	addi	a1,s0,-152
    80005b5a:	4509                	li	a0,2
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	28a080e7          	jalr	650(ra) # 80002de6 <argint>
     argint(1, &major) < 0 ||
    80005b64:	02054863          	bltz	a0,80005b94 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b68:	f6841683          	lh	a3,-152(s0)
    80005b6c:	f6c41603          	lh	a2,-148(s0)
    80005b70:	458d                	li	a1,3
    80005b72:	f7040513          	addi	a0,s0,-144
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	778080e7          	jalr	1912(ra) # 800052ee <create>
     argint(2, &minor) < 0 ||
    80005b7e:	c919                	beqz	a0,80005b94 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	066080e7          	jalr	102(ra) # 80003be6 <iunlockput>
  end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	83c080e7          	jalr	-1988(ra) # 800043c4 <end_op>
  return 0;
    80005b90:	4501                	li	a0,0
    80005b92:	a031                	j	80005b9e <sys_mknod+0x80>
    end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	830080e7          	jalr	-2000(ra) # 800043c4 <end_op>
    return -1;
    80005b9c:	557d                	li	a0,-1
}
    80005b9e:	60ea                	ld	ra,152(sp)
    80005ba0:	644a                	ld	s0,144(sp)
    80005ba2:	610d                	addi	sp,sp,160
    80005ba4:	8082                	ret

0000000080005ba6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ba6:	7135                	addi	sp,sp,-160
    80005ba8:	ed06                	sd	ra,152(sp)
    80005baa:	e922                	sd	s0,144(sp)
    80005bac:	e526                	sd	s1,136(sp)
    80005bae:	e14a                	sd	s2,128(sp)
    80005bb0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bb2:	ffffc097          	auipc	ra,0xffffc
    80005bb6:	f7a080e7          	jalr	-134(ra) # 80001b2c <myproc>
    80005bba:	892a                	mv	s2,a0
  
  begin_op();
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	788080e7          	jalr	1928(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bc4:	08000613          	li	a2,128
    80005bc8:	f6040593          	addi	a1,s0,-160
    80005bcc:	4501                	li	a0,0
    80005bce:	ffffd097          	auipc	ra,0xffffd
    80005bd2:	25c080e7          	jalr	604(ra) # 80002e2a <argstr>
    80005bd6:	04054b63          	bltz	a0,80005c2c <sys_chdir+0x86>
    80005bda:	f6040513          	addi	a0,s0,-160
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	556080e7          	jalr	1366(ra) # 80004134 <namei>
    80005be6:	84aa                	mv	s1,a0
    80005be8:	c131                	beqz	a0,80005c2c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	d9a080e7          	jalr	-614(ra) # 80003984 <ilock>
  if(ip->type != T_DIR){
    80005bf2:	04449703          	lh	a4,68(s1)
    80005bf6:	4785                	li	a5,1
    80005bf8:	04f71063          	bne	a4,a5,80005c38 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	e48080e7          	jalr	-440(ra) # 80003a46 <iunlock>
  iput(p->cwd);
    80005c06:	15093503          	ld	a0,336(s2)
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	f34080e7          	jalr	-204(ra) # 80003b3e <iput>
  end_op();
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	7b2080e7          	jalr	1970(ra) # 800043c4 <end_op>
  p->cwd = ip;
    80005c1a:	14993823          	sd	s1,336(s2)
  return 0;
    80005c1e:	4501                	li	a0,0
}
    80005c20:	60ea                	ld	ra,152(sp)
    80005c22:	644a                	ld	s0,144(sp)
    80005c24:	64aa                	ld	s1,136(sp)
    80005c26:	690a                	ld	s2,128(sp)
    80005c28:	610d                	addi	sp,sp,160
    80005c2a:	8082                	ret
    end_op();
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	798080e7          	jalr	1944(ra) # 800043c4 <end_op>
    return -1;
    80005c34:	557d                	li	a0,-1
    80005c36:	b7ed                	j	80005c20 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c38:	8526                	mv	a0,s1
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	fac080e7          	jalr	-84(ra) # 80003be6 <iunlockput>
    end_op();
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	782080e7          	jalr	1922(ra) # 800043c4 <end_op>
    return -1;
    80005c4a:	557d                	li	a0,-1
    80005c4c:	bfd1                	j	80005c20 <sys_chdir+0x7a>

0000000080005c4e <sys_exec>:

uint64
sys_exec(void)
{
    80005c4e:	7145                	addi	sp,sp,-464
    80005c50:	e786                	sd	ra,456(sp)
    80005c52:	e3a2                	sd	s0,448(sp)
    80005c54:	ff26                	sd	s1,440(sp)
    80005c56:	fb4a                	sd	s2,432(sp)
    80005c58:	f74e                	sd	s3,424(sp)
    80005c5a:	f352                	sd	s4,416(sp)
    80005c5c:	ef56                	sd	s5,408(sp)
    80005c5e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c60:	08000613          	li	a2,128
    80005c64:	f4040593          	addi	a1,s0,-192
    80005c68:	4501                	li	a0,0
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	1c0080e7          	jalr	448(ra) # 80002e2a <argstr>
    return -1;
    80005c72:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c74:	0c054a63          	bltz	a0,80005d48 <sys_exec+0xfa>
    80005c78:	e3840593          	addi	a1,s0,-456
    80005c7c:	4505                	li	a0,1
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	18a080e7          	jalr	394(ra) # 80002e08 <argaddr>
    80005c86:	0c054163          	bltz	a0,80005d48 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c8a:	10000613          	li	a2,256
    80005c8e:	4581                	li	a1,0
    80005c90:	e4040513          	addi	a0,s0,-448
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	064080e7          	jalr	100(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c9c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ca0:	89a6                	mv	s3,s1
    80005ca2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ca4:	02000a13          	li	s4,32
    80005ca8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cac:	00391793          	slli	a5,s2,0x3
    80005cb0:	e3040593          	addi	a1,s0,-464
    80005cb4:	e3843503          	ld	a0,-456(s0)
    80005cb8:	953e                	add	a0,a0,a5
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	092080e7          	jalr	146(ra) # 80002d4c <fetchaddr>
    80005cc2:	02054a63          	bltz	a0,80005cf6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cc6:	e3043783          	ld	a5,-464(s0)
    80005cca:	c3b9                	beqz	a5,80005d10 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	e40080e7          	jalr	-448(ra) # 80000b0c <kalloc>
    80005cd4:	85aa                	mv	a1,a0
    80005cd6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cda:	cd11                	beqz	a0,80005cf6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cdc:	6605                	lui	a2,0x1
    80005cde:	e3043503          	ld	a0,-464(s0)
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	0bc080e7          	jalr	188(ra) # 80002d9e <fetchstr>
    80005cea:	00054663          	bltz	a0,80005cf6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cee:	0905                	addi	s2,s2,1
    80005cf0:	09a1                	addi	s3,s3,8
    80005cf2:	fb491be3          	bne	s2,s4,80005ca8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf6:	10048913          	addi	s2,s1,256
    80005cfa:	6088                	ld	a0,0(s1)
    80005cfc:	c529                	beqz	a0,80005d46 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cfe:	ffffb097          	auipc	ra,0xffffb
    80005d02:	d12080e7          	jalr	-750(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d06:	04a1                	addi	s1,s1,8
    80005d08:	ff2499e3          	bne	s1,s2,80005cfa <sys_exec+0xac>
  return -1;
    80005d0c:	597d                	li	s2,-1
    80005d0e:	a82d                	j	80005d48 <sys_exec+0xfa>
      argv[i] = 0;
    80005d10:	0a8e                	slli	s5,s5,0x3
    80005d12:	fc040793          	addi	a5,s0,-64
    80005d16:	9abe                	add	s5,s5,a5
    80005d18:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005d1c:	e4040593          	addi	a1,s0,-448
    80005d20:	f4040513          	addi	a0,s0,-192
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	178080e7          	jalr	376(ra) # 80004e9c <exec>
    80005d2c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d2e:	10048993          	addi	s3,s1,256
    80005d32:	6088                	ld	a0,0(s1)
    80005d34:	c911                	beqz	a0,80005d48 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d36:	ffffb097          	auipc	ra,0xffffb
    80005d3a:	cda080e7          	jalr	-806(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d3e:	04a1                	addi	s1,s1,8
    80005d40:	ff3499e3          	bne	s1,s3,80005d32 <sys_exec+0xe4>
    80005d44:	a011                	j	80005d48 <sys_exec+0xfa>
  return -1;
    80005d46:	597d                	li	s2,-1
}
    80005d48:	854a                	mv	a0,s2
    80005d4a:	60be                	ld	ra,456(sp)
    80005d4c:	641e                	ld	s0,448(sp)
    80005d4e:	74fa                	ld	s1,440(sp)
    80005d50:	795a                	ld	s2,432(sp)
    80005d52:	79ba                	ld	s3,424(sp)
    80005d54:	7a1a                	ld	s4,416(sp)
    80005d56:	6afa                	ld	s5,408(sp)
    80005d58:	6179                	addi	sp,sp,464
    80005d5a:	8082                	ret

0000000080005d5c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d5c:	7139                	addi	sp,sp,-64
    80005d5e:	fc06                	sd	ra,56(sp)
    80005d60:	f822                	sd	s0,48(sp)
    80005d62:	f426                	sd	s1,40(sp)
    80005d64:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d66:	ffffc097          	auipc	ra,0xffffc
    80005d6a:	dc6080e7          	jalr	-570(ra) # 80001b2c <myproc>
    80005d6e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d70:	fd840593          	addi	a1,s0,-40
    80005d74:	4501                	li	a0,0
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	092080e7          	jalr	146(ra) # 80002e08 <argaddr>
    return -1;
    80005d7e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d80:	0e054063          	bltz	a0,80005e60 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d84:	fc840593          	addi	a1,s0,-56
    80005d88:	fd040513          	addi	a0,s0,-48
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	de0080e7          	jalr	-544(ra) # 80004b6c <pipealloc>
    return -1;
    80005d94:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d96:	0c054563          	bltz	a0,80005e60 <sys_pipe+0x104>
  fd0 = -1;
    80005d9a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d9e:	fd043503          	ld	a0,-48(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	50a080e7          	jalr	1290(ra) # 800052ac <fdalloc>
    80005daa:	fca42223          	sw	a0,-60(s0)
    80005dae:	08054c63          	bltz	a0,80005e46 <sys_pipe+0xea>
    80005db2:	fc843503          	ld	a0,-56(s0)
    80005db6:	fffff097          	auipc	ra,0xfffff
    80005dba:	4f6080e7          	jalr	1270(ra) # 800052ac <fdalloc>
    80005dbe:	fca42023          	sw	a0,-64(s0)
    80005dc2:	06054863          	bltz	a0,80005e32 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dc6:	4691                	li	a3,4
    80005dc8:	fc440613          	addi	a2,s0,-60
    80005dcc:	fd843583          	ld	a1,-40(s0)
    80005dd0:	68a8                	ld	a0,80(s1)
    80005dd2:	ffffc097          	auipc	ra,0xffffc
    80005dd6:	8d8080e7          	jalr	-1832(ra) # 800016aa <copyout>
    80005dda:	02054063          	bltz	a0,80005dfa <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dde:	4691                	li	a3,4
    80005de0:	fc040613          	addi	a2,s0,-64
    80005de4:	fd843583          	ld	a1,-40(s0)
    80005de8:	0591                	addi	a1,a1,4
    80005dea:	68a8                	ld	a0,80(s1)
    80005dec:	ffffc097          	auipc	ra,0xffffc
    80005df0:	8be080e7          	jalr	-1858(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005df4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df6:	06055563          	bgez	a0,80005e60 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dfa:	fc442783          	lw	a5,-60(s0)
    80005dfe:	07e9                	addi	a5,a5,26
    80005e00:	078e                	slli	a5,a5,0x3
    80005e02:	97a6                	add	a5,a5,s1
    80005e04:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e08:	fc042503          	lw	a0,-64(s0)
    80005e0c:	0569                	addi	a0,a0,26
    80005e0e:	050e                	slli	a0,a0,0x3
    80005e10:	9526                	add	a0,a0,s1
    80005e12:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e16:	fd043503          	ld	a0,-48(s0)
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	9fc080e7          	jalr	-1540(ra) # 80004816 <fileclose>
    fileclose(wf);
    80005e22:	fc843503          	ld	a0,-56(s0)
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	9f0080e7          	jalr	-1552(ra) # 80004816 <fileclose>
    return -1;
    80005e2e:	57fd                	li	a5,-1
    80005e30:	a805                	j	80005e60 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e32:	fc442783          	lw	a5,-60(s0)
    80005e36:	0007c863          	bltz	a5,80005e46 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e3a:	01a78513          	addi	a0,a5,26
    80005e3e:	050e                	slli	a0,a0,0x3
    80005e40:	9526                	add	a0,a0,s1
    80005e42:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e46:	fd043503          	ld	a0,-48(s0)
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	9cc080e7          	jalr	-1588(ra) # 80004816 <fileclose>
    fileclose(wf);
    80005e52:	fc843503          	ld	a0,-56(s0)
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	9c0080e7          	jalr	-1600(ra) # 80004816 <fileclose>
    return -1;
    80005e5e:	57fd                	li	a5,-1
}
    80005e60:	853e                	mv	a0,a5
    80005e62:	70e2                	ld	ra,56(sp)
    80005e64:	7442                	ld	s0,48(sp)
    80005e66:	74a2                	ld	s1,40(sp)
    80005e68:	6121                	addi	sp,sp,64
    80005e6a:	8082                	ret
    80005e6c:	0000                	unimp
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	d51fc0ef          	jal	ra,80002c00 <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	710c                	ld	a1,32(a0)
    80005f0c:	7510                	ld	a2,40(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	bb8080e7          	jalr	-1096(ra) # 80001b00 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	b80080e7          	jalr	-1152(ra) # 80001b00 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	b58080e7          	jalr	-1192(ra) # 80001b00 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	04a7cc63          	blt	a5,a0,80006028 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fd4:	0001e797          	auipc	a5,0x1e
    80005fd8:	02c78793          	addi	a5,a5,44 # 80024000 <disk>
    80005fdc:	00a78733          	add	a4,a5,a0
    80005fe0:	6789                	lui	a5,0x2
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fe8:	eba1                	bnez	a5,80006038 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fea:	00451713          	slli	a4,a0,0x4
    80005fee:	00020797          	auipc	a5,0x20
    80005ff2:	0127b783          	ld	a5,18(a5) # 80026000 <disk+0x2000>
    80005ff6:	97ba                	add	a5,a5,a4
    80005ff8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ffc:	0001e797          	auipc	a5,0x1e
    80006000:	00478793          	addi	a5,a5,4 # 80024000 <disk>
    80006004:	97aa                	add	a5,a5,a0
    80006006:	6509                	lui	a0,0x2
    80006008:	953e                	add	a0,a0,a5
    8000600a:	4785                	li	a5,1
    8000600c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006010:	00020517          	auipc	a0,0x20
    80006014:	00850513          	addi	a0,a0,8 # 80026018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	672080e7          	jalr	1650(ra) # 8000268a <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("virtio_disk_intr 1");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	79050513          	addi	a0,a0,1936 # 800087b8 <syscalls+0x330>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	79850513          	addi	a0,a0,1944 # 800087d0 <syscalls+0x348>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	500080e7          	jalr	1280(ra) # 80000540 <panic>

0000000080006048 <virtio_disk_init>:
{
    80006048:	1101                	addi	sp,sp,-32
    8000604a:	ec06                	sd	ra,24(sp)
    8000604c:	e822                	sd	s0,16(sp)
    8000604e:	e426                	sd	s1,8(sp)
    80006050:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006052:	00002597          	auipc	a1,0x2
    80006056:	79658593          	addi	a1,a1,1942 # 800087e8 <syscalls+0x360>
    8000605a:	00020517          	auipc	a0,0x20
    8000605e:	04e50513          	addi	a0,a0,78 # 800260a8 <disk+0x20a8>
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	b0a080e7          	jalr	-1270(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	4398                	lw	a4,0(a5)
    80006070:	2701                	sext.w	a4,a4
    80006072:	747277b7          	lui	a5,0x74727
    80006076:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000607a:	0ef71163          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	43dc                	lw	a5,4(a5)
    80006084:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006086:	4705                	li	a4,1
    80006088:	0ce79a63          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	479c                	lw	a5,8(a5)
    80006092:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006094:	4709                	li	a4,2
    80006096:	0ce79363          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	47d8                	lw	a4,12(a5)
    800060a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a2:	554d47b7          	lui	a5,0x554d4
    800060a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060aa:	0af71963          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	4705                	li	a4,1
    800060b4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	470d                	li	a4,3
    800060b8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060bc:	c7ffe737          	lui	a4,0xc7ffe
    800060c0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800060c4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060c6:	2701                	sext.w	a4,a4
    800060c8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ca:	472d                	li	a4,11
    800060cc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	473d                	li	a4,15
    800060d0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060d2:	6705                	lui	a4,0x1
    800060d4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060d6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060da:	5bdc                	lw	a5,52(a5)
    800060dc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060de:	c7d9                	beqz	a5,8000616c <virtio_disk_init+0x124>
  if(max < NUM)
    800060e0:	471d                	li	a4,7
    800060e2:	08f77d63          	bgeu	a4,a5,8000617c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e6:	100014b7          	lui	s1,0x10001
    800060ea:	47a1                	li	a5,8
    800060ec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060ee:	6609                	lui	a2,0x2
    800060f0:	4581                	li	a1,0
    800060f2:	0001e517          	auipc	a0,0x1e
    800060f6:	f0e50513          	addi	a0,a0,-242 # 80024000 <disk>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	bfe080e7          	jalr	-1026(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006102:	0001e717          	auipc	a4,0x1e
    80006106:	efe70713          	addi	a4,a4,-258 # 80024000 <disk>
    8000610a:	00c75793          	srli	a5,a4,0xc
    8000610e:	2781                	sext.w	a5,a5
    80006110:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006112:	00020797          	auipc	a5,0x20
    80006116:	eee78793          	addi	a5,a5,-274 # 80026000 <disk+0x2000>
    8000611a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000611c:	0001e717          	auipc	a4,0x1e
    80006120:	f6470713          	addi	a4,a4,-156 # 80024080 <disk+0x80>
    80006124:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006126:	0001f717          	auipc	a4,0x1f
    8000612a:	eda70713          	addi	a4,a4,-294 # 80025000 <disk+0x1000>
    8000612e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006130:	4705                	li	a4,1
    80006132:	00e78c23          	sb	a4,24(a5)
    80006136:	00e78ca3          	sb	a4,25(a5)
    8000613a:	00e78d23          	sb	a4,26(a5)
    8000613e:	00e78da3          	sb	a4,27(a5)
    80006142:	00e78e23          	sb	a4,28(a5)
    80006146:	00e78ea3          	sb	a4,29(a5)
    8000614a:	00e78f23          	sb	a4,30(a5)
    8000614e:	00e78fa3          	sb	a4,31(a5)
}
    80006152:	60e2                	ld	ra,24(sp)
    80006154:	6442                	ld	s0,16(sp)
    80006156:	64a2                	ld	s1,8(sp)
    80006158:	6105                	addi	sp,sp,32
    8000615a:	8082                	ret
    panic("could not find virtio disk");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	69c50513          	addi	a0,a0,1692 # 800087f8 <syscalls+0x370>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	6ac50513          	addi	a0,a0,1708 # 80008818 <syscalls+0x390>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	6bc50513          	addi	a0,a0,1724 # 80008838 <syscalls+0x3b0>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3bc080e7          	jalr	956(ra) # 80000540 <panic>

000000008000618c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000618c:	7175                	addi	sp,sp,-144
    8000618e:	e506                	sd	ra,136(sp)
    80006190:	e122                	sd	s0,128(sp)
    80006192:	fca6                	sd	s1,120(sp)
    80006194:	f8ca                	sd	s2,112(sp)
    80006196:	f4ce                	sd	s3,104(sp)
    80006198:	f0d2                	sd	s4,96(sp)
    8000619a:	ecd6                	sd	s5,88(sp)
    8000619c:	e8da                	sd	s6,80(sp)
    8000619e:	e4de                	sd	s7,72(sp)
    800061a0:	e0e2                	sd	s8,64(sp)
    800061a2:	fc66                	sd	s9,56(sp)
    800061a4:	f86a                	sd	s10,48(sp)
    800061a6:	f46e                	sd	s11,40(sp)
    800061a8:	0900                	addi	s0,sp,144
    800061aa:	8aaa                	mv	s5,a0
    800061ac:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061ae:	00c52c83          	lw	s9,12(a0)
    800061b2:	001c9c9b          	slliw	s9,s9,0x1
    800061b6:	1c82                	slli	s9,s9,0x20
    800061b8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061bc:	00020517          	auipc	a0,0x20
    800061c0:	eec50513          	addi	a0,a0,-276 # 800260a8 <disk+0x20a8>
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	a38080e7          	jalr	-1480(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    800061cc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061ce:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d0:	0001ec17          	auipc	s8,0x1e
    800061d4:	e30c0c13          	addi	s8,s8,-464 # 80024000 <disk>
    800061d8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061da:	4b0d                	li	s6,3
    800061dc:	a0ad                	j	80006246 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061de:	00fc0733          	add	a4,s8,a5
    800061e2:	975e                	add	a4,a4,s7
    800061e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061ea:	0207c563          	bltz	a5,80006214 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061ee:	2905                	addiw	s2,s2,1
    800061f0:	0611                	addi	a2,a2,4
    800061f2:	19690d63          	beq	s2,s6,8000638c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061f8:	00020717          	auipc	a4,0x20
    800061fc:	e2070713          	addi	a4,a4,-480 # 80026018 <disk+0x2018>
    80006200:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006202:	00074683          	lbu	a3,0(a4)
    80006206:	fee1                	bnez	a3,800061de <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	0705                	addi	a4,a4,1
    8000620c:	fe979be3          	bne	a5,s1,80006202 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006210:	57fd                	li	a5,-1
    80006212:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006214:	01205d63          	blez	s2,8000622e <virtio_disk_rw+0xa2>
    80006218:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000621a:	000a2503          	lw	a0,0(s4)
    8000621e:	00000097          	auipc	ra,0x0
    80006222:	da8080e7          	jalr	-600(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006226:	2d85                	addiw	s11,s11,1
    80006228:	0a11                	addi	s4,s4,4
    8000622a:	ffb918e3          	bne	s2,s11,8000621a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622e:	00020597          	auipc	a1,0x20
    80006232:	e7a58593          	addi	a1,a1,-390 # 800260a8 <disk+0x20a8>
    80006236:	00020517          	auipc	a0,0x20
    8000623a:	de250513          	addi	a0,a0,-542 # 80026018 <disk+0x2018>
    8000623e:	ffffc097          	auipc	ra,0xffffc
    80006242:	2b2080e7          	jalr	690(ra) # 800024f0 <sleep>
  for(int i = 0; i < 3; i++){
    80006246:	f8040a13          	addi	s4,s0,-128
{
    8000624a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000624c:	894e                	mv	s2,s3
    8000624e:	b765                	j	800061f6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006250:	00020717          	auipc	a4,0x20
    80006254:	db073703          	ld	a4,-592(a4) # 80026000 <disk+0x2000>
    80006258:	973e                	add	a4,a4,a5
    8000625a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000625e:	0001e517          	auipc	a0,0x1e
    80006262:	da250513          	addi	a0,a0,-606 # 80024000 <disk>
    80006266:	00020717          	auipc	a4,0x20
    8000626a:	d9a70713          	addi	a4,a4,-614 # 80026000 <disk+0x2000>
    8000626e:	6314                	ld	a3,0(a4)
    80006270:	96be                	add	a3,a3,a5
    80006272:	00c6d603          	lhu	a2,12(a3)
    80006276:	00166613          	ori	a2,a2,1
    8000627a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000627e:	f8842683          	lw	a3,-120(s0)
    80006282:	6310                	ld	a2,0(a4)
    80006284:	97b2                	add	a5,a5,a2
    80006286:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000628a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000628e:	0612                	slli	a2,a2,0x4
    80006290:	962a                	add	a2,a2,a0
    80006292:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006296:	00469793          	slli	a5,a3,0x4
    8000629a:	630c                	ld	a1,0(a4)
    8000629c:	95be                	add	a1,a1,a5
    8000629e:	6689                	lui	a3,0x2
    800062a0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800062a4:	96ca                	add	a3,a3,s2
    800062a6:	96aa                	add	a3,a3,a0
    800062a8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800062aa:	6314                	ld	a3,0(a4)
    800062ac:	96be                	add	a3,a3,a5
    800062ae:	4585                	li	a1,1
    800062b0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b2:	6314                	ld	a3,0(a4)
    800062b4:	96be                	add	a3,a3,a5
    800062b6:	4509                	li	a0,2
    800062b8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062bc:	6314                	ld	a3,0(a4)
    800062be:	97b6                	add	a5,a5,a3
    800062c0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062c4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062c8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062cc:	6714                	ld	a3,8(a4)
    800062ce:	0026d783          	lhu	a5,2(a3)
    800062d2:	8b9d                	andi	a5,a5,7
    800062d4:	0789                	addi	a5,a5,2
    800062d6:	0786                	slli	a5,a5,0x1
    800062d8:	97b6                	add	a5,a5,a3
    800062da:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062de:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062e2:	6718                	ld	a4,8(a4)
    800062e4:	00275783          	lhu	a5,2(a4)
    800062e8:	2785                	addiw	a5,a5,1
    800062ea:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f6:	004aa783          	lw	a5,4(s5)
    800062fa:	02b79163          	bne	a5,a1,8000631c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062fe:	00020917          	auipc	s2,0x20
    80006302:	daa90913          	addi	s2,s2,-598 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006306:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006308:	85ca                	mv	a1,s2
    8000630a:	8556                	mv	a0,s5
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	1e4080e7          	jalr	484(ra) # 800024f0 <sleep>
  while(b->disk == 1) {
    80006314:	004aa783          	lw	a5,4(s5)
    80006318:	fe9788e3          	beq	a5,s1,80006308 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000631c:	f8042483          	lw	s1,-128(s0)
    80006320:	20048793          	addi	a5,s1,512
    80006324:	00479713          	slli	a4,a5,0x4
    80006328:	0001e797          	auipc	a5,0x1e
    8000632c:	cd878793          	addi	a5,a5,-808 # 80024000 <disk>
    80006330:	97ba                	add	a5,a5,a4
    80006332:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006336:	00020917          	auipc	s2,0x20
    8000633a:	cca90913          	addi	s2,s2,-822 # 80026000 <disk+0x2000>
    8000633e:	a019                	j	80006344 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006340:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006344:	8526                	mv	a0,s1
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	c80080e7          	jalr	-896(ra) # 80005fc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000634e:	0492                	slli	s1,s1,0x4
    80006350:	00093783          	ld	a5,0(s2)
    80006354:	94be                	add	s1,s1,a5
    80006356:	00c4d783          	lhu	a5,12(s1)
    8000635a:	8b85                	andi	a5,a5,1
    8000635c:	f3f5                	bnez	a5,80006340 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635e:	00020517          	auipc	a0,0x20
    80006362:	d4a50513          	addi	a0,a0,-694 # 800260a8 <disk+0x20a8>
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	94a080e7          	jalr	-1718(ra) # 80000cb0 <release>
}
    8000636e:	60aa                	ld	ra,136(sp)
    80006370:	640a                	ld	s0,128(sp)
    80006372:	74e6                	ld	s1,120(sp)
    80006374:	7946                	ld	s2,112(sp)
    80006376:	79a6                	ld	s3,104(sp)
    80006378:	7a06                	ld	s4,96(sp)
    8000637a:	6ae6                	ld	s5,88(sp)
    8000637c:	6b46                	ld	s6,80(sp)
    8000637e:	6ba6                	ld	s7,72(sp)
    80006380:	6c06                	ld	s8,64(sp)
    80006382:	7ce2                	ld	s9,56(sp)
    80006384:	7d42                	ld	s10,48(sp)
    80006386:	7da2                	ld	s11,40(sp)
    80006388:	6149                	addi	sp,sp,144
    8000638a:	8082                	ret
  if(write)
    8000638c:	01a037b3          	snez	a5,s10
    80006390:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006394:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006398:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000639c:	f8042483          	lw	s1,-128(s0)
    800063a0:	00449913          	slli	s2,s1,0x4
    800063a4:	00020997          	auipc	s3,0x20
    800063a8:	c5c98993          	addi	s3,s3,-932 # 80026000 <disk+0x2000>
    800063ac:	0009ba03          	ld	s4,0(s3)
    800063b0:	9a4a                	add	s4,s4,s2
    800063b2:	f7040513          	addi	a0,s0,-144
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	d02080e7          	jalr	-766(ra) # 800010b8 <kvmpa>
    800063be:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063c2:	0009b783          	ld	a5,0(s3)
    800063c6:	97ca                	add	a5,a5,s2
    800063c8:	4741                	li	a4,16
    800063ca:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063cc:	0009b783          	ld	a5,0(s3)
    800063d0:	97ca                	add	a5,a5,s2
    800063d2:	4705                	li	a4,1
    800063d4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f8442783          	lw	a5,-124(s0)
    800063dc:	0009b703          	ld	a4,0(s3)
    800063e0:	974a                	add	a4,a4,s2
    800063e2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e6:	0792                	slli	a5,a5,0x4
    800063e8:	0009b703          	ld	a4,0(s3)
    800063ec:	973e                	add	a4,a4,a5
    800063ee:	058a8693          	addi	a3,s5,88
    800063f2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063f4:	0009b703          	ld	a4,0(s3)
    800063f8:	973e                	add	a4,a4,a5
    800063fa:	40000693          	li	a3,1024
    800063fe:	c714                	sw	a3,8(a4)
  if(write)
    80006400:	e40d18e3          	bnez	s10,80006250 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006404:	00020717          	auipc	a4,0x20
    80006408:	bfc73703          	ld	a4,-1028(a4) # 80026000 <disk+0x2000>
    8000640c:	973e                	add	a4,a4,a5
    8000640e:	4689                	li	a3,2
    80006410:	00d71623          	sh	a3,12(a4)
    80006414:	b5a9                	j	8000625e <virtio_disk_rw+0xd2>

0000000080006416 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006416:	1101                	addi	sp,sp,-32
    80006418:	ec06                	sd	ra,24(sp)
    8000641a:	e822                	sd	s0,16(sp)
    8000641c:	e426                	sd	s1,8(sp)
    8000641e:	e04a                	sd	s2,0(sp)
    80006420:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006422:	00020517          	auipc	a0,0x20
    80006426:	c8650513          	addi	a0,a0,-890 # 800260a8 <disk+0x20a8>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	7d2080e7          	jalr	2002(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006432:	00020717          	auipc	a4,0x20
    80006436:	bce70713          	addi	a4,a4,-1074 # 80026000 <disk+0x2000>
    8000643a:	02075783          	lhu	a5,32(a4)
    8000643e:	6b18                	ld	a4,16(a4)
    80006440:	00275683          	lhu	a3,2(a4)
    80006444:	8ebd                	xor	a3,a3,a5
    80006446:	8a9d                	andi	a3,a3,7
    80006448:	cab9                	beqz	a3,8000649e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000644a:	0001e917          	auipc	s2,0x1e
    8000644e:	bb690913          	addi	s2,s2,-1098 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006452:	00020497          	auipc	s1,0x20
    80006456:	bae48493          	addi	s1,s1,-1106 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000645a:	078e                	slli	a5,a5,0x3
    8000645c:	97ba                	add	a5,a5,a4
    8000645e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006460:	20078713          	addi	a4,a5,512
    80006464:	0712                	slli	a4,a4,0x4
    80006466:	974a                	add	a4,a4,s2
    80006468:	03074703          	lbu	a4,48(a4)
    8000646c:	ef21                	bnez	a4,800064c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000646e:	20078793          	addi	a5,a5,512
    80006472:	0792                	slli	a5,a5,0x4
    80006474:	97ca                	add	a5,a5,s2
    80006476:	7798                	ld	a4,40(a5)
    80006478:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000647c:	7788                	ld	a0,40(a5)
    8000647e:	ffffc097          	auipc	ra,0xffffc
    80006482:	20c080e7          	jalr	524(ra) # 8000268a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006486:	0204d783          	lhu	a5,32(s1)
    8000648a:	2785                	addiw	a5,a5,1
    8000648c:	8b9d                	andi	a5,a5,7
    8000648e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006492:	6898                	ld	a4,16(s1)
    80006494:	00275683          	lhu	a3,2(a4)
    80006498:	8a9d                	andi	a3,a3,7
    8000649a:	fcf690e3          	bne	a3,a5,8000645a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000649e:	10001737          	lui	a4,0x10001
    800064a2:	533c                	lw	a5,96(a4)
    800064a4:	8b8d                	andi	a5,a5,3
    800064a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064a8:	00020517          	auipc	a0,0x20
    800064ac:	c0050513          	addi	a0,a0,-1024 # 800260a8 <disk+0x20a8>
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	800080e7          	jalr	-2048(ra) # 80000cb0 <release>
}
    800064b8:	60e2                	ld	ra,24(sp)
    800064ba:	6442                	ld	s0,16(sp)
    800064bc:	64a2                	ld	s1,8(sp)
    800064be:	6902                	ld	s2,0(sp)
    800064c0:	6105                	addi	sp,sp,32
    800064c2:	8082                	ret
      panic("virtio_disk_intr status");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	39450513          	addi	a0,a0,916 # 80008858 <syscalls+0x3d0>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	074080e7          	jalr	116(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

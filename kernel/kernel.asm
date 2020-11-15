
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
  int interval = 10000; // cycles; about 1/10th second in qemu.
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
    8000005e:	e2678793          	addi	a5,a5,-474 # 80005e80 <timervec>
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
    80000128:	654080e7          	jalr	1620(ra) # 80002778 <either_copyin>
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
    800001cc:	922080e7          	jalr	-1758(ra) # 80001aea <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	2d4080e7          	jalr	724(ra) # 800024ac <sleep>
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
    80000218:	50e080e7          	jalr	1294(ra) # 80002722 <either_copyout>
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
    800002f8:	4da080e7          	jalr	1242(ra) # 800027ce <procdump>
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
    8000044c:	1f0080e7          	jalr	496(ra) # 80002638 <wakeup>
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
    8000047e:	13678793          	addi	a5,a5,310 # 800225b0 <devsw>
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
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
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
    800008a4:	d98080e7          	jalr	-616(ra) # 80002638 <wakeup>
    
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
    8000093e:	b72080e7          	jalr	-1166(ra) # 800024ac <sleep>
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
    80000b9a:	f38080e7          	jalr	-200(ra) # 80001ace <mycpu>
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
    80000bcc:	f06080e7          	jalr	-250(ra) # 80001ace <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	efa080e7          	jalr	-262(ra) # 80001ace <mycpu>
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
    80000bf0:	ee2080e7          	jalr	-286(ra) # 80001ace <mycpu>
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
    80000c30:	ea2080e7          	jalr	-350(ra) # 80001ace <mycpu>
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
    80000c5c:	e76080e7          	jalr	-394(ra) # 80001ace <mycpu>
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
    80000eb2:	c10080e7          	jalr	-1008(ra) # 80001abe <cpuid>
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
    80000ece:	bf4080e7          	jalr	-1036(ra) # 80001abe <cpuid>
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
    80000ef0:	a24080e7          	jalr	-1500(ra) # 80002910 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	fcc080e7          	jalr	-52(ra) # 80005ec0 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	192080e7          	jalr	402(ra) # 8000208e <scheduler>
    consoleinit();
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	54e080e7          	jalr	1358(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	85e080e7          	jalr	-1954(ra) # 8000076a <printfinit>
    printf("\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	1d450513          	addi	a0,a0,468 # 800080e8 <digits+0xa8>
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
    80000f50:	aa2080e7          	jalr	-1374(ra) # 800019ee <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	994080e7          	jalr	-1644(ra) # 800028e8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	9b4080e7          	jalr	-1612(ra) # 80002910 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f46080e7          	jalr	-186(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	f54080e7          	jalr	-172(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	0fa080e7          	jalr	250(ra) # 8000306e <binit>
    iinit();         // inode cache
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	78c080e7          	jalr	1932(ra) # 80003708 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	72a080e7          	jalr	1834(ra) # 800046ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	03c080e7          	jalr	60(ra) # 80005fc8 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e5a080e7          	jalr	-422(ra) # 80001dee <userinit>
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

0000000080001878 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001878:	1101                	addi	sp,sp,-32
    8000187a:	ec06                	sd	ra,24(sp)
    8000187c:	e822                	sd	s0,16(sp)
    8000187e:	e426                	sd	s1,8(sp)
    80001880:	1000                	addi	s0,sp,32
    80001882:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	2fe080e7          	jalr	766(ra) # 80000b82 <holding>
    8000188c:	c909                	beqz	a0,8000189e <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    8000188e:	749c                	ld	a5,40(s1)
    80001890:	00978f63          	beq	a5,s1,800018ae <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    p->change = 3;
  }
}
    80001894:	60e2                	ld	ra,24(sp)
    80001896:	6442                	ld	s0,16(sp)
    80001898:	64a2                	ld	s1,8(sp)
    8000189a:	6105                	addi	sp,sp,32
    8000189c:	8082                	ret
    panic("wakeup1");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	94a50513          	addi	a0,a0,-1718 # 800081e8 <digits+0x1a8>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	c9a080e7          	jalr	-870(ra) # 80000540 <panic>
  if (p->chan == p && p->state == SLEEPING)
    800018ae:	4c98                	lw	a4,24(s1)
    800018b0:	4785                	li	a5,1
    800018b2:	fef711e3          	bne	a4,a5,80001894 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018b6:	4789                	li	a5,2
    800018b8:	cc9c                	sw	a5,24(s1)
    p->change = 3;
    800018ba:	478d                	li	a5,3
    800018bc:	16f4a423          	sw	a5,360(s1)
}
    800018c0:	bfd1                	j	80001894 <wakeup1+0x1c>

00000000800018c2 <getportion>:
{
    800018c2:	1141                	addi	sp,sp,-16
    800018c4:	e422                	sd	s0,8(sp)
    800018c6:	0800                	addi	s0,sp,16
  int total = p->Qtime[2] + p->Qtime[1] + p->Qtime[0];
    800018c8:	17452683          	lw	a3,372(a0)
    800018cc:	17052703          	lw	a4,368(a0)
    800018d0:	16c52583          	lw	a1,364(a0)
    800018d4:	00e6863b          	addw	a2,a3,a4
    800018d8:	9e2d                	addw	a2,a2,a1
  p->Qtime[2] = p->Qtime[2] * 100 / total;
    800018da:	06400793          	li	a5,100
    800018de:	02d786bb          	mulw	a3,a5,a3
    800018e2:	02c6c6bb          	divw	a3,a3,a2
    800018e6:	16d52a23          	sw	a3,372(a0)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    800018ea:	02e7873b          	mulw	a4,a5,a4
    800018ee:	02c7473b          	divw	a4,a4,a2
    800018f2:	16e52823          	sw	a4,368(a0)
  p->Qtime[0] = p->Qtime[0] * 100 / total;
    800018f6:	02b787bb          	mulw	a5,a5,a1
    800018fa:	02c7c7bb          	divw	a5,a5,a2
    800018fe:	16f52623          	sw	a5,364(a0)
}
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret

0000000080001908 <findproc>:
{
    80001908:	1141                	addi	sp,sp,-16
    8000190a:	e422                	sd	s0,8(sp)
    8000190c:	0800                	addi	s0,sp,16
    if (Q[priority][index] == obj)
    8000190e:	00959713          	slli	a4,a1,0x9
    80001912:	00010797          	auipc	a5,0x10
    80001916:	03e78793          	addi	a5,a5,62 # 80011950 <Q>
    8000191a:	97ba                	add	a5,a5,a4
    8000191c:	639c                	ld	a5,0(a5)
    8000191e:	02f50263          	beq	a0,a5,80001942 <findproc+0x3a>
    80001922:	86aa                	mv	a3,a0
    80001924:	00010797          	auipc	a5,0x10
    80001928:	03478793          	addi	a5,a5,52 # 80011958 <Q+0x8>
    8000192c:	97ba                	add	a5,a5,a4
  int index = 0;
    8000192e:	4501                	li	a0,0
    index++;
    80001930:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    80001932:	07a1                	addi	a5,a5,8
    80001934:	ff87b703          	ld	a4,-8(a5)
    80001938:	fed71ce3          	bne	a4,a3,80001930 <findproc+0x28>
}
    8000193c:	6422                	ld	s0,8(sp)
    8000193e:	0141                	addi	sp,sp,16
    80001940:	8082                	ret
  int index = 0;
    80001942:	4501                	li	a0,0
    80001944:	bfe5                	j	8000193c <findproc+0x34>

0000000080001946 <movequeue>:
{
    80001946:	7179                	addi	sp,sp,-48
    80001948:	f406                	sd	ra,40(sp)
    8000194a:	f022                	sd	s0,32(sp)
    8000194c:	ec26                	sd	s1,24(sp)
    8000194e:	e84a                	sd	s2,16(sp)
    80001950:	e44e                	sd	s3,8(sp)
    80001952:	1800                	addi	s0,sp,48
    80001954:	84aa                	mv	s1,a0
    80001956:	892e                	mv	s2,a1
  if (opt != INSERT)
    80001958:	4785                	li	a5,1
    8000195a:	06f60163          	beq	a2,a5,800019bc <movequeue+0x76>
    8000195e:	89b2                	mv	s3,a2
    int pos = findproc(obj, obj->priority);
    80001960:	17852583          	lw	a1,376(a0)
    80001964:	00000097          	auipc	ra,0x0
    80001968:	fa4080e7          	jalr	-92(ra) # 80001908 <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    8000196c:	03e00793          	li	a5,62
    80001970:	02a7c863          	blt	a5,a0,800019a0 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001974:	00010697          	auipc	a3,0x10
    80001978:	fdc68693          	addi	a3,a3,-36 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    8000197c:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001980:	1784a783          	lw	a5,376(s1)
    80001984:	862a                	mv	a2,a0
    80001986:	2505                	addiw	a0,a0,1
    80001988:	079a                	slli	a5,a5,0x6
    8000198a:	00a78733          	add	a4,a5,a0
    8000198e:	070e                	slli	a4,a4,0x3
    80001990:	9736                	add	a4,a4,a3
    80001992:	6318                	ld	a4,0(a4)
    80001994:	97b2                	add	a5,a5,a2
    80001996:	078e                	slli	a5,a5,0x3
    80001998:	97b6                	add	a5,a5,a3
    8000199a:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    8000199c:	feb512e3          	bne	a0,a1,80001980 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    800019a0:	1784a783          	lw	a5,376(s1)
    800019a4:	00979713          	slli	a4,a5,0x9
    800019a8:	00010797          	auipc	a5,0x10
    800019ac:	fa878793          	addi	a5,a5,-88 # 80011950 <Q>
    800019b0:	97ba                	add	a5,a5,a4
    800019b2:	1e07bc23          	sd	zero,504(a5)
  if (opt != DELETE)
    800019b6:	4789                	li	a5,2
    800019b8:	02f98463          	beq	s3,a5,800019e0 <movequeue+0x9a>
    int endstart = findproc(0, priority);
    800019bc:	85ca                	mv	a1,s2
    800019be:	4501                	li	a0,0
    800019c0:	00000097          	auipc	ra,0x0
    800019c4:	f48080e7          	jalr	-184(ra) # 80001908 <findproc>
    Q[priority][endstart] = obj;
    800019c8:	00691793          	slli	a5,s2,0x6
    800019cc:	97aa                	add	a5,a5,a0
    800019ce:	078e                	slli	a5,a5,0x3
    800019d0:	00010717          	auipc	a4,0x10
    800019d4:	f8070713          	addi	a4,a4,-128 # 80011950 <Q>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    800019dc:	1724ac23          	sw	s2,376(s1)
}
    800019e0:	70a2                	ld	ra,40(sp)
    800019e2:	7402                	ld	s0,32(sp)
    800019e4:	64e2                	ld	s1,24(sp)
    800019e6:	6942                	ld	s2,16(sp)
    800019e8:	69a2                	ld	s3,8(sp)
    800019ea:	6145                	addi	sp,sp,48
    800019ec:	8082                	ret

00000000800019ee <procinit>:
{
    800019ee:	715d                	addi	sp,sp,-80
    800019f0:	e486                	sd	ra,72(sp)
    800019f2:	e0a2                	sd	s0,64(sp)
    800019f4:	fc26                	sd	s1,56(sp)
    800019f6:	f84a                	sd	s2,48(sp)
    800019f8:	f44e                	sd	s3,40(sp)
    800019fa:	f052                	sd	s4,32(sp)
    800019fc:	ec56                	sd	s5,24(sp)
    800019fe:	e85a                	sd	s6,16(sp)
    80001a00:	e45e                	sd	s7,8(sp)
    80001a02:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a04:	00006597          	auipc	a1,0x6
    80001a08:	7ec58593          	addi	a1,a1,2028 # 800081f0 <digits+0x1b0>
    80001a0c:	00010517          	auipc	a0,0x10
    80001a10:	54450513          	addi	a0,a0,1348 # 80011f50 <pid_lock>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	158080e7          	jalr	344(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a1c:	00011917          	auipc	s2,0x11
    80001a20:	94c90913          	addi	s2,s2,-1716 # 80012368 <proc>
    initlock(&p->lock, "proc");
    80001a24:	00006b97          	auipc	s7,0x6
    80001a28:	7d4b8b93          	addi	s7,s7,2004 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a2c:	8b4a                	mv	s6,s2
    80001a2e:	00006a97          	auipc	s5,0x6
    80001a32:	5d2a8a93          	addi	s5,s5,1490 # 80008000 <etext>
    80001a36:	040009b7          	lui	s3,0x4000
    80001a3a:	19fd                	addi	s3,s3,-1
    80001a3c:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a3e:	00017a17          	auipc	s4,0x17
    80001a42:	92aa0a13          	addi	s4,s4,-1750 # 80018368 <tickslock>
    initlock(&p->lock, "proc");
    80001a46:	85de                	mv	a1,s7
    80001a48:	854a                	mv	a0,s2
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	122080e7          	jalr	290(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	0ba080e7          	jalr	186(ra) # 80000b0c <kalloc>
    80001a5a:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a5c:	c929                	beqz	a0,80001aae <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a5e:	416904b3          	sub	s1,s2,s6
    80001a62:	849d                	srai	s1,s1,0x7
    80001a64:	000ab783          	ld	a5,0(s5)
    80001a68:	02f484b3          	mul	s1,s1,a5
    80001a6c:	2485                	addiw	s1,s1,1
    80001a6e:	00d4949b          	slliw	s1,s1,0xd
    80001a72:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a76:	4699                	li	a3,6
    80001a78:	6605                	lui	a2,0x1
    80001a7a:	8526                	mv	a0,s1
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	728080e7          	jalr	1832(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001a84:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a88:	18090913          	addi	s2,s2,384
    80001a8c:	fb491de3          	bne	s2,s4,80001a46 <procinit+0x58>
  kvminithart();
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	51c080e7          	jalr	1308(ra) # 80000fac <kvminithart>
}
    80001a98:	60a6                	ld	ra,72(sp)
    80001a9a:	6406                	ld	s0,64(sp)
    80001a9c:	74e2                	ld	s1,56(sp)
    80001a9e:	7942                	ld	s2,48(sp)
    80001aa0:	79a2                	ld	s3,40(sp)
    80001aa2:	7a02                	ld	s4,32(sp)
    80001aa4:	6ae2                	ld	s5,24(sp)
    80001aa6:	6b42                	ld	s6,16(sp)
    80001aa8:	6ba2                	ld	s7,8(sp)
    80001aaa:	6161                	addi	sp,sp,80
    80001aac:	8082                	ret
      panic("kalloc");
    80001aae:	00006517          	auipc	a0,0x6
    80001ab2:	75250513          	addi	a0,a0,1874 # 80008200 <digits+0x1c0>
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	a8a080e7          	jalr	-1398(ra) # 80000540 <panic>

0000000080001abe <cpuid>:
{
    80001abe:	1141                	addi	sp,sp,-16
    80001ac0:	e422                	sd	s0,8(sp)
    80001ac2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ac4:	8512                	mv	a0,tp
}
    80001ac6:	2501                	sext.w	a0,a0
    80001ac8:	6422                	ld	s0,8(sp)
    80001aca:	0141                	addi	sp,sp,16
    80001acc:	8082                	ret

0000000080001ace <mycpu>:
{
    80001ace:	1141                	addi	sp,sp,-16
    80001ad0:	e422                	sd	s0,8(sp)
    80001ad2:	0800                	addi	s0,sp,16
    80001ad4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ad6:	2781                	sext.w	a5,a5
    80001ad8:	079e                	slli	a5,a5,0x7
}
    80001ada:	00010517          	auipc	a0,0x10
    80001ade:	48e50513          	addi	a0,a0,1166 # 80011f68 <cpus>
    80001ae2:	953e                	add	a0,a0,a5
    80001ae4:	6422                	ld	s0,8(sp)
    80001ae6:	0141                	addi	sp,sp,16
    80001ae8:	8082                	ret

0000000080001aea <myproc>:
{
    80001aea:	1101                	addi	sp,sp,-32
    80001aec:	ec06                	sd	ra,24(sp)
    80001aee:	e822                	sd	s0,16(sp)
    80001af0:	e426                	sd	s1,8(sp)
    80001af2:	1000                	addi	s0,sp,32
  push_off();
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	0bc080e7          	jalr	188(ra) # 80000bb0 <push_off>
    80001afc:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001afe:	2781                	sext.w	a5,a5
    80001b00:	079e                	slli	a5,a5,0x7
    80001b02:	00010717          	auipc	a4,0x10
    80001b06:	e4e70713          	addi	a4,a4,-434 # 80011950 <Q>
    80001b0a:	97ba                	add	a5,a5,a4
    80001b0c:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	140080e7          	jalr	320(ra) # 80000c50 <pop_off>
}
    80001b18:	8526                	mv	a0,s1
    80001b1a:	60e2                	ld	ra,24(sp)
    80001b1c:	6442                	ld	s0,16(sp)
    80001b1e:	64a2                	ld	s1,8(sp)
    80001b20:	6105                	addi	sp,sp,32
    80001b22:	8082                	ret

0000000080001b24 <forkret>:
{
    80001b24:	1141                	addi	sp,sp,-16
    80001b26:	e406                	sd	ra,8(sp)
    80001b28:	e022                	sd	s0,0(sp)
    80001b2a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b2c:	00000097          	auipc	ra,0x0
    80001b30:	fbe080e7          	jalr	-66(ra) # 80001aea <myproc>
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	17c080e7          	jalr	380(ra) # 80000cb0 <release>
  if (first)
    80001b3c:	00007797          	auipc	a5,0x7
    80001b40:	d447a783          	lw	a5,-700(a5) # 80008880 <first.1>
    80001b44:	eb89                	bnez	a5,80001b56 <forkret+0x32>
  usertrapret();
    80001b46:	00001097          	auipc	ra,0x1
    80001b4a:	de2080e7          	jalr	-542(ra) # 80002928 <usertrapret>
}
    80001b4e:	60a2                	ld	ra,8(sp)
    80001b50:	6402                	ld	s0,0(sp)
    80001b52:	0141                	addi	sp,sp,16
    80001b54:	8082                	ret
    first = 0;
    80001b56:	00007797          	auipc	a5,0x7
    80001b5a:	d207a523          	sw	zero,-726(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001b5e:	4505                	li	a0,1
    80001b60:	00002097          	auipc	ra,0x2
    80001b64:	b28080e7          	jalr	-1240(ra) # 80003688 <fsinit>
    80001b68:	bff9                	j	80001b46 <forkret+0x22>

0000000080001b6a <allocpid>:
{
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	e04a                	sd	s2,0(sp)
    80001b74:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b76:	00010917          	auipc	s2,0x10
    80001b7a:	3da90913          	addi	s2,s2,986 # 80011f50 <pid_lock>
    80001b7e:	854a                	mv	a0,s2
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	07c080e7          	jalr	124(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b88:	00007797          	auipc	a5,0x7
    80001b8c:	cfc78793          	addi	a5,a5,-772 # 80008884 <nextpid>
    80001b90:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b92:	0014871b          	addiw	a4,s1,1
    80001b96:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b98:	854a                	mv	a0,s2
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	116080e7          	jalr	278(ra) # 80000cb0 <release>
}
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	60e2                	ld	ra,24(sp)
    80001ba6:	6442                	ld	s0,16(sp)
    80001ba8:	64a2                	ld	s1,8(sp)
    80001baa:	6902                	ld	s2,0(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <proc_pagetable>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
    80001bbc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	7b4080e7          	jalr	1972(ra) # 80001372 <uvmcreate>
    80001bc6:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bc8:	c121                	beqz	a0,80001c08 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bca:	4729                	li	a4,10
    80001bcc:	00005697          	auipc	a3,0x5
    80001bd0:	43468693          	addi	a3,a3,1076 # 80007000 <_trampoline>
    80001bd4:	6605                	lui	a2,0x1
    80001bd6:	040005b7          	lui	a1,0x4000
    80001bda:	15fd                	addi	a1,a1,-1
    80001bdc:	05b2                	slli	a1,a1,0xc
    80001bde:	fffff097          	auipc	ra,0xfffff
    80001be2:	538080e7          	jalr	1336(ra) # 80001116 <mappages>
    80001be6:	02054863          	bltz	a0,80001c16 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bea:	4719                	li	a4,6
    80001bec:	05893683          	ld	a3,88(s2)
    80001bf0:	6605                	lui	a2,0x1
    80001bf2:	020005b7          	lui	a1,0x2000
    80001bf6:	15fd                	addi	a1,a1,-1
    80001bf8:	05b6                	slli	a1,a1,0xd
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	51a080e7          	jalr	1306(ra) # 80001116 <mappages>
    80001c04:	02054163          	bltz	a0,80001c26 <proc_pagetable+0x76>
}
    80001c08:	8526                	mv	a0,s1
    80001c0a:	60e2                	ld	ra,24(sp)
    80001c0c:	6442                	ld	s0,16(sp)
    80001c0e:	64a2                	ld	s1,8(sp)
    80001c10:	6902                	ld	s2,0(sp)
    80001c12:	6105                	addi	sp,sp,32
    80001c14:	8082                	ret
    uvmfree(pagetable, 0);
    80001c16:	4581                	li	a1,0
    80001c18:	8526                	mv	a0,s1
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	954080e7          	jalr	-1708(ra) # 8000156e <uvmfree>
    return 0;
    80001c22:	4481                	li	s1,0
    80001c24:	b7d5                	j	80001c08 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c26:	4681                	li	a3,0
    80001c28:	4605                	li	a2,1
    80001c2a:	040005b7          	lui	a1,0x4000
    80001c2e:	15fd                	addi	a1,a1,-1
    80001c30:	05b2                	slli	a1,a1,0xc
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	67a080e7          	jalr	1658(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c3c:	4581                	li	a1,0
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	92e080e7          	jalr	-1746(ra) # 8000156e <uvmfree>
    return 0;
    80001c48:	4481                	li	s1,0
    80001c4a:	bf7d                	j	80001c08 <proc_pagetable+0x58>

0000000080001c4c <proc_freepagetable>:
{
    80001c4c:	1101                	addi	sp,sp,-32
    80001c4e:	ec06                	sd	ra,24(sp)
    80001c50:	e822                	sd	s0,16(sp)
    80001c52:	e426                	sd	s1,8(sp)
    80001c54:	e04a                	sd	s2,0(sp)
    80001c56:	1000                	addi	s0,sp,32
    80001c58:	84aa                	mv	s1,a0
    80001c5a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c5c:	4681                	li	a3,0
    80001c5e:	4605                	li	a2,1
    80001c60:	040005b7          	lui	a1,0x4000
    80001c64:	15fd                	addi	a1,a1,-1
    80001c66:	05b2                	slli	a1,a1,0xc
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	646080e7          	jalr	1606(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c70:	4681                	li	a3,0
    80001c72:	4605                	li	a2,1
    80001c74:	020005b7          	lui	a1,0x2000
    80001c78:	15fd                	addi	a1,a1,-1
    80001c7a:	05b6                	slli	a1,a1,0xd
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	630080e7          	jalr	1584(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c86:	85ca                	mv	a1,s2
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	8e4080e7          	jalr	-1820(ra) # 8000156e <uvmfree>
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret

0000000080001c9e <freeproc>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
    80001ca8:	84aa                	mv	s1,a0
  getportion(p);
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	c18080e7          	jalr	-1000(ra) # 800018c2 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cb2:	16c4a783          	lw	a5,364(s1)
    80001cb6:	1704a703          	lw	a4,368(s1)
    80001cba:	1744a683          	lw	a3,372(s1)
    80001cbe:	5c90                	lw	a2,56(s1)
    80001cc0:	15848593          	addi	a1,s1,344
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	54450513          	addi	a0,a0,1348 # 80008208 <digits+0x1c8>
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	8be080e7          	jalr	-1858(ra) # 8000058a <printf>
  if (p->trapframe)
    80001cd4:	6ca8                	ld	a0,88(s1)
    80001cd6:	c509                	beqz	a0,80001ce0 <freeproc+0x42>
    kfree((void *)p->trapframe);
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	d38080e7          	jalr	-712(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001ce0:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ce4:	68a8                	ld	a0,80(s1)
    80001ce6:	c511                	beqz	a0,80001cf2 <freeproc+0x54>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce8:	64ac                	ld	a1,72(s1)
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	f62080e7          	jalr	-158(ra) # 80001c4c <proc_freepagetable>
  p->pagetable = 0;
    80001cf2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cfa:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cfe:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d02:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d06:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d0a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d0e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d12:	0004ac23          	sw	zero,24(s1)
  movequeue(p, 0, DELETE);
    80001d16:	4609                	li	a2,2
    80001d18:	4581                	li	a1,0
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	c2a080e7          	jalr	-982(ra) # 80001946 <movequeue>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <allocproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d3a:	00010497          	auipc	s1,0x10
    80001d3e:	62e48493          	addi	s1,s1,1582 # 80012368 <proc>
    80001d42:	00016917          	auipc	s2,0x16
    80001d46:	62690913          	addi	s2,s2,1574 # 80018368 <tickslock>
    acquire(&p->lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	eb0080e7          	jalr	-336(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001d54:	4c9c                	lw	a5,24(s1)
    80001d56:	cf81                	beqz	a5,80001d6e <allocproc+0x40>
      release(&p->lock);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	f56080e7          	jalr	-170(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d62:	18048493          	addi	s1,s1,384
    80001d66:	ff2492e3          	bne	s1,s2,80001d4a <allocproc+0x1c>
  return 0;
    80001d6a:	4481                	li	s1,0
    80001d6c:	a0b9                	j	80001dba <allocproc+0x8c>
  p->pid = allocpid();
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	dfc080e7          	jalr	-516(ra) # 80001b6a <allocpid>
    80001d76:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	d94080e7          	jalr	-620(ra) # 80000b0c <kalloc>
    80001d80:	892a                	mv	s2,a0
    80001d82:	eca8                	sd	a0,88(s1)
    80001d84:	c131                	beqz	a0,80001dc8 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d86:	8526                	mv	a0,s1
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	e28080e7          	jalr	-472(ra) # 80001bb0 <proc_pagetable>
    80001d90:	892a                	mv	s2,a0
    80001d92:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d94:	c129                	beqz	a0,80001dd6 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d96:	07000613          	li	a2,112
    80001d9a:	4581                	li	a1,0
    80001d9c:	06048513          	addi	a0,s1,96
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	f58080e7          	jalr	-168(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001da8:	00000797          	auipc	a5,0x0
    80001dac:	d7c78793          	addi	a5,a5,-644 # 80001b24 <forkret>
    80001db0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db2:	60bc                	ld	a5,64(s1)
    80001db4:	6705                	lui	a4,0x1
    80001db6:	97ba                	add	a5,a5,a4
    80001db8:	f4bc                	sd	a5,104(s1)
}
    80001dba:	8526                	mv	a0,s1
    80001dbc:	60e2                	ld	ra,24(sp)
    80001dbe:	6442                	ld	s0,16(sp)
    80001dc0:	64a2                	ld	s1,8(sp)
    80001dc2:	6902                	ld	s2,0(sp)
    80001dc4:	6105                	addi	sp,sp,32
    80001dc6:	8082                	ret
    release(&p->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	ee6080e7          	jalr	-282(ra) # 80000cb0 <release>
    return 0;
    80001dd2:	84ca                	mv	s1,s2
    80001dd4:	b7dd                	j	80001dba <allocproc+0x8c>
    freeproc(p);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	ec6080e7          	jalr	-314(ra) # 80001c9e <freeproc>
    release(&p->lock);
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	ece080e7          	jalr	-306(ra) # 80000cb0 <release>
    return 0;
    80001dea:	84ca                	mv	s1,s2
    80001dec:	b7f9                	j	80001dba <allocproc+0x8c>

0000000080001dee <userinit>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	f36080e7          	jalr	-202(ra) # 80001d2e <allocproc>
    80001e00:	84aa                	mv	s1,a0
  initproc = p;
    80001e02:	00007797          	auipc	a5,0x7
    80001e06:	20a7bb23          	sd	a0,534(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e0a:	03400613          	li	a2,52
    80001e0e:	00007597          	auipc	a1,0x7
    80001e12:	a8258593          	addi	a1,a1,-1406 # 80008890 <initcode>
    80001e16:	6928                	ld	a0,80(a0)
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	588080e7          	jalr	1416(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e20:	6785                	lui	a5,0x1
    80001e22:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e24:	6cb8                	ld	a4,88(s1)
    80001e26:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e2a:	6cb8                	ld	a4,88(s1)
    80001e2c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e2e:	4641                	li	a2,16
    80001e30:	00006597          	auipc	a1,0x6
    80001e34:	40858593          	addi	a1,a1,1032 # 80008238 <digits+0x1f8>
    80001e38:	15848513          	addi	a0,s1,344
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	00e080e7          	jalr	14(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001e44:	00006517          	auipc	a0,0x6
    80001e48:	40450513          	addi	a0,a0,1028 # 80008248 <digits+0x208>
    80001e4c:	00002097          	auipc	ra,0x2
    80001e50:	264080e7          	jalr	612(ra) # 800040b0 <namei>
    80001e54:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e58:	4789                	li	a5,2
    80001e5a:	cc9c                	sw	a5,24(s1)
  movequeue(p, 2, INSERT);
    80001e5c:	4605                	li	a2,1
    80001e5e:	4589                	li	a1,2
    80001e60:	8526                	mv	a0,s1
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	ae4080e7          	jalr	-1308(ra) # 80001946 <movequeue>
  p->Qtime[2] = 0;
    80001e6a:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001e6e:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001e72:	1604a623          	sw	zero,364(s1)
  release(&p->lock);
    80001e76:	8526                	mv	a0,s1
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	e38080e7          	jalr	-456(ra) # 80000cb0 <release>
}
    80001e80:	60e2                	ld	ra,24(sp)
    80001e82:	6442                	ld	s0,16(sp)
    80001e84:	64a2                	ld	s1,8(sp)
    80001e86:	6105                	addi	sp,sp,32
    80001e88:	8082                	ret

0000000080001e8a <growproc>:
{
    80001e8a:	1101                	addi	sp,sp,-32
    80001e8c:	ec06                	sd	ra,24(sp)
    80001e8e:	e822                	sd	s0,16(sp)
    80001e90:	e426                	sd	s1,8(sp)
    80001e92:	e04a                	sd	s2,0(sp)
    80001e94:	1000                	addi	s0,sp,32
    80001e96:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	c52080e7          	jalr	-942(ra) # 80001aea <myproc>
    80001ea0:	892a                	mv	s2,a0
  sz = p->sz;
    80001ea2:	652c                	ld	a1,72(a0)
    80001ea4:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001ea8:	00904f63          	bgtz	s1,80001ec6 <growproc+0x3c>
  else if (n < 0)
    80001eac:	0204cc63          	bltz	s1,80001ee4 <growproc+0x5a>
  p->sz = sz;
    80001eb0:	1602                	slli	a2,a2,0x20
    80001eb2:	9201                	srli	a2,a2,0x20
    80001eb4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001eb8:	4501                	li	a0,0
}
    80001eba:	60e2                	ld	ra,24(sp)
    80001ebc:	6442                	ld	s0,16(sp)
    80001ebe:	64a2                	ld	s1,8(sp)
    80001ec0:	6902                	ld	s2,0(sp)
    80001ec2:	6105                	addi	sp,sp,32
    80001ec4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ec6:	9e25                	addw	a2,a2,s1
    80001ec8:	1602                	slli	a2,a2,0x20
    80001eca:	9201                	srli	a2,a2,0x20
    80001ecc:	1582                	slli	a1,a1,0x20
    80001ece:	9181                	srli	a1,a1,0x20
    80001ed0:	6928                	ld	a0,80(a0)
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	588080e7          	jalr	1416(ra) # 8000145a <uvmalloc>
    80001eda:	0005061b          	sext.w	a2,a0
    80001ede:	fa69                	bnez	a2,80001eb0 <growproc+0x26>
      return -1;
    80001ee0:	557d                	li	a0,-1
    80001ee2:	bfe1                	j	80001eba <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ee4:	9e25                	addw	a2,a2,s1
    80001ee6:	1602                	slli	a2,a2,0x20
    80001ee8:	9201                	srli	a2,a2,0x20
    80001eea:	1582                	slli	a1,a1,0x20
    80001eec:	9181                	srli	a1,a1,0x20
    80001eee:	6928                	ld	a0,80(a0)
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	522080e7          	jalr	1314(ra) # 80001412 <uvmdealloc>
    80001ef8:	0005061b          	sext.w	a2,a0
    80001efc:	bf55                	j	80001eb0 <growproc+0x26>

0000000080001efe <fork>:
{
    80001efe:	7139                	addi	sp,sp,-64
    80001f00:	fc06                	sd	ra,56(sp)
    80001f02:	f822                	sd	s0,48(sp)
    80001f04:	f426                	sd	s1,40(sp)
    80001f06:	f04a                	sd	s2,32(sp)
    80001f08:	ec4e                	sd	s3,24(sp)
    80001f0a:	e852                	sd	s4,16(sp)
    80001f0c:	e456                	sd	s5,8(sp)
    80001f0e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f10:	00000097          	auipc	ra,0x0
    80001f14:	bda080e7          	jalr	-1062(ra) # 80001aea <myproc>
    80001f18:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	e14080e7          	jalr	-492(ra) # 80001d2e <allocproc>
    80001f22:	10050163          	beqz	a0,80002024 <fork+0x126>
    80001f26:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f28:	048ab603          	ld	a2,72(s5)
    80001f2c:	692c                	ld	a1,80(a0)
    80001f2e:	050ab503          	ld	a0,80(s5)
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	674080e7          	jalr	1652(ra) # 800015a6 <uvmcopy>
    80001f3a:	04054a63          	bltz	a0,80001f8e <fork+0x90>
  np->sz = p->sz;
    80001f3e:	048ab783          	ld	a5,72(s5)
    80001f42:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f46:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f4a:	058ab683          	ld	a3,88(s5)
    80001f4e:	87b6                	mv	a5,a3
    80001f50:	0589b703          	ld	a4,88(s3)
    80001f54:	12068693          	addi	a3,a3,288
    80001f58:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f5c:	6788                	ld	a0,8(a5)
    80001f5e:	6b8c                	ld	a1,16(a5)
    80001f60:	6f90                	ld	a2,24(a5)
    80001f62:	01073023          	sd	a6,0(a4)
    80001f66:	e708                	sd	a0,8(a4)
    80001f68:	eb0c                	sd	a1,16(a4)
    80001f6a:	ef10                	sd	a2,24(a4)
    80001f6c:	02078793          	addi	a5,a5,32
    80001f70:	02070713          	addi	a4,a4,32
    80001f74:	fed792e3          	bne	a5,a3,80001f58 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001f78:	0589b783          	ld	a5,88(s3)
    80001f7c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f80:	0d0a8493          	addi	s1,s5,208
    80001f84:	0d098913          	addi	s2,s3,208
    80001f88:	150a8a13          	addi	s4,s5,336
    80001f8c:	a00d                	j	80001fae <fork+0xb0>
    freeproc(np);
    80001f8e:	854e                	mv	a0,s3
    80001f90:	00000097          	auipc	ra,0x0
    80001f94:	d0e080e7          	jalr	-754(ra) # 80001c9e <freeproc>
    release(&np->lock);
    80001f98:	854e                	mv	a0,s3
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	d16080e7          	jalr	-746(ra) # 80000cb0 <release>
    return -1;
    80001fa2:	54fd                	li	s1,-1
    80001fa4:	a0b5                	j	80002010 <fork+0x112>
  for (i = 0; i < NOFILE; i++)
    80001fa6:	04a1                	addi	s1,s1,8
    80001fa8:	0921                	addi	s2,s2,8
    80001faa:	01448b63          	beq	s1,s4,80001fc0 <fork+0xc2>
    if (p->ofile[i])
    80001fae:	6088                	ld	a0,0(s1)
    80001fb0:	d97d                	beqz	a0,80001fa6 <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fb2:	00002097          	auipc	ra,0x2
    80001fb6:	78e080e7          	jalr	1934(ra) # 80004740 <filedup>
    80001fba:	00a93023          	sd	a0,0(s2)
    80001fbe:	b7e5                	j	80001fa6 <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001fc0:	150ab503          	ld	a0,336(s5)
    80001fc4:	00002097          	auipc	ra,0x2
    80001fc8:	8fe080e7          	jalr	-1794(ra) # 800038c2 <idup>
    80001fcc:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fd0:	4641                	li	a2,16
    80001fd2:	158a8593          	addi	a1,s5,344
    80001fd6:	15898513          	addi	a0,s3,344
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	e70080e7          	jalr	-400(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80001fe2:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001fe6:	4789                	li	a5,2
    80001fe8:	00f9ac23          	sw	a5,24(s3)
  movequeue(np, 2, INSERT);
    80001fec:	4605                	li	a2,1
    80001fee:	4589                	li	a1,2
    80001ff0:	854e                	mv	a0,s3
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	954080e7          	jalr	-1708(ra) # 80001946 <movequeue>
  np->Qtime[2] = 0;
    80001ffa:	1609aa23          	sw	zero,372(s3)
  np->Qtime[1] = 0;
    80001ffe:	1609a823          	sw	zero,368(s3)
  np->Qtime[0] = 0;
    80002002:	1609a623          	sw	zero,364(s3)
  release(&np->lock);
    80002006:	854e                	mv	a0,s3
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	ca8080e7          	jalr	-856(ra) # 80000cb0 <release>
}
    80002010:	8526                	mv	a0,s1
    80002012:	70e2                	ld	ra,56(sp)
    80002014:	7442                	ld	s0,48(sp)
    80002016:	74a2                	ld	s1,40(sp)
    80002018:	7902                	ld	s2,32(sp)
    8000201a:	69e2                	ld	s3,24(sp)
    8000201c:	6a42                	ld	s4,16(sp)
    8000201e:	6aa2                	ld	s5,8(sp)
    80002020:	6121                	addi	sp,sp,64
    80002022:	8082                	ret
    return -1;
    80002024:	54fd                	li	s1,-1
    80002026:	b7ed                	j	80002010 <fork+0x112>

0000000080002028 <reparent>:
{
    80002028:	7179                	addi	sp,sp,-48
    8000202a:	f406                	sd	ra,40(sp)
    8000202c:	f022                	sd	s0,32(sp)
    8000202e:	ec26                	sd	s1,24(sp)
    80002030:	e84a                	sd	s2,16(sp)
    80002032:	e44e                	sd	s3,8(sp)
    80002034:	e052                	sd	s4,0(sp)
    80002036:	1800                	addi	s0,sp,48
    80002038:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000203a:	00010497          	auipc	s1,0x10
    8000203e:	32e48493          	addi	s1,s1,814 # 80012368 <proc>
      pp->parent = initproc;
    80002042:	00007a17          	auipc	s4,0x7
    80002046:	fd6a0a13          	addi	s4,s4,-42 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000204a:	00016997          	auipc	s3,0x16
    8000204e:	31e98993          	addi	s3,s3,798 # 80018368 <tickslock>
    80002052:	a029                	j	8000205c <reparent+0x34>
    80002054:	18048493          	addi	s1,s1,384
    80002058:	03348363          	beq	s1,s3,8000207e <reparent+0x56>
    if (pp->parent == p)
    8000205c:	709c                	ld	a5,32(s1)
    8000205e:	ff279be3          	bne	a5,s2,80002054 <reparent+0x2c>
      acquire(&pp->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	b98080e7          	jalr	-1128(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    8000206c:	000a3783          	ld	a5,0(s4)
    80002070:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c3c080e7          	jalr	-964(ra) # 80000cb0 <release>
    8000207c:	bfe1                	j	80002054 <reparent+0x2c>
}
    8000207e:	70a2                	ld	ra,40(sp)
    80002080:	7402                	ld	s0,32(sp)
    80002082:	64e2                	ld	s1,24(sp)
    80002084:	6942                	ld	s2,16(sp)
    80002086:	69a2                	ld	s3,8(sp)
    80002088:	6a02                	ld	s4,0(sp)
    8000208a:	6145                	addi	sp,sp,48
    8000208c:	8082                	ret

000000008000208e <scheduler>:
{
    8000208e:	7159                	addi	sp,sp,-112
    80002090:	f486                	sd	ra,104(sp)
    80002092:	f0a2                	sd	s0,96(sp)
    80002094:	eca6                	sd	s1,88(sp)
    80002096:	e8ca                	sd	s2,80(sp)
    80002098:	e4ce                	sd	s3,72(sp)
    8000209a:	e0d2                	sd	s4,64(sp)
    8000209c:	fc56                	sd	s5,56(sp)
    8000209e:	f85a                	sd	s6,48(sp)
    800020a0:	f45e                	sd	s7,40(sp)
    800020a2:	f062                	sd	s8,32(sp)
    800020a4:	ec66                	sd	s9,24(sp)
    800020a6:	e86a                	sd	s10,16(sp)
    800020a8:	e46e                	sd	s11,8(sp)
    800020aa:	1880                	addi	s0,sp,112
    800020ac:	8492                	mv	s1,tp
  int id = r_tp();
    800020ae:	2481                	sext.w	s1,s1
  printf("Entered Scheduler\n");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	1a050513          	addi	a0,a0,416 # 80008250 <digits+0x210>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	4d2080e7          	jalr	1234(ra) # 8000058a <printf>
  c->proc = 0;
    800020c0:	00749b93          	slli	s7,s1,0x7
    800020c4:	00010797          	auipc	a5,0x10
    800020c8:	88c78793          	addi	a5,a5,-1908 # 80011950 <Q>
    800020cc:	97de                	add	a5,a5,s7
    800020ce:	6007bc23          	sd	zero,1560(a5)
        swtch(&c->context, &p->context);
    800020d2:	00010797          	auipc	a5,0x10
    800020d6:	e9e78793          	addi	a5,a5,-354 # 80011f70 <cpus+0x8>
    800020da:	9bbe                	add	s7,s7,a5
  int exec = 0;
    800020dc:	4c01                	li	s8,0
      else if (p->change == 2)
    800020de:	4989                	li	s3,2
    for (p = proc; p < &proc[NPROC]; p++)
    800020e0:	00016a17          	auipc	s4,0x16
    800020e4:	288a0a13          	addi	s4,s4,648 # 80018368 <tickslock>
        c->proc = p;
    800020e8:	00010c97          	auipc	s9,0x10
    800020ec:	868c8c93          	addi	s9,s9,-1944 # 80011950 <Q>
    800020f0:	049e                	slli	s1,s1,0x7
    800020f2:	009c8b33          	add	s6,s9,s1
    800020f6:	a011                	j	800020fa <scheduler+0x6c>
      exec = 0;
    800020f8:	4c01                	li	s8,0
      if (p->change == 1)
    800020fa:	4905                	li	s2,1
    800020fc:	a8c5                	j	800021ec <scheduler+0x15e>
        movequeue(p, 1, MOVE);
    800020fe:	4601                	li	a2,0
    80002100:	85ca                	mv	a1,s2
    80002102:	8526                	mv	a0,s1
    80002104:	00000097          	auipc	ra,0x0
    80002108:	842080e7          	jalr	-1982(ra) # 80001946 <movequeue>
        p->change = 0;
    8000210c:	1604a423          	sw	zero,360(s1)
      release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b9e080e7          	jalr	-1122(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000211a:	18048493          	addi	s1,s1,384
    8000211e:	05448363          	beq	s1,s4,80002164 <scheduler+0xd6>
      acquire(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ad8080e7          	jalr	-1320(ra) # 80000bfc <acquire>
      if (p->change == 1)
    8000212c:	1684a783          	lw	a5,360(s1)
    80002130:	fd2787e3          	beq	a5,s2,800020fe <scheduler+0x70>
      else if (p->change == 2)
    80002134:	01378e63          	beq	a5,s3,80002150 <scheduler+0xc2>
      else if (p->change == 3)
    80002138:	fd579ce3          	bne	a5,s5,80002110 <scheduler+0x82>
        movequeue(p, 2, MOVE);
    8000213c:	4601                	li	a2,0
    8000213e:	85ce                	mv	a1,s3
    80002140:	8526                	mv	a0,s1
    80002142:	00000097          	auipc	ra,0x0
    80002146:	804080e7          	jalr	-2044(ra) # 80001946 <movequeue>
        p->change = 0;
    8000214a:	1604a423          	sw	zero,360(s1)
    8000214e:	b7c9                	j	80002110 <scheduler+0x82>
        movequeue(p, 0, MOVE);
    80002150:	4601                	li	a2,0
    80002152:	4581                	li	a1,0
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	7f0080e7          	jalr	2032(ra) # 80001946 <movequeue>
        p->change = 0;
    8000215e:	1604a423          	sw	zero,360(s1)
    80002162:	b77d                	j	80002110 <scheduler+0x82>
    int tail2 = findproc(0, 2) - 1;
    80002164:	85ce                	mv	a1,s3
    80002166:	4501                	li	a0,0
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	7a0080e7          	jalr	1952(ra) # 80001908 <findproc>
    for (int i = 0; i <= tail2; i++)
    80002170:	06a05363          	blez	a0,800021d6 <scheduler+0x148>
    80002174:	00010a97          	auipc	s5,0x10
    80002178:	bdca8a93          	addi	s5,s5,-1060 # 80011d50 <Q+0x400>
    8000217c:	fff50d1b          	addiw	s10,a0,-1
    80002180:	020d1793          	slli	a5,s10,0x20
    80002184:	01d7dd13          	srli	s10,a5,0x1d
    80002188:	00010797          	auipc	a5,0x10
    8000218c:	bd078793          	addi	a5,a5,-1072 # 80011d58 <Q+0x408>
    80002190:	9d3e                	add	s10,s10,a5
        p->state = RUNNING;
    80002192:	4d8d                	li	s11,3
    80002194:	a809                	j	800021a6 <scheduler+0x118>
      release(&p->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b18080e7          	jalr	-1256(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    800021a0:	0aa1                	addi	s5,s5,8
    800021a2:	03aa8a63          	beq	s5,s10,800021d6 <scheduler+0x148>
      p = Q[2][i];
    800021a6:	000ab483          	ld	s1,0(s5)
      acquire(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	a50080e7          	jalr	-1456(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    800021b4:	4c9c                	lw	a5,24(s1)
    800021b6:	ff3790e3          	bne	a5,s3,80002196 <scheduler+0x108>
        p->state = RUNNING;
    800021ba:	01b4ac23          	sw	s11,24(s1)
        c->proc = p;
    800021be:	609b3c23          	sd	s1,1560(s6) # 1618 <_entry-0x7fffe9e8>
        swtch(&c->context, &p->context);
    800021c2:	06048593          	addi	a1,s1,96
    800021c6:	855e                	mv	a0,s7
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	6b6080e7          	jalr	1718(ra) # 8000287e <swtch>
        c->proc = 0;
    800021d0:	600b3c23          	sd	zero,1560(s6)
    800021d4:	b7c9                	j	80002196 <scheduler+0x108>
    int tail1 = findproc(0, 1) - 1;
    800021d6:	85ca                	mv	a1,s2
    800021d8:	4501                	li	a0,0
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	72e080e7          	jalr	1838(ra) # 80001908 <findproc>
    800021e2:	fff5049b          	addiw	s1,a0,-1
    if (tail1 == -1)
    800021e6:	57fd                	li	a5,-1
    800021e8:	00f49e63          	bne	s1,a5,80002204 <scheduler+0x176>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021f0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021f4:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021f8:	00010497          	auipc	s1,0x10
    800021fc:	17048493          	addi	s1,s1,368 # 80012368 <proc>
      else if (p->change == 3)
    80002200:	4a8d                	li	s5,3
    80002202:	b705                	j	80002122 <scheduler+0x94>
    p = Q[1][exec];
    80002204:	040c0793          	addi	a5,s8,64
    80002208:	078e                	slli	a5,a5,0x3
    8000220a:	97e6                	add	a5,a5,s9
    8000220c:	0007b903          	ld	s2,0(a5)
    acquire(&p->lock);
    80002210:	854a                	mv	a0,s2
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9ea080e7          	jalr	-1558(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000221a:	01892783          	lw	a5,24(s2)
    8000221e:	01378b63          	beq	a5,s3,80002234 <scheduler+0x1a6>
    release(&p->lock);
    80002222:	854a                	mv	a0,s2
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a8c080e7          	jalr	-1396(ra) # 80000cb0 <release>
    if (exec < tail1)
    8000222c:	ec9c56e3          	bge	s8,s1,800020f8 <scheduler+0x6a>
      exec++;
    80002230:	2c05                	addiw	s8,s8,1
    80002232:	b5e1                	j	800020fa <scheduler+0x6c>
      p->state = RUNNING;
    80002234:	478d                	li	a5,3
    80002236:	00f92c23          	sw	a5,24(s2)
      c->proc = p;
    8000223a:	612b3c23          	sd	s2,1560(s6)
      swtch(&c->context, &p->context);
    8000223e:	06090593          	addi	a1,s2,96
    80002242:	855e                	mv	a0,s7
    80002244:	00000097          	auipc	ra,0x0
    80002248:	63a080e7          	jalr	1594(ra) # 8000287e <swtch>
      c->proc = 0;
    8000224c:	600b3c23          	sd	zero,1560(s6)
    80002250:	bfc9                	j	80002222 <scheduler+0x194>

0000000080002252 <sched>:
{
    80002252:	7179                	addi	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	88a080e7          	jalr	-1910(ra) # 80001aea <myproc>
    80002268:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	918080e7          	jalr	-1768(ra) # 80000b82 <holding>
    80002272:	c93d                	beqz	a0,800022e8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002274:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002276:	2781                	sext.w	a5,a5
    80002278:	079e                	slli	a5,a5,0x7
    8000227a:	0000f717          	auipc	a4,0xf
    8000227e:	6d670713          	addi	a4,a4,1750 # 80011950 <Q>
    80002282:	97ba                	add	a5,a5,a4
    80002284:	6907a703          	lw	a4,1680(a5)
    80002288:	4785                	li	a5,1
    8000228a:	06f71763          	bne	a4,a5,800022f8 <sched+0xa6>
  if (p->state == RUNNING)
    8000228e:	4c98                	lw	a4,24(s1)
    80002290:	478d                	li	a5,3
    80002292:	06f70b63          	beq	a4,a5,80002308 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002296:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000229a:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000229c:	efb5                	bnez	a5,80002318 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022a0:	0000f917          	auipc	s2,0xf
    800022a4:	6b090913          	addi	s2,s2,1712 # 80011950 <Q>
    800022a8:	2781                	sext.w	a5,a5
    800022aa:	079e                	slli	a5,a5,0x7
    800022ac:	97ca                	add	a5,a5,s2
    800022ae:	6947a983          	lw	s3,1684(a5)
    800022b2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022b4:	2781                	sext.w	a5,a5
    800022b6:	079e                	slli	a5,a5,0x7
    800022b8:	00010597          	auipc	a1,0x10
    800022bc:	cb858593          	addi	a1,a1,-840 # 80011f70 <cpus+0x8>
    800022c0:	95be                	add	a1,a1,a5
    800022c2:	06048513          	addi	a0,s1,96
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	5b8080e7          	jalr	1464(ra) # 8000287e <swtch>
    800022ce:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022d0:	2781                	sext.w	a5,a5
    800022d2:	079e                	slli	a5,a5,0x7
    800022d4:	97ca                	add	a5,a5,s2
    800022d6:	6937aa23          	sw	s3,1684(a5)
}
    800022da:	70a2                	ld	ra,40(sp)
    800022dc:	7402                	ld	s0,32(sp)
    800022de:	64e2                	ld	s1,24(sp)
    800022e0:	6942                	ld	s2,16(sp)
    800022e2:	69a2                	ld	s3,8(sp)
    800022e4:	6145                	addi	sp,sp,48
    800022e6:	8082                	ret
    panic("sched p->lock");
    800022e8:	00006517          	auipc	a0,0x6
    800022ec:	f8050513          	addi	a0,a0,-128 # 80008268 <digits+0x228>
    800022f0:	ffffe097          	auipc	ra,0xffffe
    800022f4:	250080e7          	jalr	592(ra) # 80000540 <panic>
    panic("sched locks");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f8050513          	addi	a0,a0,-128 # 80008278 <digits+0x238>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	240080e7          	jalr	576(ra) # 80000540 <panic>
    panic("sched running");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f8050513          	addi	a0,a0,-128 # 80008288 <digits+0x248>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	230080e7          	jalr	560(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002318:	00006517          	auipc	a0,0x6
    8000231c:	f8050513          	addi	a0,a0,-128 # 80008298 <digits+0x258>
    80002320:	ffffe097          	auipc	ra,0xffffe
    80002324:	220080e7          	jalr	544(ra) # 80000540 <panic>

0000000080002328 <exit>:
{
    80002328:	7179                	addi	sp,sp,-48
    8000232a:	f406                	sd	ra,40(sp)
    8000232c:	f022                	sd	s0,32(sp)
    8000232e:	ec26                	sd	s1,24(sp)
    80002330:	e84a                	sd	s2,16(sp)
    80002332:	e44e                	sd	s3,8(sp)
    80002334:	e052                	sd	s4,0(sp)
    80002336:	1800                	addi	s0,sp,48
    80002338:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	7b0080e7          	jalr	1968(ra) # 80001aea <myproc>
    80002342:	89aa                	mv	s3,a0
  if (p == initproc)
    80002344:	00007797          	auipc	a5,0x7
    80002348:	cd47b783          	ld	a5,-812(a5) # 80009018 <initproc>
    8000234c:	0d050493          	addi	s1,a0,208
    80002350:	15050913          	addi	s2,a0,336
    80002354:	02a79363          	bne	a5,a0,8000237a <exit+0x52>
    panic("init exiting");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f5850513          	addi	a0,a0,-168 # 800082b0 <digits+0x270>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1e0080e7          	jalr	480(ra) # 80000540 <panic>
      fileclose(f);
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	42a080e7          	jalr	1066(ra) # 80004792 <fileclose>
      p->ofile[fd] = 0;
    80002370:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002374:	04a1                	addi	s1,s1,8
    80002376:	01248563          	beq	s1,s2,80002380 <exit+0x58>
    if (p->ofile[fd])
    8000237a:	6088                	ld	a0,0(s1)
    8000237c:	f575                	bnez	a0,80002368 <exit+0x40>
    8000237e:	bfdd                	j	80002374 <exit+0x4c>
  begin_op();
    80002380:	00002097          	auipc	ra,0x2
    80002384:	f40080e7          	jalr	-192(ra) # 800042c0 <begin_op>
  iput(p->cwd);
    80002388:	1509b503          	ld	a0,336(s3)
    8000238c:	00001097          	auipc	ra,0x1
    80002390:	72e080e7          	jalr	1838(ra) # 80003aba <iput>
  end_op();
    80002394:	00002097          	auipc	ra,0x2
    80002398:	fac080e7          	jalr	-84(ra) # 80004340 <end_op>
  p->cwd = 0;
    8000239c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023a0:	00007497          	auipc	s1,0x7
    800023a4:	c7848493          	addi	s1,s1,-904 # 80009018 <initproc>
    800023a8:	6088                	ld	a0,0(s1)
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	852080e7          	jalr	-1966(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    800023b2:	6088                	ld	a0,0(s1)
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	4c4080e7          	jalr	1220(ra) # 80001878 <wakeup1>
  release(&initproc->lock);
    800023bc:	6088                	ld	a0,0(s1)
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8f2080e7          	jalr	-1806(ra) # 80000cb0 <release>
  acquire(&p->lock);
    800023c6:	854e                	mv	a0,s3
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	834080e7          	jalr	-1996(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    800023d0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023d4:	854e                	mv	a0,s3
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8da080e7          	jalr	-1830(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	81c080e7          	jalr	-2020(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    800023e8:	854e                	mv	a0,s3
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	812080e7          	jalr	-2030(ra) # 80000bfc <acquire>
  reparent(p);
    800023f2:	854e                	mv	a0,s3
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	c34080e7          	jalr	-972(ra) # 80002028 <reparent>
  wakeup1(original_parent);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	47a080e7          	jalr	1146(ra) # 80001878 <wakeup1>
  p->xstate = status;
    80002406:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000240a:	4791                	li	a5,4
    8000240c:	00f9ac23          	sw	a5,24(s3)
  p->change = 2;
    80002410:	4789                	li	a5,2
    80002412:	16f9a423          	sw	a5,360(s3)
  release(&original_parent->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	898080e7          	jalr	-1896(ra) # 80000cb0 <release>
  sched();
    80002420:	00000097          	auipc	ra,0x0
    80002424:	e32080e7          	jalr	-462(ra) # 80002252 <sched>
  panic("zombie exit");
    80002428:	00006517          	auipc	a0,0x6
    8000242c:	e9850513          	addi	a0,a0,-360 # 800082c0 <digits+0x280>
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	110080e7          	jalr	272(ra) # 80000540 <panic>

0000000080002438 <yield>:
{
    80002438:	1101                	addi	sp,sp,-32
    8000243a:	ec06                	sd	ra,24(sp)
    8000243c:	e822                	sd	s0,16(sp)
    8000243e:	e426                	sd	s1,8(sp)
    80002440:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	6a8080e7          	jalr	1704(ra) # 80001aea <myproc>
    8000244a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	7b0080e7          	jalr	1968(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    80002454:	4709                	li	a4,2
    80002456:	cc98                	sw	a4,24(s1)
  if (p->priority == 2)
    80002458:	1784a783          	lw	a5,376(s1)
    8000245c:	00e78c63          	beq	a5,a4,80002474 <yield+0x3c>
  else if (p->priority == 1)
    80002460:	4705                	li	a4,1
    80002462:	02e78f63          	beq	a5,a4,800024a0 <yield+0x68>
  else if (p->priority == 0)
    80002466:	ef99                	bnez	a5,80002484 <yield+0x4c>
   (p->Qtime[0]++);
    80002468:	16c4a783          	lw	a5,364(s1)
    8000246c:	2785                	addiw	a5,a5,1
    8000246e:	16f4a623          	sw	a5,364(s1)
    80002472:	a809                	j	80002484 <yield+0x4c>
    p->change = 1;
    80002474:	4785                	li	a5,1
    80002476:	16f4a423          	sw	a5,360(s1)
    (p->Qtime[2])++;
    8000247a:	1744a783          	lw	a5,372(s1)
    8000247e:	2785                	addiw	a5,a5,1
    80002480:	16f4aa23          	sw	a5,372(s1)
  sched();
    80002484:	00000097          	auipc	ra,0x0
    80002488:	dce080e7          	jalr	-562(ra) # 80002252 <sched>
  release(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	822080e7          	jalr	-2014(ra) # 80000cb0 <release>
}
    80002496:	60e2                	ld	ra,24(sp)
    80002498:	6442                	ld	s0,16(sp)
    8000249a:	64a2                	ld	s1,8(sp)
    8000249c:	6105                	addi	sp,sp,32
    8000249e:	8082                	ret
    (p->Qtime[1])++;
    800024a0:	1704a783          	lw	a5,368(s1)
    800024a4:	2785                	addiw	a5,a5,1
    800024a6:	16f4a823          	sw	a5,368(s1)
    800024aa:	bfe9                	j	80002484 <yield+0x4c>

00000000800024ac <sleep>:
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	89aa                	mv	s3,a0
    800024bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	62c080e7          	jalr	1580(ra) # 80001aea <myproc>
    800024c6:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    800024c8:	05250963          	beq	a0,s2,8000251a <sleep+0x6e>
    acquire(&p->lock); //DOC: sleeplock1
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	730080e7          	jalr	1840(ra) # 80000bfc <acquire>
    release(lk);
    800024d4:	854a                	mv	a0,s2
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7da080e7          	jalr	2010(ra) # 80000cb0 <release>
  p->chan = chan;
    800024de:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800024e2:	4785                	li	a5,1
    800024e4:	cc9c                	sw	a5,24(s1)
  p->change = 2;
    800024e6:	4789                	li	a5,2
    800024e8:	16f4a423          	sw	a5,360(s1)
  sched();
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	d66080e7          	jalr	-666(ra) # 80002252 <sched>
  p->chan = 0;
    800024f4:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800024f8:	8526                	mv	a0,s1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	7b6080e7          	jalr	1974(ra) # 80000cb0 <release>
    acquire(lk);
    80002502:	854a                	mv	a0,s2
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6f8080e7          	jalr	1784(ra) # 80000bfc <acquire>
}
    8000250c:	70a2                	ld	ra,40(sp)
    8000250e:	7402                	ld	s0,32(sp)
    80002510:	64e2                	ld	s1,24(sp)
    80002512:	6942                	ld	s2,16(sp)
    80002514:	69a2                	ld	s3,8(sp)
    80002516:	6145                	addi	sp,sp,48
    80002518:	8082                	ret
  p->chan = chan;
    8000251a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000251e:	4785                	li	a5,1
    80002520:	cd1c                	sw	a5,24(a0)
  p->change = 2;
    80002522:	4789                	li	a5,2
    80002524:	16f52423          	sw	a5,360(a0)
  sched();
    80002528:	00000097          	auipc	ra,0x0
    8000252c:	d2a080e7          	jalr	-726(ra) # 80002252 <sched>
  p->chan = 0;
    80002530:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    80002534:	bfe1                	j	8000250c <sleep+0x60>

0000000080002536 <wait>:
{
    80002536:	715d                	addi	sp,sp,-80
    80002538:	e486                	sd	ra,72(sp)
    8000253a:	e0a2                	sd	s0,64(sp)
    8000253c:	fc26                	sd	s1,56(sp)
    8000253e:	f84a                	sd	s2,48(sp)
    80002540:	f44e                	sd	s3,40(sp)
    80002542:	f052                	sd	s4,32(sp)
    80002544:	ec56                	sd	s5,24(sp)
    80002546:	e85a                	sd	s6,16(sp)
    80002548:	e45e                	sd	s7,8(sp)
    8000254a:	0880                	addi	s0,sp,80
    8000254c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	59c080e7          	jalr	1436(ra) # 80001aea <myproc>
    80002556:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	6a4080e7          	jalr	1700(ra) # 80000bfc <acquire>
    havekids = 0;
    80002560:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002562:	4a11                	li	s4,4
        havekids = 1;
    80002564:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002566:	00016997          	auipc	s3,0x16
    8000256a:	e0298993          	addi	s3,s3,-510 # 80018368 <tickslock>
    havekids = 0;
    8000256e:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002570:	00010497          	auipc	s1,0x10
    80002574:	df848493          	addi	s1,s1,-520 # 80012368 <proc>
    80002578:	a08d                	j	800025da <wait+0xa4>
          pid = np->pid;
    8000257a:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000257e:	000b0e63          	beqz	s6,8000259a <wait+0x64>
    80002582:	4691                	li	a3,4
    80002584:	03448613          	addi	a2,s1,52
    80002588:	85da                	mv	a1,s6
    8000258a:	05093503          	ld	a0,80(s2)
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	11c080e7          	jalr	284(ra) # 800016aa <copyout>
    80002596:	02054263          	bltz	a0,800025ba <wait+0x84>
          freeproc(np);
    8000259a:	8526                	mv	a0,s1
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	702080e7          	jalr	1794(ra) # 80001c9e <freeproc>
          release(&np->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	70a080e7          	jalr	1802(ra) # 80000cb0 <release>
          release(&p->lock);
    800025ae:	854a                	mv	a0,s2
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	700080e7          	jalr	1792(ra) # 80000cb0 <release>
          return pid;
    800025b8:	a8a9                	j	80002612 <wait+0xdc>
            release(&np->lock);
    800025ba:	8526                	mv	a0,s1
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6f4080e7          	jalr	1780(ra) # 80000cb0 <release>
            release(&p->lock);
    800025c4:	854a                	mv	a0,s2
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	6ea080e7          	jalr	1770(ra) # 80000cb0 <release>
            return -1;
    800025ce:	59fd                	li	s3,-1
    800025d0:	a089                	j	80002612 <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    800025d2:	18048493          	addi	s1,s1,384
    800025d6:	03348463          	beq	s1,s3,800025fe <wait+0xc8>
      if (np->parent == p)
    800025da:	709c                	ld	a5,32(s1)
    800025dc:	ff279be3          	bne	a5,s2,800025d2 <wait+0x9c>
        acquire(&np->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	61a080e7          	jalr	1562(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    800025ea:	4c9c                	lw	a5,24(s1)
    800025ec:	f94787e3          	beq	a5,s4,8000257a <wait+0x44>
        release(&np->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6be080e7          	jalr	1726(ra) # 80000cb0 <release>
        havekids = 1;
    800025fa:	8756                	mv	a4,s5
    800025fc:	bfd9                	j	800025d2 <wait+0x9c>
    if (!havekids || p->killed)
    800025fe:	c701                	beqz	a4,80002606 <wait+0xd0>
    80002600:	03092783          	lw	a5,48(s2)
    80002604:	c39d                	beqz	a5,8000262a <wait+0xf4>
      release(&p->lock);
    80002606:	854a                	mv	a0,s2
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	6a8080e7          	jalr	1704(ra) # 80000cb0 <release>
      return -1;
    80002610:	59fd                	li	s3,-1
}
    80002612:	854e                	mv	a0,s3
    80002614:	60a6                	ld	ra,72(sp)
    80002616:	6406                	ld	s0,64(sp)
    80002618:	74e2                	ld	s1,56(sp)
    8000261a:	7942                	ld	s2,48(sp)
    8000261c:	79a2                	ld	s3,40(sp)
    8000261e:	7a02                	ld	s4,32(sp)
    80002620:	6ae2                	ld	s5,24(sp)
    80002622:	6b42                	ld	s6,16(sp)
    80002624:	6ba2                	ld	s7,8(sp)
    80002626:	6161                	addi	sp,sp,80
    80002628:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    8000262a:	85ca                	mv	a1,s2
    8000262c:	854a                	mv	a0,s2
    8000262e:	00000097          	auipc	ra,0x0
    80002632:	e7e080e7          	jalr	-386(ra) # 800024ac <sleep>
    havekids = 0;
    80002636:	bf25                	j	8000256e <wait+0x38>

0000000080002638 <wakeup>:
{
    80002638:	7139                	addi	sp,sp,-64
    8000263a:	fc06                	sd	ra,56(sp)
    8000263c:	f822                	sd	s0,48(sp)
    8000263e:	f426                	sd	s1,40(sp)
    80002640:	f04a                	sd	s2,32(sp)
    80002642:	ec4e                	sd	s3,24(sp)
    80002644:	e852                	sd	s4,16(sp)
    80002646:	e456                	sd	s5,8(sp)
    80002648:	e05a                	sd	s6,0(sp)
    8000264a:	0080                	addi	s0,sp,64
    8000264c:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    8000264e:	00010497          	auipc	s1,0x10
    80002652:	d1a48493          	addi	s1,s1,-742 # 80012368 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    80002656:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002658:	4b09                	li	s6,2
      p->change = 3;
    8000265a:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000265c:	00016917          	auipc	s2,0x16
    80002660:	d0c90913          	addi	s2,s2,-756 # 80018368 <tickslock>
    80002664:	a811                	j	80002678 <wakeup+0x40>
    release(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	648080e7          	jalr	1608(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002670:	18048493          	addi	s1,s1,384
    80002674:	03248263          	beq	s1,s2,80002698 <wakeup+0x60>
    acquire(&p->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	582080e7          	jalr	1410(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    80002682:	4c9c                	lw	a5,24(s1)
    80002684:	ff3791e3          	bne	a5,s3,80002666 <wakeup+0x2e>
    80002688:	749c                	ld	a5,40(s1)
    8000268a:	fd479ee3          	bne	a5,s4,80002666 <wakeup+0x2e>
      p->state = RUNNABLE;
    8000268e:	0164ac23          	sw	s6,24(s1)
      p->change = 3;
    80002692:	1754a423          	sw	s5,360(s1)
    80002696:	bfc1                	j	80002666 <wakeup+0x2e>
}
    80002698:	70e2                	ld	ra,56(sp)
    8000269a:	7442                	ld	s0,48(sp)
    8000269c:	74a2                	ld	s1,40(sp)
    8000269e:	7902                	ld	s2,32(sp)
    800026a0:	69e2                	ld	s3,24(sp)
    800026a2:	6a42                	ld	s4,16(sp)
    800026a4:	6aa2                	ld	s5,8(sp)
    800026a6:	6b02                	ld	s6,0(sp)
    800026a8:	6121                	addi	sp,sp,64
    800026aa:	8082                	ret

00000000800026ac <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026ac:	7179                	addi	sp,sp,-48
    800026ae:	f406                	sd	ra,40(sp)
    800026b0:	f022                	sd	s0,32(sp)
    800026b2:	ec26                	sd	s1,24(sp)
    800026b4:	e84a                	sd	s2,16(sp)
    800026b6:	e44e                	sd	s3,8(sp)
    800026b8:	1800                	addi	s0,sp,48
    800026ba:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026bc:	00010497          	auipc	s1,0x10
    800026c0:	cac48493          	addi	s1,s1,-852 # 80012368 <proc>
    800026c4:	00016997          	auipc	s3,0x16
    800026c8:	ca498993          	addi	s3,s3,-860 # 80018368 <tickslock>
  {
    acquire(&p->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	52e080e7          	jalr	1326(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    800026d6:	5c9c                	lw	a5,56(s1)
    800026d8:	01278d63          	beq	a5,s2,800026f2 <kill+0x46>
        p->change = 3;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026dc:	8526                	mv	a0,s1
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	5d2080e7          	jalr	1490(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026e6:	18048493          	addi	s1,s1,384
    800026ea:	ff3491e3          	bne	s1,s3,800026cc <kill+0x20>
  }
  return -1;
    800026ee:	557d                	li	a0,-1
    800026f0:	a821                	j	80002708 <kill+0x5c>
      p->killed = 1;
    800026f2:	4785                	li	a5,1
    800026f4:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    800026f6:	4c98                	lw	a4,24(s1)
    800026f8:	00f70f63          	beq	a4,a5,80002716 <kill+0x6a>
      release(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	5b2080e7          	jalr	1458(ra) # 80000cb0 <release>
      return 0;
    80002706:	4501                	li	a0,0
}
    80002708:	70a2                	ld	ra,40(sp)
    8000270a:	7402                	ld	s0,32(sp)
    8000270c:	64e2                	ld	s1,24(sp)
    8000270e:	6942                	ld	s2,16(sp)
    80002710:	69a2                	ld	s3,8(sp)
    80002712:	6145                	addi	sp,sp,48
    80002714:	8082                	ret
        p->state = RUNNABLE;
    80002716:	4789                	li	a5,2
    80002718:	cc9c                	sw	a5,24(s1)
        p->change = 3;
    8000271a:	478d                	li	a5,3
    8000271c:	16f4a423          	sw	a5,360(s1)
    80002720:	bff1                	j	800026fc <kill+0x50>

0000000080002722 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	e052                	sd	s4,0(sp)
    80002730:	1800                	addi	s0,sp,48
    80002732:	84aa                	mv	s1,a0
    80002734:	892e                	mv	s2,a1
    80002736:	89b2                	mv	s3,a2
    80002738:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	3b0080e7          	jalr	944(ra) # 80001aea <myproc>
  if (user_dst)
    80002742:	c08d                	beqz	s1,80002764 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002744:	86d2                	mv	a3,s4
    80002746:	864e                	mv	a2,s3
    80002748:	85ca                	mv	a1,s2
    8000274a:	6928                	ld	a0,80(a0)
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	f5e080e7          	jalr	-162(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002754:	70a2                	ld	ra,40(sp)
    80002756:	7402                	ld	s0,32(sp)
    80002758:	64e2                	ld	s1,24(sp)
    8000275a:	6942                	ld	s2,16(sp)
    8000275c:	69a2                	ld	s3,8(sp)
    8000275e:	6a02                	ld	s4,0(sp)
    80002760:	6145                	addi	sp,sp,48
    80002762:	8082                	ret
    memmove((char *)dst, src, len);
    80002764:	000a061b          	sext.w	a2,s4
    80002768:	85ce                	mv	a1,s3
    8000276a:	854a                	mv	a0,s2
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	5e8080e7          	jalr	1512(ra) # 80000d54 <memmove>
    return 0;
    80002774:	8526                	mv	a0,s1
    80002776:	bff9                	j	80002754 <either_copyout+0x32>

0000000080002778 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002778:	7179                	addi	sp,sp,-48
    8000277a:	f406                	sd	ra,40(sp)
    8000277c:	f022                	sd	s0,32(sp)
    8000277e:	ec26                	sd	s1,24(sp)
    80002780:	e84a                	sd	s2,16(sp)
    80002782:	e44e                	sd	s3,8(sp)
    80002784:	e052                	sd	s4,0(sp)
    80002786:	1800                	addi	s0,sp,48
    80002788:	892a                	mv	s2,a0
    8000278a:	84ae                	mv	s1,a1
    8000278c:	89b2                	mv	s3,a2
    8000278e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002790:	fffff097          	auipc	ra,0xfffff
    80002794:	35a080e7          	jalr	858(ra) # 80001aea <myproc>
  if (user_src)
    80002798:	c08d                	beqz	s1,800027ba <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000279a:	86d2                	mv	a3,s4
    8000279c:	864e                	mv	a2,s3
    8000279e:	85ca                	mv	a1,s2
    800027a0:	6928                	ld	a0,80(a0)
    800027a2:	fffff097          	auipc	ra,0xfffff
    800027a6:	f94080e7          	jalr	-108(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027aa:	70a2                	ld	ra,40(sp)
    800027ac:	7402                	ld	s0,32(sp)
    800027ae:	64e2                	ld	s1,24(sp)
    800027b0:	6942                	ld	s2,16(sp)
    800027b2:	69a2                	ld	s3,8(sp)
    800027b4:	6a02                	ld	s4,0(sp)
    800027b6:	6145                	addi	sp,sp,48
    800027b8:	8082                	ret
    memmove(dst, (char *)src, len);
    800027ba:	000a061b          	sext.w	a2,s4
    800027be:	85ce                	mv	a1,s3
    800027c0:	854a                	mv	a0,s2
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	592080e7          	jalr	1426(ra) # 80000d54 <memmove>
    return 0;
    800027ca:	8526                	mv	a0,s1
    800027cc:	bff9                	j	800027aa <either_copyin+0x32>

00000000800027ce <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027ce:	715d                	addi	sp,sp,-80
    800027d0:	e486                	sd	ra,72(sp)
    800027d2:	e0a2                	sd	s0,64(sp)
    800027d4:	fc26                	sd	s1,56(sp)
    800027d6:	f84a                	sd	s2,48(sp)
    800027d8:	f44e                	sd	s3,40(sp)
    800027da:	f052                	sd	s4,32(sp)
    800027dc:	ec56                	sd	s5,24(sp)
    800027de:	e85a                	sd	s6,16(sp)
    800027e0:	e45e                	sd	s7,8(sp)
    800027e2:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	90450513          	addi	a0,a0,-1788 # 800080e8 <digits+0xa8>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	d9e080e7          	jalr	-610(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027f4:	00010497          	auipc	s1,0x10
    800027f8:	ccc48493          	addi	s1,s1,-820 # 800124c0 <proc+0x158>
    800027fc:	00016917          	auipc	s2,0x16
    80002800:	cc490913          	addi	s2,s2,-828 # 800184c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002804:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002806:	00006997          	auipc	s3,0x6
    8000280a:	aca98993          	addi	s3,s3,-1334 # 800082d0 <digits+0x290>
    printf("%d %s %s", p->pid, state, p->name);
    8000280e:	00006a97          	auipc	s5,0x6
    80002812:	acaa8a93          	addi	s5,s5,-1334 # 800082d8 <digits+0x298>
    printf("\n");
    80002816:	00006a17          	auipc	s4,0x6
    8000281a:	8d2a0a13          	addi	s4,s4,-1838 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281e:	00006b97          	auipc	s7,0x6
    80002822:	af2b8b93          	addi	s7,s7,-1294 # 80008310 <states.0>
    80002826:	a00d                	j	80002848 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002828:	ee06a583          	lw	a1,-288(a3)
    8000282c:	8556                	mv	a0,s5
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	d5c080e7          	jalr	-676(ra) # 8000058a <printf>
    printf("\n");
    80002836:	8552                	mv	a0,s4
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	d52080e7          	jalr	-686(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002840:	18048493          	addi	s1,s1,384
    80002844:	03248263          	beq	s1,s2,80002868 <procdump+0x9a>
    if (p->state == UNUSED)
    80002848:	86a6                	mv	a3,s1
    8000284a:	ec04a783          	lw	a5,-320(s1)
    8000284e:	dbed                	beqz	a5,80002840 <procdump+0x72>
      state = "???";
    80002850:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002852:	fcfb6be3          	bltu	s6,a5,80002828 <procdump+0x5a>
    80002856:	02079713          	slli	a4,a5,0x20
    8000285a:	01d75793          	srli	a5,a4,0x1d
    8000285e:	97de                	add	a5,a5,s7
    80002860:	6390                	ld	a2,0(a5)
    80002862:	f279                	bnez	a2,80002828 <procdump+0x5a>
      state = "???";
    80002864:	864e                	mv	a2,s3
    80002866:	b7c9                	j	80002828 <procdump+0x5a>
  }
}
    80002868:	60a6                	ld	ra,72(sp)
    8000286a:	6406                	ld	s0,64(sp)
    8000286c:	74e2                	ld	s1,56(sp)
    8000286e:	7942                	ld	s2,48(sp)
    80002870:	79a2                	ld	s3,40(sp)
    80002872:	7a02                	ld	s4,32(sp)
    80002874:	6ae2                	ld	s5,24(sp)
    80002876:	6b42                	ld	s6,16(sp)
    80002878:	6ba2                	ld	s7,8(sp)
    8000287a:	6161                	addi	sp,sp,80
    8000287c:	8082                	ret

000000008000287e <swtch>:
    8000287e:	00153023          	sd	ra,0(a0)
    80002882:	00253423          	sd	sp,8(a0)
    80002886:	e900                	sd	s0,16(a0)
    80002888:	ed04                	sd	s1,24(a0)
    8000288a:	03253023          	sd	s2,32(a0)
    8000288e:	03353423          	sd	s3,40(a0)
    80002892:	03453823          	sd	s4,48(a0)
    80002896:	03553c23          	sd	s5,56(a0)
    8000289a:	05653023          	sd	s6,64(a0)
    8000289e:	05753423          	sd	s7,72(a0)
    800028a2:	05853823          	sd	s8,80(a0)
    800028a6:	05953c23          	sd	s9,88(a0)
    800028aa:	07a53023          	sd	s10,96(a0)
    800028ae:	07b53423          	sd	s11,104(a0)
    800028b2:	0005b083          	ld	ra,0(a1)
    800028b6:	0085b103          	ld	sp,8(a1)
    800028ba:	6980                	ld	s0,16(a1)
    800028bc:	6d84                	ld	s1,24(a1)
    800028be:	0205b903          	ld	s2,32(a1)
    800028c2:	0285b983          	ld	s3,40(a1)
    800028c6:	0305ba03          	ld	s4,48(a1)
    800028ca:	0385ba83          	ld	s5,56(a1)
    800028ce:	0405bb03          	ld	s6,64(a1)
    800028d2:	0485bb83          	ld	s7,72(a1)
    800028d6:	0505bc03          	ld	s8,80(a1)
    800028da:	0585bc83          	ld	s9,88(a1)
    800028de:	0605bd03          	ld	s10,96(a1)
    800028e2:	0685bd83          	ld	s11,104(a1)
    800028e6:	8082                	ret

00000000800028e8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028e8:	1141                	addi	sp,sp,-16
    800028ea:	e406                	sd	ra,8(sp)
    800028ec:	e022                	sd	s0,0(sp)
    800028ee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028f0:	00006597          	auipc	a1,0x6
    800028f4:	a4858593          	addi	a1,a1,-1464 # 80008338 <states.0+0x28>
    800028f8:	00016517          	auipc	a0,0x16
    800028fc:	a7050513          	addi	a0,a0,-1424 # 80018368 <tickslock>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	26c080e7          	jalr	620(ra) # 80000b6c <initlock>
}
    80002908:	60a2                	ld	ra,8(sp)
    8000290a:	6402                	ld	s0,0(sp)
    8000290c:	0141                	addi	sp,sp,16
    8000290e:	8082                	ret

0000000080002910 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002910:	1141                	addi	sp,sp,-16
    80002912:	e422                	sd	s0,8(sp)
    80002914:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002916:	00003797          	auipc	a5,0x3
    8000291a:	4da78793          	addi	a5,a5,1242 # 80005df0 <kernelvec>
    8000291e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002922:	6422                	ld	s0,8(sp)
    80002924:	0141                	addi	sp,sp,16
    80002926:	8082                	ret

0000000080002928 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002928:	1141                	addi	sp,sp,-16
    8000292a:	e406                	sd	ra,8(sp)
    8000292c:	e022                	sd	s0,0(sp)
    8000292e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	1ba080e7          	jalr	442(ra) # 80001aea <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002938:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000293c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000293e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002942:	00004617          	auipc	a2,0x4
    80002946:	6be60613          	addi	a2,a2,1726 # 80007000 <_trampoline>
    8000294a:	00004697          	auipc	a3,0x4
    8000294e:	6b668693          	addi	a3,a3,1718 # 80007000 <_trampoline>
    80002952:	8e91                	sub	a3,a3,a2
    80002954:	040007b7          	lui	a5,0x4000
    80002958:	17fd                	addi	a5,a5,-1
    8000295a:	07b2                	slli	a5,a5,0xc
    8000295c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000295e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002962:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002964:	180026f3          	csrr	a3,satp
    80002968:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000296a:	6d38                	ld	a4,88(a0)
    8000296c:	6134                	ld	a3,64(a0)
    8000296e:	6585                	lui	a1,0x1
    80002970:	96ae                	add	a3,a3,a1
    80002972:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002974:	6d38                	ld	a4,88(a0)
    80002976:	00000697          	auipc	a3,0x0
    8000297a:	13868693          	addi	a3,a3,312 # 80002aae <usertrap>
    8000297e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002980:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002982:	8692                	mv	a3,tp
    80002984:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002986:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000298a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000298e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002992:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002996:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002998:	6f18                	ld	a4,24(a4)
    8000299a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000299e:	692c                	ld	a1,80(a0)
    800029a0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029a2:	00004717          	auipc	a4,0x4
    800029a6:	6ee70713          	addi	a4,a4,1774 # 80007090 <userret>
    800029aa:	8f11                	sub	a4,a4,a2
    800029ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ae:	577d                	li	a4,-1
    800029b0:	177e                	slli	a4,a4,0x3f
    800029b2:	8dd9                	or	a1,a1,a4
    800029b4:	02000537          	lui	a0,0x2000
    800029b8:	157d                	addi	a0,a0,-1
    800029ba:	0536                	slli	a0,a0,0xd
    800029bc:	9782                	jalr	a5
}
    800029be:	60a2                	ld	ra,8(sp)
    800029c0:	6402                	ld	s0,0(sp)
    800029c2:	0141                	addi	sp,sp,16
    800029c4:	8082                	ret

00000000800029c6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029c6:	1101                	addi	sp,sp,-32
    800029c8:	ec06                	sd	ra,24(sp)
    800029ca:	e822                	sd	s0,16(sp)
    800029cc:	e426                	sd	s1,8(sp)
    800029ce:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029d0:	00016497          	auipc	s1,0x16
    800029d4:	99848493          	addi	s1,s1,-1640 # 80018368 <tickslock>
    800029d8:	8526                	mv	a0,s1
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	222080e7          	jalr	546(ra) # 80000bfc <acquire>
  ticks++;
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	63e50513          	addi	a0,a0,1598 # 80009020 <ticks>
    800029ea:	411c                	lw	a5,0(a0)
    800029ec:	2785                	addiw	a5,a5,1
    800029ee:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	c48080e7          	jalr	-952(ra) # 80002638 <wakeup>
  release(&tickslock);
    800029f8:	8526                	mv	a0,s1
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	2b6080e7          	jalr	694(ra) # 80000cb0 <release>
}
    80002a02:	60e2                	ld	ra,24(sp)
    80002a04:	6442                	ld	s0,16(sp)
    80002a06:	64a2                	ld	s1,8(sp)
    80002a08:	6105                	addi	sp,sp,32
    80002a0a:	8082                	ret

0000000080002a0c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a0c:	1101                	addi	sp,sp,-32
    80002a0e:	ec06                	sd	ra,24(sp)
    80002a10:	e822                	sd	s0,16(sp)
    80002a12:	e426                	sd	s1,8(sp)
    80002a14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a16:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a1a:	00074d63          	bltz	a4,80002a34 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a1e:	57fd                	li	a5,-1
    80002a20:	17fe                	slli	a5,a5,0x3f
    80002a22:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a24:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a26:	06f70363          	beq	a4,a5,80002a8c <devintr+0x80>
  }
}
    80002a2a:	60e2                	ld	ra,24(sp)
    80002a2c:	6442                	ld	s0,16(sp)
    80002a2e:	64a2                	ld	s1,8(sp)
    80002a30:	6105                	addi	sp,sp,32
    80002a32:	8082                	ret
     (scause & 0xff) == 9){
    80002a34:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a38:	46a5                	li	a3,9
    80002a3a:	fed792e3          	bne	a5,a3,80002a1e <devintr+0x12>
    int irq = plic_claim();
    80002a3e:	00003097          	auipc	ra,0x3
    80002a42:	4ba080e7          	jalr	1210(ra) # 80005ef8 <plic_claim>
    80002a46:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a48:	47a9                	li	a5,10
    80002a4a:	02f50763          	beq	a0,a5,80002a78 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a4e:	4785                	li	a5,1
    80002a50:	02f50963          	beq	a0,a5,80002a82 <devintr+0x76>
    return 1;
    80002a54:	4505                	li	a0,1
    } else if(irq){
    80002a56:	d8f1                	beqz	s1,80002a2a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a58:	85a6                	mv	a1,s1
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	8e650513          	addi	a0,a0,-1818 # 80008340 <states.0+0x30>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b28080e7          	jalr	-1240(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a6a:	8526                	mv	a0,s1
    80002a6c:	00003097          	auipc	ra,0x3
    80002a70:	4b0080e7          	jalr	1200(ra) # 80005f1c <plic_complete>
    return 1;
    80002a74:	4505                	li	a0,1
    80002a76:	bf55                	j	80002a2a <devintr+0x1e>
      uartintr();
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	f48080e7          	jalr	-184(ra) # 800009c0 <uartintr>
    80002a80:	b7ed                	j	80002a6a <devintr+0x5e>
      virtio_disk_intr();
    80002a82:	00004097          	auipc	ra,0x4
    80002a86:	914080e7          	jalr	-1772(ra) # 80006396 <virtio_disk_intr>
    80002a8a:	b7c5                	j	80002a6a <devintr+0x5e>
    if(cpuid() == 0){
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	032080e7          	jalr	50(ra) # 80001abe <cpuid>
    80002a94:	c901                	beqz	a0,80002aa4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a96:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a9a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a9c:	14479073          	csrw	sip,a5
    return 2;
    80002aa0:	4509                	li	a0,2
    80002aa2:	b761                	j	80002a2a <devintr+0x1e>
      clockintr();
    80002aa4:	00000097          	auipc	ra,0x0
    80002aa8:	f22080e7          	jalr	-222(ra) # 800029c6 <clockintr>
    80002aac:	b7ed                	j	80002a96 <devintr+0x8a>

0000000080002aae <usertrap>:
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	e04a                	sd	s2,0(sp)
    80002ab8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002abe:	1007f793          	andi	a5,a5,256
    80002ac2:	e3ad                	bnez	a5,80002b24 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ac4:	00003797          	auipc	a5,0x3
    80002ac8:	32c78793          	addi	a5,a5,812 # 80005df0 <kernelvec>
    80002acc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	01a080e7          	jalr	26(ra) # 80001aea <myproc>
    80002ad8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ada:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002adc:	14102773          	csrr	a4,sepc
    80002ae0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ae6:	47a1                	li	a5,8
    80002ae8:	04f71c63          	bne	a4,a5,80002b40 <usertrap+0x92>
    if(p->killed)
    80002aec:	591c                	lw	a5,48(a0)
    80002aee:	e3b9                	bnez	a5,80002b34 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002af0:	6cb8                	ld	a4,88(s1)
    80002af2:	6f1c                	ld	a5,24(a4)
    80002af4:	0791                	addi	a5,a5,4
    80002af6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002afc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b00:	10079073          	csrw	sstatus,a5
    syscall();
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	2f8080e7          	jalr	760(ra) # 80002dfc <syscall>
  if(p->killed)
    80002b0c:	589c                	lw	a5,48(s1)
    80002b0e:	ebc1                	bnez	a5,80002b9e <usertrap+0xf0>
  usertrapret();
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	e18080e7          	jalr	-488(ra) # 80002928 <usertrapret>
}
    80002b18:	60e2                	ld	ra,24(sp)
    80002b1a:	6442                	ld	s0,16(sp)
    80002b1c:	64a2                	ld	s1,8(sp)
    80002b1e:	6902                	ld	s2,0(sp)
    80002b20:	6105                	addi	sp,sp,32
    80002b22:	8082                	ret
    panic("usertrap: not from user mode");
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	83c50513          	addi	a0,a0,-1988 # 80008360 <states.0+0x50>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a14080e7          	jalr	-1516(ra) # 80000540 <panic>
      exit(-1);
    80002b34:	557d                	li	a0,-1
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	7f2080e7          	jalr	2034(ra) # 80002328 <exit>
    80002b3e:	bf4d                	j	80002af0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	ecc080e7          	jalr	-308(ra) # 80002a0c <devintr>
    80002b48:	892a                	mv	s2,a0
    80002b4a:	c501                	beqz	a0,80002b52 <usertrap+0xa4>
  if(p->killed)
    80002b4c:	589c                	lw	a5,48(s1)
    80002b4e:	c3a1                	beqz	a5,80002b8e <usertrap+0xe0>
    80002b50:	a815                	j	80002b84 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b52:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b56:	5c90                	lw	a2,56(s1)
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	82850513          	addi	a0,a0,-2008 # 80008380 <states.0+0x70>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	a2a080e7          	jalr	-1494(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b68:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b70:	00006517          	auipc	a0,0x6
    80002b74:	84050513          	addi	a0,a0,-1984 # 800083b0 <states.0+0xa0>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	a12080e7          	jalr	-1518(ra) # 8000058a <printf>
    p->killed = 1;
    80002b80:	4785                	li	a5,1
    80002b82:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b84:	557d                	li	a0,-1
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	7a2080e7          	jalr	1954(ra) # 80002328 <exit>
  if(which_dev == 2)
    80002b8e:	4789                	li	a5,2
    80002b90:	f8f910e3          	bne	s2,a5,80002b10 <usertrap+0x62>
    yield();
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	8a4080e7          	jalr	-1884(ra) # 80002438 <yield>
    80002b9c:	bf95                	j	80002b10 <usertrap+0x62>
  int which_dev = 0;
    80002b9e:	4901                	li	s2,0
    80002ba0:	b7d5                	j	80002b84 <usertrap+0xd6>

0000000080002ba2 <kerneltrap>:
{
    80002ba2:	7179                	addi	sp,sp,-48
    80002ba4:	f406                	sd	ra,40(sp)
    80002ba6:	f022                	sd	s0,32(sp)
    80002ba8:	ec26                	sd	s1,24(sp)
    80002baa:	e84a                	sd	s2,16(sp)
    80002bac:	e44e                	sd	s3,8(sp)
    80002bae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bbc:	1004f793          	andi	a5,s1,256
    80002bc0:	cb85                	beqz	a5,80002bf0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bc6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bc8:	ef85                	bnez	a5,80002c00 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	e42080e7          	jalr	-446(ra) # 80002a0c <devintr>
    80002bd2:	cd1d                	beqz	a0,80002c10 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd4:	4789                	li	a5,2
    80002bd6:	08f50663          	beq	a0,a5,80002c62 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bda:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bde:	10049073          	csrw	sstatus,s1
}
    80002be2:	70a2                	ld	ra,40(sp)
    80002be4:	7402                	ld	s0,32(sp)
    80002be6:	64e2                	ld	s1,24(sp)
    80002be8:	6942                	ld	s2,16(sp)
    80002bea:	69a2                	ld	s3,8(sp)
    80002bec:	6145                	addi	sp,sp,48
    80002bee:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bf0:	00005517          	auipc	a0,0x5
    80002bf4:	7e050513          	addi	a0,a0,2016 # 800083d0 <states.0+0xc0>
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	948080e7          	jalr	-1720(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c00:	00005517          	auipc	a0,0x5
    80002c04:	7f850513          	addi	a0,a0,2040 # 800083f8 <states.0+0xe8>
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	938080e7          	jalr	-1736(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c10:	00006597          	auipc	a1,0x6
    80002c14:	4105a583          	lw	a1,1040(a1) # 80009020 <ticks>
    80002c18:	00006517          	auipc	a0,0x6
    80002c1c:	85850513          	addi	a0,a0,-1960 # 80008470 <states.0+0x160>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	96a080e7          	jalr	-1686(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002c28:	85ce                	mv	a1,s3
    80002c2a:	00005517          	auipc	a0,0x5
    80002c2e:	7ee50513          	addi	a0,a0,2030 # 80008418 <states.0+0x108>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	958080e7          	jalr	-1704(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c3e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	7e650513          	addi	a0,a0,2022 # 80008428 <states.0+0x118>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	940080e7          	jalr	-1728(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	7ee50513          	addi	a0,a0,2030 # 80008440 <states.0+0x130>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e6080e7          	jalr	-1818(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	e88080e7          	jalr	-376(ra) # 80001aea <myproc>
    80002c6a:	d925                	beqz	a0,80002bda <kerneltrap+0x38>
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	e7e080e7          	jalr	-386(ra) # 80001aea <myproc>
    80002c74:	4d18                	lw	a4,24(a0)
    80002c76:	478d                	li	a5,3
    80002c78:	f6f711e3          	bne	a4,a5,80002bda <kerneltrap+0x38>
    yield();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	7bc080e7          	jalr	1980(ra) # 80002438 <yield>
    80002c84:	bf99                	j	80002bda <kerneltrap+0x38>

0000000080002c86 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	e426                	sd	s1,8(sp)
    80002c8e:	1000                	addi	s0,sp,32
    80002c90:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	e58080e7          	jalr	-424(ra) # 80001aea <myproc>
  switch (n)
    80002c9a:	4795                	li	a5,5
    80002c9c:	0497e163          	bltu	a5,s1,80002cde <argraw+0x58>
    80002ca0:	048a                	slli	s1,s1,0x2
    80002ca2:	00005717          	auipc	a4,0x5
    80002ca6:	7d670713          	addi	a4,a4,2006 # 80008478 <states.0+0x168>
    80002caa:	94ba                	add	s1,s1,a4
    80002cac:	409c                	lw	a5,0(s1)
    80002cae:	97ba                	add	a5,a5,a4
    80002cb0:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002cb2:	6d3c                	ld	a5,88(a0)
    80002cb4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cb6:	60e2                	ld	ra,24(sp)
    80002cb8:	6442                	ld	s0,16(sp)
    80002cba:	64a2                	ld	s1,8(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret
    return p->trapframe->a1;
    80002cc0:	6d3c                	ld	a5,88(a0)
    80002cc2:	7fa8                	ld	a0,120(a5)
    80002cc4:	bfcd                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a2;
    80002cc6:	6d3c                	ld	a5,88(a0)
    80002cc8:	63c8                	ld	a0,128(a5)
    80002cca:	b7f5                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a3;
    80002ccc:	6d3c                	ld	a5,88(a0)
    80002cce:	67c8                	ld	a0,136(a5)
    80002cd0:	b7dd                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a4;
    80002cd2:	6d3c                	ld	a5,88(a0)
    80002cd4:	6bc8                	ld	a0,144(a5)
    80002cd6:	b7c5                	j	80002cb6 <argraw+0x30>
    return p->trapframe->a5;
    80002cd8:	6d3c                	ld	a5,88(a0)
    80002cda:	6fc8                	ld	a0,152(a5)
    80002cdc:	bfe9                	j	80002cb6 <argraw+0x30>
  panic("argraw");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	77250513          	addi	a0,a0,1906 # 80008450 <states.0+0x140>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	85a080e7          	jalr	-1958(ra) # 80000540 <panic>

0000000080002cee <fetchaddr>:
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	e04a                	sd	s2,0(sp)
    80002cf8:	1000                	addi	s0,sp,32
    80002cfa:	84aa                	mv	s1,a0
    80002cfc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	dec080e7          	jalr	-532(ra) # 80001aea <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d06:	653c                	ld	a5,72(a0)
    80002d08:	02f4f863          	bgeu	s1,a5,80002d38 <fetchaddr+0x4a>
    80002d0c:	00848713          	addi	a4,s1,8
    80002d10:	02e7e663          	bltu	a5,a4,80002d3c <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d14:	46a1                	li	a3,8
    80002d16:	8626                	mv	a2,s1
    80002d18:	85ca                	mv	a1,s2
    80002d1a:	6928                	ld	a0,80(a0)
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	a1a080e7          	jalr	-1510(ra) # 80001736 <copyin>
    80002d24:	00a03533          	snez	a0,a0
    80002d28:	40a00533          	neg	a0,a0
}
    80002d2c:	60e2                	ld	ra,24(sp)
    80002d2e:	6442                	ld	s0,16(sp)
    80002d30:	64a2                	ld	s1,8(sp)
    80002d32:	6902                	ld	s2,0(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret
    return -1;
    80002d38:	557d                	li	a0,-1
    80002d3a:	bfcd                	j	80002d2c <fetchaddr+0x3e>
    80002d3c:	557d                	li	a0,-1
    80002d3e:	b7fd                	j	80002d2c <fetchaddr+0x3e>

0000000080002d40 <fetchstr>:
{
    80002d40:	7179                	addi	sp,sp,-48
    80002d42:	f406                	sd	ra,40(sp)
    80002d44:	f022                	sd	s0,32(sp)
    80002d46:	ec26                	sd	s1,24(sp)
    80002d48:	e84a                	sd	s2,16(sp)
    80002d4a:	e44e                	sd	s3,8(sp)
    80002d4c:	1800                	addi	s0,sp,48
    80002d4e:	892a                	mv	s2,a0
    80002d50:	84ae                	mv	s1,a1
    80002d52:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	d96080e7          	jalr	-618(ra) # 80001aea <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d5c:	86ce                	mv	a3,s3
    80002d5e:	864a                	mv	a2,s2
    80002d60:	85a6                	mv	a1,s1
    80002d62:	6928                	ld	a0,80(a0)
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	a60080e7          	jalr	-1440(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002d6c:	00054763          	bltz	a0,80002d7a <fetchstr+0x3a>
  return strlen(buf);
    80002d70:	8526                	mv	a0,s1
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	10a080e7          	jalr	266(ra) # 80000e7c <strlen>
}
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6942                	ld	s2,16(sp)
    80002d82:	69a2                	ld	s3,8(sp)
    80002d84:	6145                	addi	sp,sp,48
    80002d86:	8082                	ret

0000000080002d88 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	1000                	addi	s0,sp,32
    80002d92:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	ef2080e7          	jalr	-270(ra) # 80002c86 <argraw>
    80002d9c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d9e:	4501                	li	a0,0
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	e426                	sd	s1,8(sp)
    80002db2:	1000                	addi	s0,sp,32
    80002db4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	ed0080e7          	jalr	-304(ra) # 80002c86 <argraw>
    80002dbe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc0:	4501                	li	a0,0
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	e04a                	sd	s2,0(sp)
    80002dd6:	1000                	addi	s0,sp,32
    80002dd8:	84ae                	mv	s1,a1
    80002dda:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	eaa080e7          	jalr	-342(ra) # 80002c86 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002de4:	864a                	mv	a2,s2
    80002de6:	85a6                	mv	a1,s1
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	f58080e7          	jalr	-168(ra) # 80002d40 <fetchstr>
}
    80002df0:	60e2                	ld	ra,24(sp)
    80002df2:	6442                	ld	s0,16(sp)
    80002df4:	64a2                	ld	s1,8(sp)
    80002df6:	6902                	ld	s2,0(sp)
    80002df8:	6105                	addi	sp,sp,32
    80002dfa:	8082                	ret

0000000080002dfc <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	e426                	sd	s1,8(sp)
    80002e04:	e04a                	sd	s2,0(sp)
    80002e06:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	ce2080e7          	jalr	-798(ra) # 80001aea <myproc>
    80002e10:	84aa                	mv	s1,a0

  p->change = 3;
    80002e12:	478d                	li	a5,3
    80002e14:	16f52423          	sw	a5,360(a0)

  num = p->trapframe->a7;
    80002e18:	05853903          	ld	s2,88(a0)
    80002e1c:	0a893783          	ld	a5,168(s2)
    80002e20:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e24:	37fd                	addiw	a5,a5,-1
    80002e26:	4751                	li	a4,20
    80002e28:	00f76f63          	bltu	a4,a5,80002e46 <syscall+0x4a>
    80002e2c:	00369713          	slli	a4,a3,0x3
    80002e30:	00005797          	auipc	a5,0x5
    80002e34:	66078793          	addi	a5,a5,1632 # 80008490 <syscalls>
    80002e38:	97ba                	add	a5,a5,a4
    80002e3a:	639c                	ld	a5,0(a5)
    80002e3c:	c789                	beqz	a5,80002e46 <syscall+0x4a>
  {
    p->trapframe->a0 = syscalls[num]();
    80002e3e:	9782                	jalr	a5
    80002e40:	06a93823          	sd	a0,112(s2)
    80002e44:	a839                	j	80002e62 <syscall+0x66>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e46:	15848613          	addi	a2,s1,344
    80002e4a:	5c8c                	lw	a1,56(s1)
    80002e4c:	00005517          	auipc	a0,0x5
    80002e50:	60c50513          	addi	a0,a0,1548 # 80008458 <states.0+0x148>
    80002e54:	ffffd097          	auipc	ra,0xffffd
    80002e58:	736080e7          	jalr	1846(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e5c:	6cbc                	ld	a5,88(s1)
    80002e5e:	577d                	li	a4,-1
    80002e60:	fbb8                	sd	a4,112(a5)
  }
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6902                	ld	s2,0(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e76:	fec40593          	addi	a1,s0,-20
    80002e7a:	4501                	li	a0,0
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	f0c080e7          	jalr	-244(ra) # 80002d88 <argint>
    return -1;
    80002e84:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e86:	00054963          	bltz	a0,80002e98 <sys_exit+0x2a>
  exit(n);
    80002e8a:	fec42503          	lw	a0,-20(s0)
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	49a080e7          	jalr	1178(ra) # 80002328 <exit>
  return 0;  // not reached
    80002e96:	4781                	li	a5,0
}
    80002e98:	853e                	mv	a0,a5
    80002e9a:	60e2                	ld	ra,24(sp)
    80002e9c:	6442                	ld	s0,16(sp)
    80002e9e:	6105                	addi	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea2:	1141                	addi	sp,sp,-16
    80002ea4:	e406                	sd	ra,8(sp)
    80002ea6:	e022                	sd	s0,0(sp)
    80002ea8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	c40080e7          	jalr	-960(ra) # 80001aea <myproc>
}
    80002eb2:	5d08                	lw	a0,56(a0)
    80002eb4:	60a2                	ld	ra,8(sp)
    80002eb6:	6402                	ld	s0,0(sp)
    80002eb8:	0141                	addi	sp,sp,16
    80002eba:	8082                	ret

0000000080002ebc <sys_fork>:

uint64
sys_fork(void)
{
    80002ebc:	1141                	addi	sp,sp,-16
    80002ebe:	e406                	sd	ra,8(sp)
    80002ec0:	e022                	sd	s0,0(sp)
    80002ec2:	0800                	addi	s0,sp,16
  return fork();
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	03a080e7          	jalr	58(ra) # 80001efe <fork>
}
    80002ecc:	60a2                	ld	ra,8(sp)
    80002ece:	6402                	ld	s0,0(sp)
    80002ed0:	0141                	addi	sp,sp,16
    80002ed2:	8082                	ret

0000000080002ed4 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed4:	1101                	addi	sp,sp,-32
    80002ed6:	ec06                	sd	ra,24(sp)
    80002ed8:	e822                	sd	s0,16(sp)
    80002eda:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002edc:	fe840593          	addi	a1,s0,-24
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	ec8080e7          	jalr	-312(ra) # 80002daa <argaddr>
    80002eea:	87aa                	mv	a5,a0
    return -1;
    80002eec:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002eee:	0007c863          	bltz	a5,80002efe <sys_wait+0x2a>
  return wait(p);
    80002ef2:	fe843503          	ld	a0,-24(s0)
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	640080e7          	jalr	1600(ra) # 80002536 <wait>
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	6105                	addi	sp,sp,32
    80002f04:	8082                	ret

0000000080002f06 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f06:	7179                	addi	sp,sp,-48
    80002f08:	f406                	sd	ra,40(sp)
    80002f0a:	f022                	sd	s0,32(sp)
    80002f0c:	ec26                	sd	s1,24(sp)
    80002f0e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f10:	fdc40593          	addi	a1,s0,-36
    80002f14:	4501                	li	a0,0
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	e72080e7          	jalr	-398(ra) # 80002d88 <argint>
    return -1;
    80002f1e:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f20:	00054f63          	bltz	a0,80002f3e <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	bc6080e7          	jalr	-1082(ra) # 80001aea <myproc>
    80002f2c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f2e:	fdc42503          	lw	a0,-36(s0)
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	f58080e7          	jalr	-168(ra) # 80001e8a <growproc>
    80002f3a:	00054863          	bltz	a0,80002f4a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f3e:	8526                	mv	a0,s1
    80002f40:	70a2                	ld	ra,40(sp)
    80002f42:	7402                	ld	s0,32(sp)
    80002f44:	64e2                	ld	s1,24(sp)
    80002f46:	6145                	addi	sp,sp,48
    80002f48:	8082                	ret
    return -1;
    80002f4a:	54fd                	li	s1,-1
    80002f4c:	bfcd                	j	80002f3e <sys_sbrk+0x38>

0000000080002f4e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f4e:	7139                	addi	sp,sp,-64
    80002f50:	fc06                	sd	ra,56(sp)
    80002f52:	f822                	sd	s0,48(sp)
    80002f54:	f426                	sd	s1,40(sp)
    80002f56:	f04a                	sd	s2,32(sp)
    80002f58:	ec4e                	sd	s3,24(sp)
    80002f5a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f5c:	fcc40593          	addi	a1,s0,-52
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	e26080e7          	jalr	-474(ra) # 80002d88 <argint>
    return -1;
    80002f6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6c:	06054563          	bltz	a0,80002fd6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f70:	00015517          	auipc	a0,0x15
    80002f74:	3f850513          	addi	a0,a0,1016 # 80018368 <tickslock>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	c84080e7          	jalr	-892(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002f80:	00006917          	auipc	s2,0x6
    80002f84:	0a092903          	lw	s2,160(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f88:	fcc42783          	lw	a5,-52(s0)
    80002f8c:	cf85                	beqz	a5,80002fc4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f8e:	00015997          	auipc	s3,0x15
    80002f92:	3da98993          	addi	s3,s3,986 # 80018368 <tickslock>
    80002f96:	00006497          	auipc	s1,0x6
    80002f9a:	08a48493          	addi	s1,s1,138 # 80009020 <ticks>
    if(myproc()->killed){
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	b4c080e7          	jalr	-1204(ra) # 80001aea <myproc>
    80002fa6:	591c                	lw	a5,48(a0)
    80002fa8:	ef9d                	bnez	a5,80002fe6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002faa:	85ce                	mv	a1,s3
    80002fac:	8526                	mv	a0,s1
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	4fe080e7          	jalr	1278(ra) # 800024ac <sleep>
  while(ticks - ticks0 < n){
    80002fb6:	409c                	lw	a5,0(s1)
    80002fb8:	412787bb          	subw	a5,a5,s2
    80002fbc:	fcc42703          	lw	a4,-52(s0)
    80002fc0:	fce7efe3          	bltu	a5,a4,80002f9e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fc4:	00015517          	auipc	a0,0x15
    80002fc8:	3a450513          	addi	a0,a0,932 # 80018368 <tickslock>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	ce4080e7          	jalr	-796(ra) # 80000cb0 <release>
  return 0;
    80002fd4:	4781                	li	a5,0
}
    80002fd6:	853e                	mv	a0,a5
    80002fd8:	70e2                	ld	ra,56(sp)
    80002fda:	7442                	ld	s0,48(sp)
    80002fdc:	74a2                	ld	s1,40(sp)
    80002fde:	7902                	ld	s2,32(sp)
    80002fe0:	69e2                	ld	s3,24(sp)
    80002fe2:	6121                	addi	sp,sp,64
    80002fe4:	8082                	ret
      release(&tickslock);
    80002fe6:	00015517          	auipc	a0,0x15
    80002fea:	38250513          	addi	a0,a0,898 # 80018368 <tickslock>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	cc2080e7          	jalr	-830(ra) # 80000cb0 <release>
      return -1;
    80002ff6:	57fd                	li	a5,-1
    80002ff8:	bff9                	j	80002fd6 <sys_sleep+0x88>

0000000080002ffa <sys_kill>:

uint64
sys_kill(void)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003002:	fec40593          	addi	a1,s0,-20
    80003006:	4501                	li	a0,0
    80003008:	00000097          	auipc	ra,0x0
    8000300c:	d80080e7          	jalr	-640(ra) # 80002d88 <argint>
    80003010:	87aa                	mv	a5,a0
    return -1;
    80003012:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003014:	0007c863          	bltz	a5,80003024 <sys_kill+0x2a>
  return kill(pid);
    80003018:	fec42503          	lw	a0,-20(s0)
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	690080e7          	jalr	1680(ra) # 800026ac <kill>
}
    80003024:	60e2                	ld	ra,24(sp)
    80003026:	6442                	ld	s0,16(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret

000000008000302c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	e426                	sd	s1,8(sp)
    80003034:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003036:	00015517          	auipc	a0,0x15
    8000303a:	33250513          	addi	a0,a0,818 # 80018368 <tickslock>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	bbe080e7          	jalr	-1090(ra) # 80000bfc <acquire>
  xticks = ticks;
    80003046:	00006497          	auipc	s1,0x6
    8000304a:	fda4a483          	lw	s1,-38(s1) # 80009020 <ticks>
  release(&tickslock);
    8000304e:	00015517          	auipc	a0,0x15
    80003052:	31a50513          	addi	a0,a0,794 # 80018368 <tickslock>
    80003056:	ffffe097          	auipc	ra,0xffffe
    8000305a:	c5a080e7          	jalr	-934(ra) # 80000cb0 <release>
  return xticks;
}
    8000305e:	02049513          	slli	a0,s1,0x20
    80003062:	9101                	srli	a0,a0,0x20
    80003064:	60e2                	ld	ra,24(sp)
    80003066:	6442                	ld	s0,16(sp)
    80003068:	64a2                	ld	s1,8(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret

000000008000306e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000306e:	7179                	addi	sp,sp,-48
    80003070:	f406                	sd	ra,40(sp)
    80003072:	f022                	sd	s0,32(sp)
    80003074:	ec26                	sd	s1,24(sp)
    80003076:	e84a                	sd	s2,16(sp)
    80003078:	e44e                	sd	s3,8(sp)
    8000307a:	e052                	sd	s4,0(sp)
    8000307c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000307e:	00005597          	auipc	a1,0x5
    80003082:	4c258593          	addi	a1,a1,1218 # 80008540 <syscalls+0xb0>
    80003086:	00015517          	auipc	a0,0x15
    8000308a:	2fa50513          	addi	a0,a0,762 # 80018380 <bcache>
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	ade080e7          	jalr	-1314(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003096:	0001d797          	auipc	a5,0x1d
    8000309a:	2ea78793          	addi	a5,a5,746 # 80020380 <bcache+0x8000>
    8000309e:	0001d717          	auipc	a4,0x1d
    800030a2:	54a70713          	addi	a4,a4,1354 # 800205e8 <bcache+0x8268>
    800030a6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030aa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ae:	00015497          	auipc	s1,0x15
    800030b2:	2ea48493          	addi	s1,s1,746 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    800030b6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030b8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030ba:	00005a17          	auipc	s4,0x5
    800030be:	48ea0a13          	addi	s4,s4,1166 # 80008548 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030c2:	2b893783          	ld	a5,696(s2)
    800030c6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030c8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030cc:	85d2                	mv	a1,s4
    800030ce:	01048513          	addi	a0,s1,16
    800030d2:	00001097          	auipc	ra,0x1
    800030d6:	4b2080e7          	jalr	1202(ra) # 80004584 <initsleeplock>
    bcache.head.next->prev = b;
    800030da:	2b893783          	ld	a5,696(s2)
    800030de:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030e0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e4:	45848493          	addi	s1,s1,1112
    800030e8:	fd349de3          	bne	s1,s3,800030c2 <binit+0x54>
  }
}
    800030ec:	70a2                	ld	ra,40(sp)
    800030ee:	7402                	ld	s0,32(sp)
    800030f0:	64e2                	ld	s1,24(sp)
    800030f2:	6942                	ld	s2,16(sp)
    800030f4:	69a2                	ld	s3,8(sp)
    800030f6:	6a02                	ld	s4,0(sp)
    800030f8:	6145                	addi	sp,sp,48
    800030fa:	8082                	ret

00000000800030fc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030fc:	7179                	addi	sp,sp,-48
    800030fe:	f406                	sd	ra,40(sp)
    80003100:	f022                	sd	s0,32(sp)
    80003102:	ec26                	sd	s1,24(sp)
    80003104:	e84a                	sd	s2,16(sp)
    80003106:	e44e                	sd	s3,8(sp)
    80003108:	1800                	addi	s0,sp,48
    8000310a:	892a                	mv	s2,a0
    8000310c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000310e:	00015517          	auipc	a0,0x15
    80003112:	27250513          	addi	a0,a0,626 # 80018380 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	ae6080e7          	jalr	-1306(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000311e:	0001d497          	auipc	s1,0x1d
    80003122:	51a4b483          	ld	s1,1306(s1) # 80020638 <bcache+0x82b8>
    80003126:	0001d797          	auipc	a5,0x1d
    8000312a:	4c278793          	addi	a5,a5,1218 # 800205e8 <bcache+0x8268>
    8000312e:	02f48f63          	beq	s1,a5,8000316c <bread+0x70>
    80003132:	873e                	mv	a4,a5
    80003134:	a021                	j	8000313c <bread+0x40>
    80003136:	68a4                	ld	s1,80(s1)
    80003138:	02e48a63          	beq	s1,a4,8000316c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000313c:	449c                	lw	a5,8(s1)
    8000313e:	ff279ce3          	bne	a5,s2,80003136 <bread+0x3a>
    80003142:	44dc                	lw	a5,12(s1)
    80003144:	ff3799e3          	bne	a5,s3,80003136 <bread+0x3a>
      b->refcnt++;
    80003148:	40bc                	lw	a5,64(s1)
    8000314a:	2785                	addiw	a5,a5,1
    8000314c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314e:	00015517          	auipc	a0,0x15
    80003152:	23250513          	addi	a0,a0,562 # 80018380 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	b5a080e7          	jalr	-1190(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    8000315e:	01048513          	addi	a0,s1,16
    80003162:	00001097          	auipc	ra,0x1
    80003166:	45c080e7          	jalr	1116(ra) # 800045be <acquiresleep>
      return b;
    8000316a:	a8b9                	j	800031c8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000316c:	0001d497          	auipc	s1,0x1d
    80003170:	4c44b483          	ld	s1,1220(s1) # 80020630 <bcache+0x82b0>
    80003174:	0001d797          	auipc	a5,0x1d
    80003178:	47478793          	addi	a5,a5,1140 # 800205e8 <bcache+0x8268>
    8000317c:	00f48863          	beq	s1,a5,8000318c <bread+0x90>
    80003180:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003182:	40bc                	lw	a5,64(s1)
    80003184:	cf81                	beqz	a5,8000319c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003186:	64a4                	ld	s1,72(s1)
    80003188:	fee49de3          	bne	s1,a4,80003182 <bread+0x86>
  panic("bget: no buffers");
    8000318c:	00005517          	auipc	a0,0x5
    80003190:	3c450513          	addi	a0,a0,964 # 80008550 <syscalls+0xc0>
    80003194:	ffffd097          	auipc	ra,0xffffd
    80003198:	3ac080e7          	jalr	940(ra) # 80000540 <panic>
      b->dev = dev;
    8000319c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031a0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031a4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031a8:	4785                	li	a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ac:	00015517          	auipc	a0,0x15
    800031b0:	1d450513          	addi	a0,a0,468 # 80018380 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	afc080e7          	jalr	-1284(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031bc:	01048513          	addi	a0,s1,16
    800031c0:	00001097          	auipc	ra,0x1
    800031c4:	3fe080e7          	jalr	1022(ra) # 800045be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031c8:	409c                	lw	a5,0(s1)
    800031ca:	cb89                	beqz	a5,800031dc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031cc:	8526                	mv	a0,s1
    800031ce:	70a2                	ld	ra,40(sp)
    800031d0:	7402                	ld	s0,32(sp)
    800031d2:	64e2                	ld	s1,24(sp)
    800031d4:	6942                	ld	s2,16(sp)
    800031d6:	69a2                	ld	s3,8(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret
    virtio_disk_rw(b, 0);
    800031dc:	4581                	li	a1,0
    800031de:	8526                	mv	a0,s1
    800031e0:	00003097          	auipc	ra,0x3
    800031e4:	f2c080e7          	jalr	-212(ra) # 8000610c <virtio_disk_rw>
    b->valid = 1;
    800031e8:	4785                	li	a5,1
    800031ea:	c09c                	sw	a5,0(s1)
  return b;
    800031ec:	b7c5                	j	800031cc <bread+0xd0>

00000000800031ee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	e426                	sd	s1,8(sp)
    800031f6:	1000                	addi	s0,sp,32
    800031f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031fa:	0541                	addi	a0,a0,16
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	45c080e7          	jalr	1116(ra) # 80004658 <holdingsleep>
    80003204:	cd01                	beqz	a0,8000321c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003206:	4585                	li	a1,1
    80003208:	8526                	mv	a0,s1
    8000320a:	00003097          	auipc	ra,0x3
    8000320e:	f02080e7          	jalr	-254(ra) # 8000610c <virtio_disk_rw>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret
    panic("bwrite");
    8000321c:	00005517          	auipc	a0,0x5
    80003220:	34c50513          	addi	a0,a0,844 # 80008568 <syscalls+0xd8>
    80003224:	ffffd097          	auipc	ra,0xffffd
    80003228:	31c080e7          	jalr	796(ra) # 80000540 <panic>

000000008000322c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	e426                	sd	s1,8(sp)
    80003234:	e04a                	sd	s2,0(sp)
    80003236:	1000                	addi	s0,sp,32
    80003238:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000323a:	01050913          	addi	s2,a0,16
    8000323e:	854a                	mv	a0,s2
    80003240:	00001097          	auipc	ra,0x1
    80003244:	418080e7          	jalr	1048(ra) # 80004658 <holdingsleep>
    80003248:	c92d                	beqz	a0,800032ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000324a:	854a                	mv	a0,s2
    8000324c:	00001097          	auipc	ra,0x1
    80003250:	3c8080e7          	jalr	968(ra) # 80004614 <releasesleep>

  acquire(&bcache.lock);
    80003254:	00015517          	auipc	a0,0x15
    80003258:	12c50513          	addi	a0,a0,300 # 80018380 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	9a0080e7          	jalr	-1632(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003264:	40bc                	lw	a5,64(s1)
    80003266:	37fd                	addiw	a5,a5,-1
    80003268:	0007871b          	sext.w	a4,a5
    8000326c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000326e:	eb05                	bnez	a4,8000329e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003270:	68bc                	ld	a5,80(s1)
    80003272:	64b8                	ld	a4,72(s1)
    80003274:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003276:	64bc                	ld	a5,72(s1)
    80003278:	68b8                	ld	a4,80(s1)
    8000327a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000327c:	0001d797          	auipc	a5,0x1d
    80003280:	10478793          	addi	a5,a5,260 # 80020380 <bcache+0x8000>
    80003284:	2b87b703          	ld	a4,696(a5)
    80003288:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000328a:	0001d717          	auipc	a4,0x1d
    8000328e:	35e70713          	addi	a4,a4,862 # 800205e8 <bcache+0x8268>
    80003292:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003294:	2b87b703          	ld	a4,696(a5)
    80003298:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000329a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000329e:	00015517          	auipc	a0,0x15
    800032a2:	0e250513          	addi	a0,a0,226 # 80018380 <bcache>
    800032a6:	ffffe097          	auipc	ra,0xffffe
    800032aa:	a0a080e7          	jalr	-1526(ra) # 80000cb0 <release>
}
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	64a2                	ld	s1,8(sp)
    800032b4:	6902                	ld	s2,0(sp)
    800032b6:	6105                	addi	sp,sp,32
    800032b8:	8082                	ret
    panic("brelse");
    800032ba:	00005517          	auipc	a0,0x5
    800032be:	2b650513          	addi	a0,a0,694 # 80008570 <syscalls+0xe0>
    800032c2:	ffffd097          	auipc	ra,0xffffd
    800032c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>

00000000800032ca <bpin>:

void
bpin(struct buf *b) {
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	1000                	addi	s0,sp,32
    800032d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d6:	00015517          	auipc	a0,0x15
    800032da:	0aa50513          	addi	a0,a0,170 # 80018380 <bcache>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	91e080e7          	jalr	-1762(ra) # 80000bfc <acquire>
  b->refcnt++;
    800032e6:	40bc                	lw	a5,64(s1)
    800032e8:	2785                	addiw	a5,a5,1
    800032ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ec:	00015517          	auipc	a0,0x15
    800032f0:	09450513          	addi	a0,a0,148 # 80018380 <bcache>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	9bc080e7          	jalr	-1604(ra) # 80000cb0 <release>
}
    800032fc:	60e2                	ld	ra,24(sp)
    800032fe:	6442                	ld	s0,16(sp)
    80003300:	64a2                	ld	s1,8(sp)
    80003302:	6105                	addi	sp,sp,32
    80003304:	8082                	ret

0000000080003306 <bunpin>:

void
bunpin(struct buf *b) {
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	1000                	addi	s0,sp,32
    80003310:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003312:	00015517          	auipc	a0,0x15
    80003316:	06e50513          	addi	a0,a0,110 # 80018380 <bcache>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	8e2080e7          	jalr	-1822(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003322:	40bc                	lw	a5,64(s1)
    80003324:	37fd                	addiw	a5,a5,-1
    80003326:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003328:	00015517          	auipc	a0,0x15
    8000332c:	05850513          	addi	a0,a0,88 # 80018380 <bcache>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	980080e7          	jalr	-1664(ra) # 80000cb0 <release>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret

0000000080003342 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	e426                	sd	s1,8(sp)
    8000334a:	e04a                	sd	s2,0(sp)
    8000334c:	1000                	addi	s0,sp,32
    8000334e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003350:	00d5d59b          	srliw	a1,a1,0xd
    80003354:	0001d797          	auipc	a5,0x1d
    80003358:	7087a783          	lw	a5,1800(a5) # 80020a5c <sb+0x1c>
    8000335c:	9dbd                	addw	a1,a1,a5
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	d9e080e7          	jalr	-610(ra) # 800030fc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003366:	0074f713          	andi	a4,s1,7
    8000336a:	4785                	li	a5,1
    8000336c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003370:	14ce                	slli	s1,s1,0x33
    80003372:	90d9                	srli	s1,s1,0x36
    80003374:	00950733          	add	a4,a0,s1
    80003378:	05874703          	lbu	a4,88(a4)
    8000337c:	00e7f6b3          	and	a3,a5,a4
    80003380:	c69d                	beqz	a3,800033ae <bfree+0x6c>
    80003382:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003384:	94aa                	add	s1,s1,a0
    80003386:	fff7c793          	not	a5,a5
    8000338a:	8ff9                	and	a5,a5,a4
    8000338c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003390:	00001097          	auipc	ra,0x1
    80003394:	106080e7          	jalr	262(ra) # 80004496 <log_write>
  brelse(bp);
    80003398:	854a                	mv	a0,s2
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	e92080e7          	jalr	-366(ra) # 8000322c <brelse>
}
    800033a2:	60e2                	ld	ra,24(sp)
    800033a4:	6442                	ld	s0,16(sp)
    800033a6:	64a2                	ld	s1,8(sp)
    800033a8:	6902                	ld	s2,0(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret
    panic("freeing free block");
    800033ae:	00005517          	auipc	a0,0x5
    800033b2:	1ca50513          	addi	a0,a0,458 # 80008578 <syscalls+0xe8>
    800033b6:	ffffd097          	auipc	ra,0xffffd
    800033ba:	18a080e7          	jalr	394(ra) # 80000540 <panic>

00000000800033be <balloc>:
{
    800033be:	711d                	addi	sp,sp,-96
    800033c0:	ec86                	sd	ra,88(sp)
    800033c2:	e8a2                	sd	s0,80(sp)
    800033c4:	e4a6                	sd	s1,72(sp)
    800033c6:	e0ca                	sd	s2,64(sp)
    800033c8:	fc4e                	sd	s3,56(sp)
    800033ca:	f852                	sd	s4,48(sp)
    800033cc:	f456                	sd	s5,40(sp)
    800033ce:	f05a                	sd	s6,32(sp)
    800033d0:	ec5e                	sd	s7,24(sp)
    800033d2:	e862                	sd	s8,16(sp)
    800033d4:	e466                	sd	s9,8(sp)
    800033d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033d8:	0001d797          	auipc	a5,0x1d
    800033dc:	66c7a783          	lw	a5,1644(a5) # 80020a44 <sb+0x4>
    800033e0:	cbd1                	beqz	a5,80003474 <balloc+0xb6>
    800033e2:	8baa                	mv	s7,a0
    800033e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033e6:	0001db17          	auipc	s6,0x1d
    800033ea:	65ab0b13          	addi	s6,s6,1626 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033f4:	6c89                	lui	s9,0x2
    800033f6:	a831                	j	80003412 <balloc+0x54>
    brelse(bp);
    800033f8:	854a                	mv	a0,s2
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	e32080e7          	jalr	-462(ra) # 8000322c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003402:	015c87bb          	addw	a5,s9,s5
    80003406:	00078a9b          	sext.w	s5,a5
    8000340a:	004b2703          	lw	a4,4(s6)
    8000340e:	06eaf363          	bgeu	s5,a4,80003474 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003412:	41fad79b          	sraiw	a5,s5,0x1f
    80003416:	0137d79b          	srliw	a5,a5,0x13
    8000341a:	015787bb          	addw	a5,a5,s5
    8000341e:	40d7d79b          	sraiw	a5,a5,0xd
    80003422:	01cb2583          	lw	a1,28(s6)
    80003426:	9dbd                	addw	a1,a1,a5
    80003428:	855e                	mv	a0,s7
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	cd2080e7          	jalr	-814(ra) # 800030fc <bread>
    80003432:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003434:	004b2503          	lw	a0,4(s6)
    80003438:	000a849b          	sext.w	s1,s5
    8000343c:	8662                	mv	a2,s8
    8000343e:	faa4fde3          	bgeu	s1,a0,800033f8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003442:	41f6579b          	sraiw	a5,a2,0x1f
    80003446:	01d7d69b          	srliw	a3,a5,0x1d
    8000344a:	00c6873b          	addw	a4,a3,a2
    8000344e:	00777793          	andi	a5,a4,7
    80003452:	9f95                	subw	a5,a5,a3
    80003454:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003458:	4037571b          	sraiw	a4,a4,0x3
    8000345c:	00e906b3          	add	a3,s2,a4
    80003460:	0586c683          	lbu	a3,88(a3)
    80003464:	00d7f5b3          	and	a1,a5,a3
    80003468:	cd91                	beqz	a1,80003484 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346a:	2605                	addiw	a2,a2,1
    8000346c:	2485                	addiw	s1,s1,1
    8000346e:	fd4618e3          	bne	a2,s4,8000343e <balloc+0x80>
    80003472:	b759                	j	800033f8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	11c50513          	addi	a0,a0,284 # 80008590 <syscalls+0x100>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0c4080e7          	jalr	196(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003484:	974a                	add	a4,a4,s2
    80003486:	8fd5                	or	a5,a5,a3
    80003488:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000348c:	854a                	mv	a0,s2
    8000348e:	00001097          	auipc	ra,0x1
    80003492:	008080e7          	jalr	8(ra) # 80004496 <log_write>
        brelse(bp);
    80003496:	854a                	mv	a0,s2
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	d94080e7          	jalr	-620(ra) # 8000322c <brelse>
  bp = bread(dev, bno);
    800034a0:	85a6                	mv	a1,s1
    800034a2:	855e                	mv	a0,s7
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	c58080e7          	jalr	-936(ra) # 800030fc <bread>
    800034ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034ae:	40000613          	li	a2,1024
    800034b2:	4581                	li	a1,0
    800034b4:	05850513          	addi	a0,a0,88
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	840080e7          	jalr	-1984(ra) # 80000cf8 <memset>
  log_write(bp);
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	fd4080e7          	jalr	-44(ra) # 80004496 <log_write>
  brelse(bp);
    800034ca:	854a                	mv	a0,s2
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	d60080e7          	jalr	-672(ra) # 8000322c <brelse>
}
    800034d4:	8526                	mv	a0,s1
    800034d6:	60e6                	ld	ra,88(sp)
    800034d8:	6446                	ld	s0,80(sp)
    800034da:	64a6                	ld	s1,72(sp)
    800034dc:	6906                	ld	s2,64(sp)
    800034de:	79e2                	ld	s3,56(sp)
    800034e0:	7a42                	ld	s4,48(sp)
    800034e2:	7aa2                	ld	s5,40(sp)
    800034e4:	7b02                	ld	s6,32(sp)
    800034e6:	6be2                	ld	s7,24(sp)
    800034e8:	6c42                	ld	s8,16(sp)
    800034ea:	6ca2                	ld	s9,8(sp)
    800034ec:	6125                	addi	sp,sp,96
    800034ee:	8082                	ret

00000000800034f0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034f0:	7179                	addi	sp,sp,-48
    800034f2:	f406                	sd	ra,40(sp)
    800034f4:	f022                	sd	s0,32(sp)
    800034f6:	ec26                	sd	s1,24(sp)
    800034f8:	e84a                	sd	s2,16(sp)
    800034fa:	e44e                	sd	s3,8(sp)
    800034fc:	e052                	sd	s4,0(sp)
    800034fe:	1800                	addi	s0,sp,48
    80003500:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003502:	47ad                	li	a5,11
    80003504:	04b7fe63          	bgeu	a5,a1,80003560 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003508:	ff45849b          	addiw	s1,a1,-12
    8000350c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003510:	0ff00793          	li	a5,255
    80003514:	0ae7e463          	bltu	a5,a4,800035bc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003518:	08052583          	lw	a1,128(a0)
    8000351c:	c5b5                	beqz	a1,80003588 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000351e:	00092503          	lw	a0,0(s2)
    80003522:	00000097          	auipc	ra,0x0
    80003526:	bda080e7          	jalr	-1062(ra) # 800030fc <bread>
    8000352a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000352c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003530:	02049713          	slli	a4,s1,0x20
    80003534:	01e75593          	srli	a1,a4,0x1e
    80003538:	00b784b3          	add	s1,a5,a1
    8000353c:	0004a983          	lw	s3,0(s1)
    80003540:	04098e63          	beqz	s3,8000359c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003544:	8552                	mv	a0,s4
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	ce6080e7          	jalr	-794(ra) # 8000322c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000354e:	854e                	mv	a0,s3
    80003550:	70a2                	ld	ra,40(sp)
    80003552:	7402                	ld	s0,32(sp)
    80003554:	64e2                	ld	s1,24(sp)
    80003556:	6942                	ld	s2,16(sp)
    80003558:	69a2                	ld	s3,8(sp)
    8000355a:	6a02                	ld	s4,0(sp)
    8000355c:	6145                	addi	sp,sp,48
    8000355e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003560:	02059793          	slli	a5,a1,0x20
    80003564:	01e7d593          	srli	a1,a5,0x1e
    80003568:	00b504b3          	add	s1,a0,a1
    8000356c:	0504a983          	lw	s3,80(s1)
    80003570:	fc099fe3          	bnez	s3,8000354e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003574:	4108                	lw	a0,0(a0)
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	e48080e7          	jalr	-440(ra) # 800033be <balloc>
    8000357e:	0005099b          	sext.w	s3,a0
    80003582:	0534a823          	sw	s3,80(s1)
    80003586:	b7e1                	j	8000354e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003588:	4108                	lw	a0,0(a0)
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	e34080e7          	jalr	-460(ra) # 800033be <balloc>
    80003592:	0005059b          	sext.w	a1,a0
    80003596:	08b92023          	sw	a1,128(s2)
    8000359a:	b751                	j	8000351e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000359c:	00092503          	lw	a0,0(s2)
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	e1e080e7          	jalr	-482(ra) # 800033be <balloc>
    800035a8:	0005099b          	sext.w	s3,a0
    800035ac:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035b0:	8552                	mv	a0,s4
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	ee4080e7          	jalr	-284(ra) # 80004496 <log_write>
    800035ba:	b769                	j	80003544 <bmap+0x54>
  panic("bmap: out of range");
    800035bc:	00005517          	auipc	a0,0x5
    800035c0:	fec50513          	addi	a0,a0,-20 # 800085a8 <syscalls+0x118>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	f7c080e7          	jalr	-132(ra) # 80000540 <panic>

00000000800035cc <iget>:
{
    800035cc:	7179                	addi	sp,sp,-48
    800035ce:	f406                	sd	ra,40(sp)
    800035d0:	f022                	sd	s0,32(sp)
    800035d2:	ec26                	sd	s1,24(sp)
    800035d4:	e84a                	sd	s2,16(sp)
    800035d6:	e44e                	sd	s3,8(sp)
    800035d8:	e052                	sd	s4,0(sp)
    800035da:	1800                	addi	s0,sp,48
    800035dc:	89aa                	mv	s3,a0
    800035de:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035e0:	0001d517          	auipc	a0,0x1d
    800035e4:	48050513          	addi	a0,a0,1152 # 80020a60 <icache>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	614080e7          	jalr	1556(ra) # 80000bfc <acquire>
  empty = 0;
    800035f0:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035f2:	0001d497          	auipc	s1,0x1d
    800035f6:	48648493          	addi	s1,s1,1158 # 80020a78 <icache+0x18>
    800035fa:	0001f697          	auipc	a3,0x1f
    800035fe:	f0e68693          	addi	a3,a3,-242 # 80022508 <log>
    80003602:	a039                	j	80003610 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003604:	02090b63          	beqz	s2,8000363a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003608:	08848493          	addi	s1,s1,136
    8000360c:	02d48a63          	beq	s1,a3,80003640 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003610:	449c                	lw	a5,8(s1)
    80003612:	fef059e3          	blez	a5,80003604 <iget+0x38>
    80003616:	4098                	lw	a4,0(s1)
    80003618:	ff3716e3          	bne	a4,s3,80003604 <iget+0x38>
    8000361c:	40d8                	lw	a4,4(s1)
    8000361e:	ff4713e3          	bne	a4,s4,80003604 <iget+0x38>
      ip->ref++;
    80003622:	2785                	addiw	a5,a5,1
    80003624:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003626:	0001d517          	auipc	a0,0x1d
    8000362a:	43a50513          	addi	a0,a0,1082 # 80020a60 <icache>
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	682080e7          	jalr	1666(ra) # 80000cb0 <release>
      return ip;
    80003636:	8926                	mv	s2,s1
    80003638:	a03d                	j	80003666 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363a:	f7f9                	bnez	a5,80003608 <iget+0x3c>
    8000363c:	8926                	mv	s2,s1
    8000363e:	b7e9                	j	80003608 <iget+0x3c>
  if(empty == 0)
    80003640:	02090c63          	beqz	s2,80003678 <iget+0xac>
  ip->dev = dev;
    80003644:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003648:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000364c:	4785                	li	a5,1
    8000364e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003652:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003656:	0001d517          	auipc	a0,0x1d
    8000365a:	40a50513          	addi	a0,a0,1034 # 80020a60 <icache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	652080e7          	jalr	1618(ra) # 80000cb0 <release>
}
    80003666:	854a                	mv	a0,s2
    80003668:	70a2                	ld	ra,40(sp)
    8000366a:	7402                	ld	s0,32(sp)
    8000366c:	64e2                	ld	s1,24(sp)
    8000366e:	6942                	ld	s2,16(sp)
    80003670:	69a2                	ld	s3,8(sp)
    80003672:	6a02                	ld	s4,0(sp)
    80003674:	6145                	addi	sp,sp,48
    80003676:	8082                	ret
    panic("iget: no inodes");
    80003678:	00005517          	auipc	a0,0x5
    8000367c:	f4850513          	addi	a0,a0,-184 # 800085c0 <syscalls+0x130>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	ec0080e7          	jalr	-320(ra) # 80000540 <panic>

0000000080003688 <fsinit>:
fsinit(int dev) {
    80003688:	7179                	addi	sp,sp,-48
    8000368a:	f406                	sd	ra,40(sp)
    8000368c:	f022                	sd	s0,32(sp)
    8000368e:	ec26                	sd	s1,24(sp)
    80003690:	e84a                	sd	s2,16(sp)
    80003692:	e44e                	sd	s3,8(sp)
    80003694:	1800                	addi	s0,sp,48
    80003696:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003698:	4585                	li	a1,1
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	a62080e7          	jalr	-1438(ra) # 800030fc <bread>
    800036a2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036a4:	0001d997          	auipc	s3,0x1d
    800036a8:	39c98993          	addi	s3,s3,924 # 80020a40 <sb>
    800036ac:	02000613          	li	a2,32
    800036b0:	05850593          	addi	a1,a0,88
    800036b4:	854e                	mv	a0,s3
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	69e080e7          	jalr	1694(ra) # 80000d54 <memmove>
  brelse(bp);
    800036be:	8526                	mv	a0,s1
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	b6c080e7          	jalr	-1172(ra) # 8000322c <brelse>
  if(sb.magic != FSMAGIC)
    800036c8:	0009a703          	lw	a4,0(s3)
    800036cc:	102037b7          	lui	a5,0x10203
    800036d0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036d4:	02f71263          	bne	a4,a5,800036f8 <fsinit+0x70>
  initlog(dev, &sb);
    800036d8:	0001d597          	auipc	a1,0x1d
    800036dc:	36858593          	addi	a1,a1,872 # 80020a40 <sb>
    800036e0:	854a                	mv	a0,s2
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	b3a080e7          	jalr	-1222(ra) # 8000421c <initlog>
}
    800036ea:	70a2                	ld	ra,40(sp)
    800036ec:	7402                	ld	s0,32(sp)
    800036ee:	64e2                	ld	s1,24(sp)
    800036f0:	6942                	ld	s2,16(sp)
    800036f2:	69a2                	ld	s3,8(sp)
    800036f4:	6145                	addi	sp,sp,48
    800036f6:	8082                	ret
    panic("invalid file system");
    800036f8:	00005517          	auipc	a0,0x5
    800036fc:	ed850513          	addi	a0,a0,-296 # 800085d0 <syscalls+0x140>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	e40080e7          	jalr	-448(ra) # 80000540 <panic>

0000000080003708 <iinit>:
{
    80003708:	7179                	addi	sp,sp,-48
    8000370a:	f406                	sd	ra,40(sp)
    8000370c:	f022                	sd	s0,32(sp)
    8000370e:	ec26                	sd	s1,24(sp)
    80003710:	e84a                	sd	s2,16(sp)
    80003712:	e44e                	sd	s3,8(sp)
    80003714:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003716:	00005597          	auipc	a1,0x5
    8000371a:	ed258593          	addi	a1,a1,-302 # 800085e8 <syscalls+0x158>
    8000371e:	0001d517          	auipc	a0,0x1d
    80003722:	34250513          	addi	a0,a0,834 # 80020a60 <icache>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	446080e7          	jalr	1094(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000372e:	0001d497          	auipc	s1,0x1d
    80003732:	35a48493          	addi	s1,s1,858 # 80020a88 <icache+0x28>
    80003736:	0001f997          	auipc	s3,0x1f
    8000373a:	de298993          	addi	s3,s3,-542 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000373e:	00005917          	auipc	s2,0x5
    80003742:	eb290913          	addi	s2,s2,-334 # 800085f0 <syscalls+0x160>
    80003746:	85ca                	mv	a1,s2
    80003748:	8526                	mv	a0,s1
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	e3a080e7          	jalr	-454(ra) # 80004584 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003752:	08848493          	addi	s1,s1,136
    80003756:	ff3498e3          	bne	s1,s3,80003746 <iinit+0x3e>
}
    8000375a:	70a2                	ld	ra,40(sp)
    8000375c:	7402                	ld	s0,32(sp)
    8000375e:	64e2                	ld	s1,24(sp)
    80003760:	6942                	ld	s2,16(sp)
    80003762:	69a2                	ld	s3,8(sp)
    80003764:	6145                	addi	sp,sp,48
    80003766:	8082                	ret

0000000080003768 <ialloc>:
{
    80003768:	715d                	addi	sp,sp,-80
    8000376a:	e486                	sd	ra,72(sp)
    8000376c:	e0a2                	sd	s0,64(sp)
    8000376e:	fc26                	sd	s1,56(sp)
    80003770:	f84a                	sd	s2,48(sp)
    80003772:	f44e                	sd	s3,40(sp)
    80003774:	f052                	sd	s4,32(sp)
    80003776:	ec56                	sd	s5,24(sp)
    80003778:	e85a                	sd	s6,16(sp)
    8000377a:	e45e                	sd	s7,8(sp)
    8000377c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000377e:	0001d717          	auipc	a4,0x1d
    80003782:	2ce72703          	lw	a4,718(a4) # 80020a4c <sb+0xc>
    80003786:	4785                	li	a5,1
    80003788:	04e7fa63          	bgeu	a5,a4,800037dc <ialloc+0x74>
    8000378c:	8aaa                	mv	s5,a0
    8000378e:	8bae                	mv	s7,a1
    80003790:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003792:	0001da17          	auipc	s4,0x1d
    80003796:	2aea0a13          	addi	s4,s4,686 # 80020a40 <sb>
    8000379a:	00048b1b          	sext.w	s6,s1
    8000379e:	0044d793          	srli	a5,s1,0x4
    800037a2:	018a2583          	lw	a1,24(s4)
    800037a6:	9dbd                	addw	a1,a1,a5
    800037a8:	8556                	mv	a0,s5
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	952080e7          	jalr	-1710(ra) # 800030fc <bread>
    800037b2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037b4:	05850993          	addi	s3,a0,88
    800037b8:	00f4f793          	andi	a5,s1,15
    800037bc:	079a                	slli	a5,a5,0x6
    800037be:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037c0:	00099783          	lh	a5,0(s3)
    800037c4:	c785                	beqz	a5,800037ec <ialloc+0x84>
    brelse(bp);
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	a66080e7          	jalr	-1434(ra) # 8000322c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ce:	0485                	addi	s1,s1,1
    800037d0:	00ca2703          	lw	a4,12(s4)
    800037d4:	0004879b          	sext.w	a5,s1
    800037d8:	fce7e1e3          	bltu	a5,a4,8000379a <ialloc+0x32>
  panic("ialloc: no inodes");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	e1c50513          	addi	a0,a0,-484 # 800085f8 <syscalls+0x168>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5c080e7          	jalr	-676(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    800037ec:	04000613          	li	a2,64
    800037f0:	4581                	li	a1,0
    800037f2:	854e                	mv	a0,s3
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	504080e7          	jalr	1284(ra) # 80000cf8 <memset>
      dip->type = type;
    800037fc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003800:	854a                	mv	a0,s2
    80003802:	00001097          	auipc	ra,0x1
    80003806:	c94080e7          	jalr	-876(ra) # 80004496 <log_write>
      brelse(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	a20080e7          	jalr	-1504(ra) # 8000322c <brelse>
      return iget(dev, inum);
    80003814:	85da                	mv	a1,s6
    80003816:	8556                	mv	a0,s5
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	db4080e7          	jalr	-588(ra) # 800035cc <iget>
}
    80003820:	60a6                	ld	ra,72(sp)
    80003822:	6406                	ld	s0,64(sp)
    80003824:	74e2                	ld	s1,56(sp)
    80003826:	7942                	ld	s2,48(sp)
    80003828:	79a2                	ld	s3,40(sp)
    8000382a:	7a02                	ld	s4,32(sp)
    8000382c:	6ae2                	ld	s5,24(sp)
    8000382e:	6b42                	ld	s6,16(sp)
    80003830:	6ba2                	ld	s7,8(sp)
    80003832:	6161                	addi	sp,sp,80
    80003834:	8082                	ret

0000000080003836 <iupdate>:
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	e04a                	sd	s2,0(sp)
    80003840:	1000                	addi	s0,sp,32
    80003842:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003844:	415c                	lw	a5,4(a0)
    80003846:	0047d79b          	srliw	a5,a5,0x4
    8000384a:	0001d597          	auipc	a1,0x1d
    8000384e:	20e5a583          	lw	a1,526(a1) # 80020a58 <sb+0x18>
    80003852:	9dbd                	addw	a1,a1,a5
    80003854:	4108                	lw	a0,0(a0)
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	8a6080e7          	jalr	-1882(ra) # 800030fc <bread>
    8000385e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003860:	05850793          	addi	a5,a0,88
    80003864:	40c8                	lw	a0,4(s1)
    80003866:	893d                	andi	a0,a0,15
    80003868:	051a                	slli	a0,a0,0x6
    8000386a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000386c:	04449703          	lh	a4,68(s1)
    80003870:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003874:	04649703          	lh	a4,70(s1)
    80003878:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000387c:	04849703          	lh	a4,72(s1)
    80003880:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003884:	04a49703          	lh	a4,74(s1)
    80003888:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000388c:	44f8                	lw	a4,76(s1)
    8000388e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003890:	03400613          	li	a2,52
    80003894:	05048593          	addi	a1,s1,80
    80003898:	0531                	addi	a0,a0,12
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	4ba080e7          	jalr	1210(ra) # 80000d54 <memmove>
  log_write(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	bf2080e7          	jalr	-1038(ra) # 80004496 <log_write>
  brelse(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	97e080e7          	jalr	-1666(ra) # 8000322c <brelse>
}
    800038b6:	60e2                	ld	ra,24(sp)
    800038b8:	6442                	ld	s0,16(sp)
    800038ba:	64a2                	ld	s1,8(sp)
    800038bc:	6902                	ld	s2,0(sp)
    800038be:	6105                	addi	sp,sp,32
    800038c0:	8082                	ret

00000000800038c2 <idup>:
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	1000                	addi	s0,sp,32
    800038cc:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038ce:	0001d517          	auipc	a0,0x1d
    800038d2:	19250513          	addi	a0,a0,402 # 80020a60 <icache>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	326080e7          	jalr	806(ra) # 80000bfc <acquire>
  ip->ref++;
    800038de:	449c                	lw	a5,8(s1)
    800038e0:	2785                	addiw	a5,a5,1
    800038e2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038e4:	0001d517          	auipc	a0,0x1d
    800038e8:	17c50513          	addi	a0,a0,380 # 80020a60 <icache>
    800038ec:	ffffd097          	auipc	ra,0xffffd
    800038f0:	3c4080e7          	jalr	964(ra) # 80000cb0 <release>
}
    800038f4:	8526                	mv	a0,s1
    800038f6:	60e2                	ld	ra,24(sp)
    800038f8:	6442                	ld	s0,16(sp)
    800038fa:	64a2                	ld	s1,8(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret

0000000080003900 <ilock>:
{
    80003900:	1101                	addi	sp,sp,-32
    80003902:	ec06                	sd	ra,24(sp)
    80003904:	e822                	sd	s0,16(sp)
    80003906:	e426                	sd	s1,8(sp)
    80003908:	e04a                	sd	s2,0(sp)
    8000390a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000390c:	c115                	beqz	a0,80003930 <ilock+0x30>
    8000390e:	84aa                	mv	s1,a0
    80003910:	451c                	lw	a5,8(a0)
    80003912:	00f05f63          	blez	a5,80003930 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003916:	0541                	addi	a0,a0,16
    80003918:	00001097          	auipc	ra,0x1
    8000391c:	ca6080e7          	jalr	-858(ra) # 800045be <acquiresleep>
  if(ip->valid == 0){
    80003920:	40bc                	lw	a5,64(s1)
    80003922:	cf99                	beqz	a5,80003940 <ilock+0x40>
}
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6902                	ld	s2,0(sp)
    8000392c:	6105                	addi	sp,sp,32
    8000392e:	8082                	ret
    panic("ilock");
    80003930:	00005517          	auipc	a0,0x5
    80003934:	ce050513          	addi	a0,a0,-800 # 80008610 <syscalls+0x180>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	c08080e7          	jalr	-1016(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003940:	40dc                	lw	a5,4(s1)
    80003942:	0047d79b          	srliw	a5,a5,0x4
    80003946:	0001d597          	auipc	a1,0x1d
    8000394a:	1125a583          	lw	a1,274(a1) # 80020a58 <sb+0x18>
    8000394e:	9dbd                	addw	a1,a1,a5
    80003950:	4088                	lw	a0,0(s1)
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	7aa080e7          	jalr	1962(ra) # 800030fc <bread>
    8000395a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395c:	05850593          	addi	a1,a0,88
    80003960:	40dc                	lw	a5,4(s1)
    80003962:	8bbd                	andi	a5,a5,15
    80003964:	079a                	slli	a5,a5,0x6
    80003966:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003968:	00059783          	lh	a5,0(a1)
    8000396c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003970:	00259783          	lh	a5,2(a1)
    80003974:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003978:	00459783          	lh	a5,4(a1)
    8000397c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003980:	00659783          	lh	a5,6(a1)
    80003984:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003988:	459c                	lw	a5,8(a1)
    8000398a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000398c:	03400613          	li	a2,52
    80003990:	05b1                	addi	a1,a1,12
    80003992:	05048513          	addi	a0,s1,80
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	3be080e7          	jalr	958(ra) # 80000d54 <memmove>
    brelse(bp);
    8000399e:	854a                	mv	a0,s2
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	88c080e7          	jalr	-1908(ra) # 8000322c <brelse>
    ip->valid = 1;
    800039a8:	4785                	li	a5,1
    800039aa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ac:	04449783          	lh	a5,68(s1)
    800039b0:	fbb5                	bnez	a5,80003924 <ilock+0x24>
      panic("ilock: no type");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	c6650513          	addi	a0,a0,-922 # 80008618 <syscalls+0x188>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b86080e7          	jalr	-1146(ra) # 80000540 <panic>

00000000800039c2 <iunlock>:
{
    800039c2:	1101                	addi	sp,sp,-32
    800039c4:	ec06                	sd	ra,24(sp)
    800039c6:	e822                	sd	s0,16(sp)
    800039c8:	e426                	sd	s1,8(sp)
    800039ca:	e04a                	sd	s2,0(sp)
    800039cc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039ce:	c905                	beqz	a0,800039fe <iunlock+0x3c>
    800039d0:	84aa                	mv	s1,a0
    800039d2:	01050913          	addi	s2,a0,16
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	c80080e7          	jalr	-896(ra) # 80004658 <holdingsleep>
    800039e0:	cd19                	beqz	a0,800039fe <iunlock+0x3c>
    800039e2:	449c                	lw	a5,8(s1)
    800039e4:	00f05d63          	blez	a5,800039fe <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039e8:	854a                	mv	a0,s2
    800039ea:	00001097          	auipc	ra,0x1
    800039ee:	c2a080e7          	jalr	-982(ra) # 80004614 <releasesleep>
}
    800039f2:	60e2                	ld	ra,24(sp)
    800039f4:	6442                	ld	s0,16(sp)
    800039f6:	64a2                	ld	s1,8(sp)
    800039f8:	6902                	ld	s2,0(sp)
    800039fa:	6105                	addi	sp,sp,32
    800039fc:	8082                	ret
    panic("iunlock");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	c2a50513          	addi	a0,a0,-982 # 80008628 <syscalls+0x198>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b3a080e7          	jalr	-1222(ra) # 80000540 <panic>

0000000080003a0e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a0e:	7179                	addi	sp,sp,-48
    80003a10:	f406                	sd	ra,40(sp)
    80003a12:	f022                	sd	s0,32(sp)
    80003a14:	ec26                	sd	s1,24(sp)
    80003a16:	e84a                	sd	s2,16(sp)
    80003a18:	e44e                	sd	s3,8(sp)
    80003a1a:	e052                	sd	s4,0(sp)
    80003a1c:	1800                	addi	s0,sp,48
    80003a1e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a20:	05050493          	addi	s1,a0,80
    80003a24:	08050913          	addi	s2,a0,128
    80003a28:	a021                	j	80003a30 <itrunc+0x22>
    80003a2a:	0491                	addi	s1,s1,4
    80003a2c:	01248d63          	beq	s1,s2,80003a46 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a30:	408c                	lw	a1,0(s1)
    80003a32:	dde5                	beqz	a1,80003a2a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a34:	0009a503          	lw	a0,0(s3)
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	90a080e7          	jalr	-1782(ra) # 80003342 <bfree>
      ip->addrs[i] = 0;
    80003a40:	0004a023          	sw	zero,0(s1)
    80003a44:	b7dd                	j	80003a2a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a46:	0809a583          	lw	a1,128(s3)
    80003a4a:	e185                	bnez	a1,80003a6a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a4c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a50:	854e                	mv	a0,s3
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	de4080e7          	jalr	-540(ra) # 80003836 <iupdate>
}
    80003a5a:	70a2                	ld	ra,40(sp)
    80003a5c:	7402                	ld	s0,32(sp)
    80003a5e:	64e2                	ld	s1,24(sp)
    80003a60:	6942                	ld	s2,16(sp)
    80003a62:	69a2                	ld	s3,8(sp)
    80003a64:	6a02                	ld	s4,0(sp)
    80003a66:	6145                	addi	sp,sp,48
    80003a68:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a6a:	0009a503          	lw	a0,0(s3)
    80003a6e:	fffff097          	auipc	ra,0xfffff
    80003a72:	68e080e7          	jalr	1678(ra) # 800030fc <bread>
    80003a76:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a78:	05850493          	addi	s1,a0,88
    80003a7c:	45850913          	addi	s2,a0,1112
    80003a80:	a021                	j	80003a88 <itrunc+0x7a>
    80003a82:	0491                	addi	s1,s1,4
    80003a84:	01248b63          	beq	s1,s2,80003a9a <itrunc+0x8c>
      if(a[j])
    80003a88:	408c                	lw	a1,0(s1)
    80003a8a:	dde5                	beqz	a1,80003a82 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a8c:	0009a503          	lw	a0,0(s3)
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	8b2080e7          	jalr	-1870(ra) # 80003342 <bfree>
    80003a98:	b7ed                	j	80003a82 <itrunc+0x74>
    brelse(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	790080e7          	jalr	1936(ra) # 8000322c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa4:	0809a583          	lw	a1,128(s3)
    80003aa8:	0009a503          	lw	a0,0(s3)
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	896080e7          	jalr	-1898(ra) # 80003342 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab4:	0809a023          	sw	zero,128(s3)
    80003ab8:	bf51                	j	80003a4c <itrunc+0x3e>

0000000080003aba <iput>:
{
    80003aba:	1101                	addi	sp,sp,-32
    80003abc:	ec06                	sd	ra,24(sp)
    80003abe:	e822                	sd	s0,16(sp)
    80003ac0:	e426                	sd	s1,8(sp)
    80003ac2:	e04a                	sd	s2,0(sp)
    80003ac4:	1000                	addi	s0,sp,32
    80003ac6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ac8:	0001d517          	auipc	a0,0x1d
    80003acc:	f9850513          	addi	a0,a0,-104 # 80020a60 <icache>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	12c080e7          	jalr	300(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad8:	4498                	lw	a4,8(s1)
    80003ada:	4785                	li	a5,1
    80003adc:	02f70363          	beq	a4,a5,80003b02 <iput+0x48>
  ip->ref--;
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	37fd                	addiw	a5,a5,-1
    80003ae4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ae6:	0001d517          	auipc	a0,0x1d
    80003aea:	f7a50513          	addi	a0,a0,-134 # 80020a60 <icache>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	1c2080e7          	jalr	450(ra) # 80000cb0 <release>
}
    80003af6:	60e2                	ld	ra,24(sp)
    80003af8:	6442                	ld	s0,16(sp)
    80003afa:	64a2                	ld	s1,8(sp)
    80003afc:	6902                	ld	s2,0(sp)
    80003afe:	6105                	addi	sp,sp,32
    80003b00:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b02:	40bc                	lw	a5,64(s1)
    80003b04:	dff1                	beqz	a5,80003ae0 <iput+0x26>
    80003b06:	04a49783          	lh	a5,74(s1)
    80003b0a:	fbf9                	bnez	a5,80003ae0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b0c:	01048913          	addi	s2,s1,16
    80003b10:	854a                	mv	a0,s2
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	aac080e7          	jalr	-1364(ra) # 800045be <acquiresleep>
    release(&icache.lock);
    80003b1a:	0001d517          	auipc	a0,0x1d
    80003b1e:	f4650513          	addi	a0,a0,-186 # 80020a60 <icache>
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	18e080e7          	jalr	398(ra) # 80000cb0 <release>
    itrunc(ip);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	ee2080e7          	jalr	-286(ra) # 80003a0e <itrunc>
    ip->type = 0;
    80003b34:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b38:	8526                	mv	a0,s1
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	cfc080e7          	jalr	-772(ra) # 80003836 <iupdate>
    ip->valid = 0;
    80003b42:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b46:	854a                	mv	a0,s2
    80003b48:	00001097          	auipc	ra,0x1
    80003b4c:	acc080e7          	jalr	-1332(ra) # 80004614 <releasesleep>
    acquire(&icache.lock);
    80003b50:	0001d517          	auipc	a0,0x1d
    80003b54:	f1050513          	addi	a0,a0,-240 # 80020a60 <icache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	0a4080e7          	jalr	164(ra) # 80000bfc <acquire>
    80003b60:	b741                	j	80003ae0 <iput+0x26>

0000000080003b62 <iunlockput>:
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	e426                	sd	s1,8(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	e54080e7          	jalr	-428(ra) # 800039c2 <iunlock>
  iput(ip);
    80003b76:	8526                	mv	a0,s1
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	f42080e7          	jalr	-190(ra) # 80003aba <iput>
}
    80003b80:	60e2                	ld	ra,24(sp)
    80003b82:	6442                	ld	s0,16(sp)
    80003b84:	64a2                	ld	s1,8(sp)
    80003b86:	6105                	addi	sp,sp,32
    80003b88:	8082                	ret

0000000080003b8a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b8a:	1141                	addi	sp,sp,-16
    80003b8c:	e422                	sd	s0,8(sp)
    80003b8e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b90:	411c                	lw	a5,0(a0)
    80003b92:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b94:	415c                	lw	a5,4(a0)
    80003b96:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b98:	04451783          	lh	a5,68(a0)
    80003b9c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ba0:	04a51783          	lh	a5,74(a0)
    80003ba4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ba8:	04c56783          	lwu	a5,76(a0)
    80003bac:	e99c                	sd	a5,16(a1)
}
    80003bae:	6422                	ld	s0,8(sp)
    80003bb0:	0141                	addi	sp,sp,16
    80003bb2:	8082                	ret

0000000080003bb4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb4:	457c                	lw	a5,76(a0)
    80003bb6:	0ed7e863          	bltu	a5,a3,80003ca6 <readi+0xf2>
{
    80003bba:	7159                	addi	sp,sp,-112
    80003bbc:	f486                	sd	ra,104(sp)
    80003bbe:	f0a2                	sd	s0,96(sp)
    80003bc0:	eca6                	sd	s1,88(sp)
    80003bc2:	e8ca                	sd	s2,80(sp)
    80003bc4:	e4ce                	sd	s3,72(sp)
    80003bc6:	e0d2                	sd	s4,64(sp)
    80003bc8:	fc56                	sd	s5,56(sp)
    80003bca:	f85a                	sd	s6,48(sp)
    80003bcc:	f45e                	sd	s7,40(sp)
    80003bce:	f062                	sd	s8,32(sp)
    80003bd0:	ec66                	sd	s9,24(sp)
    80003bd2:	e86a                	sd	s10,16(sp)
    80003bd4:	e46e                	sd	s11,8(sp)
    80003bd6:	1880                	addi	s0,sp,112
    80003bd8:	8baa                	mv	s7,a0
    80003bda:	8c2e                	mv	s8,a1
    80003bdc:	8ab2                	mv	s5,a2
    80003bde:	84b6                	mv	s1,a3
    80003be0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003be2:	9f35                	addw	a4,a4,a3
    return 0;
    80003be4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003be6:	08d76f63          	bltu	a4,a3,80003c84 <readi+0xd0>
  if(off + n > ip->size)
    80003bea:	00e7f463          	bgeu	a5,a4,80003bf2 <readi+0x3e>
    n = ip->size - off;
    80003bee:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf2:	0a0b0863          	beqz	s6,80003ca2 <readi+0xee>
    80003bf6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bfc:	5cfd                	li	s9,-1
    80003bfe:	a82d                	j	80003c38 <readi+0x84>
    80003c00:	020a1d93          	slli	s11,s4,0x20
    80003c04:	020ddd93          	srli	s11,s11,0x20
    80003c08:	05890793          	addi	a5,s2,88
    80003c0c:	86ee                	mv	a3,s11
    80003c0e:	963e                	add	a2,a2,a5
    80003c10:	85d6                	mv	a1,s5
    80003c12:	8562                	mv	a0,s8
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	b0e080e7          	jalr	-1266(ra) # 80002722 <either_copyout>
    80003c1c:	05950d63          	beq	a0,s9,80003c76 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c20:	854a                	mv	a0,s2
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	60a080e7          	jalr	1546(ra) # 8000322c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2a:	013a09bb          	addw	s3,s4,s3
    80003c2e:	009a04bb          	addw	s1,s4,s1
    80003c32:	9aee                	add	s5,s5,s11
    80003c34:	0569f663          	bgeu	s3,s6,80003c80 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c38:	000ba903          	lw	s2,0(s7)
    80003c3c:	00a4d59b          	srliw	a1,s1,0xa
    80003c40:	855e                	mv	a0,s7
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	8ae080e7          	jalr	-1874(ra) # 800034f0 <bmap>
    80003c4a:	0005059b          	sext.w	a1,a0
    80003c4e:	854a                	mv	a0,s2
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	4ac080e7          	jalr	1196(ra) # 800030fc <bread>
    80003c58:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5a:	3ff4f613          	andi	a2,s1,1023
    80003c5e:	40cd07bb          	subw	a5,s10,a2
    80003c62:	413b073b          	subw	a4,s6,s3
    80003c66:	8a3e                	mv	s4,a5
    80003c68:	2781                	sext.w	a5,a5
    80003c6a:	0007069b          	sext.w	a3,a4
    80003c6e:	f8f6f9e3          	bgeu	a3,a5,80003c00 <readi+0x4c>
    80003c72:	8a3a                	mv	s4,a4
    80003c74:	b771                	j	80003c00 <readi+0x4c>
      brelse(bp);
    80003c76:	854a                	mv	a0,s2
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	5b4080e7          	jalr	1460(ra) # 8000322c <brelse>
  }
  return tot;
    80003c80:	0009851b          	sext.w	a0,s3
}
    80003c84:	70a6                	ld	ra,104(sp)
    80003c86:	7406                	ld	s0,96(sp)
    80003c88:	64e6                	ld	s1,88(sp)
    80003c8a:	6946                	ld	s2,80(sp)
    80003c8c:	69a6                	ld	s3,72(sp)
    80003c8e:	6a06                	ld	s4,64(sp)
    80003c90:	7ae2                	ld	s5,56(sp)
    80003c92:	7b42                	ld	s6,48(sp)
    80003c94:	7ba2                	ld	s7,40(sp)
    80003c96:	7c02                	ld	s8,32(sp)
    80003c98:	6ce2                	ld	s9,24(sp)
    80003c9a:	6d42                	ld	s10,16(sp)
    80003c9c:	6da2                	ld	s11,8(sp)
    80003c9e:	6165                	addi	sp,sp,112
    80003ca0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca2:	89da                	mv	s3,s6
    80003ca4:	bff1                	j	80003c80 <readi+0xcc>
    return 0;
    80003ca6:	4501                	li	a0,0
}
    80003ca8:	8082                	ret

0000000080003caa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003caa:	457c                	lw	a5,76(a0)
    80003cac:	10d7e663          	bltu	a5,a3,80003db8 <writei+0x10e>
{
    80003cb0:	7159                	addi	sp,sp,-112
    80003cb2:	f486                	sd	ra,104(sp)
    80003cb4:	f0a2                	sd	s0,96(sp)
    80003cb6:	eca6                	sd	s1,88(sp)
    80003cb8:	e8ca                	sd	s2,80(sp)
    80003cba:	e4ce                	sd	s3,72(sp)
    80003cbc:	e0d2                	sd	s4,64(sp)
    80003cbe:	fc56                	sd	s5,56(sp)
    80003cc0:	f85a                	sd	s6,48(sp)
    80003cc2:	f45e                	sd	s7,40(sp)
    80003cc4:	f062                	sd	s8,32(sp)
    80003cc6:	ec66                	sd	s9,24(sp)
    80003cc8:	e86a                	sd	s10,16(sp)
    80003cca:	e46e                	sd	s11,8(sp)
    80003ccc:	1880                	addi	s0,sp,112
    80003cce:	8baa                	mv	s7,a0
    80003cd0:	8c2e                	mv	s8,a1
    80003cd2:	8ab2                	mv	s5,a2
    80003cd4:	8936                	mv	s2,a3
    80003cd6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cd8:	00e687bb          	addw	a5,a3,a4
    80003cdc:	0ed7e063          	bltu	a5,a3,80003dbc <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ce0:	00043737          	lui	a4,0x43
    80003ce4:	0cf76e63          	bltu	a4,a5,80003dc0 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce8:	0a0b0763          	beqz	s6,80003d96 <writei+0xec>
    80003cec:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cee:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cf2:	5cfd                	li	s9,-1
    80003cf4:	a091                	j	80003d38 <writei+0x8e>
    80003cf6:	02099d93          	slli	s11,s3,0x20
    80003cfa:	020ddd93          	srli	s11,s11,0x20
    80003cfe:	05848793          	addi	a5,s1,88
    80003d02:	86ee                	mv	a3,s11
    80003d04:	8656                	mv	a2,s5
    80003d06:	85e2                	mv	a1,s8
    80003d08:	953e                	add	a0,a0,a5
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	a6e080e7          	jalr	-1426(ra) # 80002778 <either_copyin>
    80003d12:	07950263          	beq	a0,s9,80003d76 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d16:	8526                	mv	a0,s1
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	77e080e7          	jalr	1918(ra) # 80004496 <log_write>
    brelse(bp);
    80003d20:	8526                	mv	a0,s1
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	50a080e7          	jalr	1290(ra) # 8000322c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2a:	01498a3b          	addw	s4,s3,s4
    80003d2e:	0129893b          	addw	s2,s3,s2
    80003d32:	9aee                	add	s5,s5,s11
    80003d34:	056a7663          	bgeu	s4,s6,80003d80 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d38:	000ba483          	lw	s1,0(s7)
    80003d3c:	00a9559b          	srliw	a1,s2,0xa
    80003d40:	855e                	mv	a0,s7
    80003d42:	fffff097          	auipc	ra,0xfffff
    80003d46:	7ae080e7          	jalr	1966(ra) # 800034f0 <bmap>
    80003d4a:	0005059b          	sext.w	a1,a0
    80003d4e:	8526                	mv	a0,s1
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	3ac080e7          	jalr	940(ra) # 800030fc <bread>
    80003d58:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5a:	3ff97513          	andi	a0,s2,1023
    80003d5e:	40ad07bb          	subw	a5,s10,a0
    80003d62:	414b073b          	subw	a4,s6,s4
    80003d66:	89be                	mv	s3,a5
    80003d68:	2781                	sext.w	a5,a5
    80003d6a:	0007069b          	sext.w	a3,a4
    80003d6e:	f8f6f4e3          	bgeu	a3,a5,80003cf6 <writei+0x4c>
    80003d72:	89ba                	mv	s3,a4
    80003d74:	b749                	j	80003cf6 <writei+0x4c>
      brelse(bp);
    80003d76:	8526                	mv	a0,s1
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	4b4080e7          	jalr	1204(ra) # 8000322c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d80:	04cba783          	lw	a5,76(s7)
    80003d84:	0127f463          	bgeu	a5,s2,80003d8c <writei+0xe2>
      ip->size = off;
    80003d88:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d8c:	855e                	mv	a0,s7
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	aa8080e7          	jalr	-1368(ra) # 80003836 <iupdate>
  }

  return n;
    80003d96:	000b051b          	sext.w	a0,s6
}
    80003d9a:	70a6                	ld	ra,104(sp)
    80003d9c:	7406                	ld	s0,96(sp)
    80003d9e:	64e6                	ld	s1,88(sp)
    80003da0:	6946                	ld	s2,80(sp)
    80003da2:	69a6                	ld	s3,72(sp)
    80003da4:	6a06                	ld	s4,64(sp)
    80003da6:	7ae2                	ld	s5,56(sp)
    80003da8:	7b42                	ld	s6,48(sp)
    80003daa:	7ba2                	ld	s7,40(sp)
    80003dac:	7c02                	ld	s8,32(sp)
    80003dae:	6ce2                	ld	s9,24(sp)
    80003db0:	6d42                	ld	s10,16(sp)
    80003db2:	6da2                	ld	s11,8(sp)
    80003db4:	6165                	addi	sp,sp,112
    80003db6:	8082                	ret
    return -1;
    80003db8:	557d                	li	a0,-1
}
    80003dba:	8082                	ret
    return -1;
    80003dbc:	557d                	li	a0,-1
    80003dbe:	bff1                	j	80003d9a <writei+0xf0>
    return -1;
    80003dc0:	557d                	li	a0,-1
    80003dc2:	bfe1                	j	80003d9a <writei+0xf0>

0000000080003dc4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dc4:	1141                	addi	sp,sp,-16
    80003dc6:	e406                	sd	ra,8(sp)
    80003dc8:	e022                	sd	s0,0(sp)
    80003dca:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dcc:	4639                	li	a2,14
    80003dce:	ffffd097          	auipc	ra,0xffffd
    80003dd2:	002080e7          	jalr	2(ra) # 80000dd0 <strncmp>
}
    80003dd6:	60a2                	ld	ra,8(sp)
    80003dd8:	6402                	ld	s0,0(sp)
    80003dda:	0141                	addi	sp,sp,16
    80003ddc:	8082                	ret

0000000080003dde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dde:	7139                	addi	sp,sp,-64
    80003de0:	fc06                	sd	ra,56(sp)
    80003de2:	f822                	sd	s0,48(sp)
    80003de4:	f426                	sd	s1,40(sp)
    80003de6:	f04a                	sd	s2,32(sp)
    80003de8:	ec4e                	sd	s3,24(sp)
    80003dea:	e852                	sd	s4,16(sp)
    80003dec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dee:	04451703          	lh	a4,68(a0)
    80003df2:	4785                	li	a5,1
    80003df4:	00f71a63          	bne	a4,a5,80003e08 <dirlookup+0x2a>
    80003df8:	892a                	mv	s2,a0
    80003dfa:	89ae                	mv	s3,a1
    80003dfc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfe:	457c                	lw	a5,76(a0)
    80003e00:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e02:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e04:	e79d                	bnez	a5,80003e32 <dirlookup+0x54>
    80003e06:	a8a5                	j	80003e7e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e08:	00005517          	auipc	a0,0x5
    80003e0c:	82850513          	addi	a0,a0,-2008 # 80008630 <syscalls+0x1a0>
    80003e10:	ffffc097          	auipc	ra,0xffffc
    80003e14:	730080e7          	jalr	1840(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e18:	00005517          	auipc	a0,0x5
    80003e1c:	83050513          	addi	a0,a0,-2000 # 80008648 <syscalls+0x1b8>
    80003e20:	ffffc097          	auipc	ra,0xffffc
    80003e24:	720080e7          	jalr	1824(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e28:	24c1                	addiw	s1,s1,16
    80003e2a:	04c92783          	lw	a5,76(s2)
    80003e2e:	04f4f763          	bgeu	s1,a5,80003e7c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e32:	4741                	li	a4,16
    80003e34:	86a6                	mv	a3,s1
    80003e36:	fc040613          	addi	a2,s0,-64
    80003e3a:	4581                	li	a1,0
    80003e3c:	854a                	mv	a0,s2
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	d76080e7          	jalr	-650(ra) # 80003bb4 <readi>
    80003e46:	47c1                	li	a5,16
    80003e48:	fcf518e3          	bne	a0,a5,80003e18 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e4c:	fc045783          	lhu	a5,-64(s0)
    80003e50:	dfe1                	beqz	a5,80003e28 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e52:	fc240593          	addi	a1,s0,-62
    80003e56:	854e                	mv	a0,s3
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	f6c080e7          	jalr	-148(ra) # 80003dc4 <namecmp>
    80003e60:	f561                	bnez	a0,80003e28 <dirlookup+0x4a>
      if(poff)
    80003e62:	000a0463          	beqz	s4,80003e6a <dirlookup+0x8c>
        *poff = off;
    80003e66:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e6a:	fc045583          	lhu	a1,-64(s0)
    80003e6e:	00092503          	lw	a0,0(s2)
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	75a080e7          	jalr	1882(ra) # 800035cc <iget>
    80003e7a:	a011                	j	80003e7e <dirlookup+0xa0>
  return 0;
    80003e7c:	4501                	li	a0,0
}
    80003e7e:	70e2                	ld	ra,56(sp)
    80003e80:	7442                	ld	s0,48(sp)
    80003e82:	74a2                	ld	s1,40(sp)
    80003e84:	7902                	ld	s2,32(sp)
    80003e86:	69e2                	ld	s3,24(sp)
    80003e88:	6a42                	ld	s4,16(sp)
    80003e8a:	6121                	addi	sp,sp,64
    80003e8c:	8082                	ret

0000000080003e8e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e8e:	711d                	addi	sp,sp,-96
    80003e90:	ec86                	sd	ra,88(sp)
    80003e92:	e8a2                	sd	s0,80(sp)
    80003e94:	e4a6                	sd	s1,72(sp)
    80003e96:	e0ca                	sd	s2,64(sp)
    80003e98:	fc4e                	sd	s3,56(sp)
    80003e9a:	f852                	sd	s4,48(sp)
    80003e9c:	f456                	sd	s5,40(sp)
    80003e9e:	f05a                	sd	s6,32(sp)
    80003ea0:	ec5e                	sd	s7,24(sp)
    80003ea2:	e862                	sd	s8,16(sp)
    80003ea4:	e466                	sd	s9,8(sp)
    80003ea6:	1080                	addi	s0,sp,96
    80003ea8:	84aa                	mv	s1,a0
    80003eaa:	8aae                	mv	s5,a1
    80003eac:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eae:	00054703          	lbu	a4,0(a0)
    80003eb2:	02f00793          	li	a5,47
    80003eb6:	02f70363          	beq	a4,a5,80003edc <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003eba:	ffffe097          	auipc	ra,0xffffe
    80003ebe:	c30080e7          	jalr	-976(ra) # 80001aea <myproc>
    80003ec2:	15053503          	ld	a0,336(a0)
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	9fc080e7          	jalr	-1540(ra) # 800038c2 <idup>
    80003ece:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ed0:	02f00913          	li	s2,47
  len = path - s;
    80003ed4:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003ed6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ed8:	4b85                	li	s7,1
    80003eda:	a865                	j	80003f92 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003edc:	4585                	li	a1,1
    80003ede:	4505                	li	a0,1
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	6ec080e7          	jalr	1772(ra) # 800035cc <iget>
    80003ee8:	89aa                	mv	s3,a0
    80003eea:	b7dd                	j	80003ed0 <namex+0x42>
      iunlockput(ip);
    80003eec:	854e                	mv	a0,s3
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	c74080e7          	jalr	-908(ra) # 80003b62 <iunlockput>
      return 0;
    80003ef6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ef8:	854e                	mv	a0,s3
    80003efa:	60e6                	ld	ra,88(sp)
    80003efc:	6446                	ld	s0,80(sp)
    80003efe:	64a6                	ld	s1,72(sp)
    80003f00:	6906                	ld	s2,64(sp)
    80003f02:	79e2                	ld	s3,56(sp)
    80003f04:	7a42                	ld	s4,48(sp)
    80003f06:	7aa2                	ld	s5,40(sp)
    80003f08:	7b02                	ld	s6,32(sp)
    80003f0a:	6be2                	ld	s7,24(sp)
    80003f0c:	6c42                	ld	s8,16(sp)
    80003f0e:	6ca2                	ld	s9,8(sp)
    80003f10:	6125                	addi	sp,sp,96
    80003f12:	8082                	ret
      iunlock(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	aac080e7          	jalr	-1364(ra) # 800039c2 <iunlock>
      return ip;
    80003f1e:	bfe9                	j	80003ef8 <namex+0x6a>
      iunlockput(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	c40080e7          	jalr	-960(ra) # 80003b62 <iunlockput>
      return 0;
    80003f2a:	89e6                	mv	s3,s9
    80003f2c:	b7f1                	j	80003ef8 <namex+0x6a>
  len = path - s;
    80003f2e:	40b48633          	sub	a2,s1,a1
    80003f32:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f36:	099c5463          	bge	s8,s9,80003fbe <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f3a:	4639                	li	a2,14
    80003f3c:	8552                	mv	a0,s4
    80003f3e:	ffffd097          	auipc	ra,0xffffd
    80003f42:	e16080e7          	jalr	-490(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003f46:	0004c783          	lbu	a5,0(s1)
    80003f4a:	01279763          	bne	a5,s2,80003f58 <namex+0xca>
    path++;
    80003f4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f50:	0004c783          	lbu	a5,0(s1)
    80003f54:	ff278de3          	beq	a5,s2,80003f4e <namex+0xc0>
    ilock(ip);
    80003f58:	854e                	mv	a0,s3
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	9a6080e7          	jalr	-1626(ra) # 80003900 <ilock>
    if(ip->type != T_DIR){
    80003f62:	04499783          	lh	a5,68(s3)
    80003f66:	f97793e3          	bne	a5,s7,80003eec <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f6a:	000a8563          	beqz	s5,80003f74 <namex+0xe6>
    80003f6e:	0004c783          	lbu	a5,0(s1)
    80003f72:	d3cd                	beqz	a5,80003f14 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f74:	865a                	mv	a2,s6
    80003f76:	85d2                	mv	a1,s4
    80003f78:	854e                	mv	a0,s3
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	e64080e7          	jalr	-412(ra) # 80003dde <dirlookup>
    80003f82:	8caa                	mv	s9,a0
    80003f84:	dd51                	beqz	a0,80003f20 <namex+0x92>
    iunlockput(ip);
    80003f86:	854e                	mv	a0,s3
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	bda080e7          	jalr	-1062(ra) # 80003b62 <iunlockput>
    ip = next;
    80003f90:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f92:	0004c783          	lbu	a5,0(s1)
    80003f96:	05279763          	bne	a5,s2,80003fe4 <namex+0x156>
    path++;
    80003f9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	ff278de3          	beq	a5,s2,80003f9a <namex+0x10c>
  if(*path == 0)
    80003fa4:	c79d                	beqz	a5,80003fd2 <namex+0x144>
    path++;
    80003fa6:	85a6                	mv	a1,s1
  len = path - s;
    80003fa8:	8cda                	mv	s9,s6
    80003faa:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fac:	01278963          	beq	a5,s2,80003fbe <namex+0x130>
    80003fb0:	dfbd                	beqz	a5,80003f2e <namex+0xa0>
    path++;
    80003fb2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fb4:	0004c783          	lbu	a5,0(s1)
    80003fb8:	ff279ce3          	bne	a5,s2,80003fb0 <namex+0x122>
    80003fbc:	bf8d                	j	80003f2e <namex+0xa0>
    memmove(name, s, len);
    80003fbe:	2601                	sext.w	a2,a2
    80003fc0:	8552                	mv	a0,s4
    80003fc2:	ffffd097          	auipc	ra,0xffffd
    80003fc6:	d92080e7          	jalr	-622(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003fca:	9cd2                	add	s9,s9,s4
    80003fcc:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003fd0:	bf9d                	j	80003f46 <namex+0xb8>
  if(nameiparent){
    80003fd2:	f20a83e3          	beqz	s5,80003ef8 <namex+0x6a>
    iput(ip);
    80003fd6:	854e                	mv	a0,s3
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	ae2080e7          	jalr	-1310(ra) # 80003aba <iput>
    return 0;
    80003fe0:	4981                	li	s3,0
    80003fe2:	bf19                	j	80003ef8 <namex+0x6a>
  if(*path == 0)
    80003fe4:	d7fd                	beqz	a5,80003fd2 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fe6:	0004c783          	lbu	a5,0(s1)
    80003fea:	85a6                	mv	a1,s1
    80003fec:	b7d1                	j	80003fb0 <namex+0x122>

0000000080003fee <dirlink>:
{
    80003fee:	7139                	addi	sp,sp,-64
    80003ff0:	fc06                	sd	ra,56(sp)
    80003ff2:	f822                	sd	s0,48(sp)
    80003ff4:	f426                	sd	s1,40(sp)
    80003ff6:	f04a                	sd	s2,32(sp)
    80003ff8:	ec4e                	sd	s3,24(sp)
    80003ffa:	e852                	sd	s4,16(sp)
    80003ffc:	0080                	addi	s0,sp,64
    80003ffe:	892a                	mv	s2,a0
    80004000:	8a2e                	mv	s4,a1
    80004002:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004004:	4601                	li	a2,0
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	dd8080e7          	jalr	-552(ra) # 80003dde <dirlookup>
    8000400e:	e93d                	bnez	a0,80004084 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004010:	04c92483          	lw	s1,76(s2)
    80004014:	c49d                	beqz	s1,80004042 <dirlink+0x54>
    80004016:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004018:	4741                	li	a4,16
    8000401a:	86a6                	mv	a3,s1
    8000401c:	fc040613          	addi	a2,s0,-64
    80004020:	4581                	li	a1,0
    80004022:	854a                	mv	a0,s2
    80004024:	00000097          	auipc	ra,0x0
    80004028:	b90080e7          	jalr	-1136(ra) # 80003bb4 <readi>
    8000402c:	47c1                	li	a5,16
    8000402e:	06f51163          	bne	a0,a5,80004090 <dirlink+0xa2>
    if(de.inum == 0)
    80004032:	fc045783          	lhu	a5,-64(s0)
    80004036:	c791                	beqz	a5,80004042 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004038:	24c1                	addiw	s1,s1,16
    8000403a:	04c92783          	lw	a5,76(s2)
    8000403e:	fcf4ede3          	bltu	s1,a5,80004018 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004042:	4639                	li	a2,14
    80004044:	85d2                	mv	a1,s4
    80004046:	fc240513          	addi	a0,s0,-62
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	dc2080e7          	jalr	-574(ra) # 80000e0c <strncpy>
  de.inum = inum;
    80004052:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004056:	4741                	li	a4,16
    80004058:	86a6                	mv	a3,s1
    8000405a:	fc040613          	addi	a2,s0,-64
    8000405e:	4581                	li	a1,0
    80004060:	854a                	mv	a0,s2
    80004062:	00000097          	auipc	ra,0x0
    80004066:	c48080e7          	jalr	-952(ra) # 80003caa <writei>
    8000406a:	872a                	mv	a4,a0
    8000406c:	47c1                	li	a5,16
  return 0;
    8000406e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004070:	02f71863          	bne	a4,a5,800040a0 <dirlink+0xb2>
}
    80004074:	70e2                	ld	ra,56(sp)
    80004076:	7442                	ld	s0,48(sp)
    80004078:	74a2                	ld	s1,40(sp)
    8000407a:	7902                	ld	s2,32(sp)
    8000407c:	69e2                	ld	s3,24(sp)
    8000407e:	6a42                	ld	s4,16(sp)
    80004080:	6121                	addi	sp,sp,64
    80004082:	8082                	ret
    iput(ip);
    80004084:	00000097          	auipc	ra,0x0
    80004088:	a36080e7          	jalr	-1482(ra) # 80003aba <iput>
    return -1;
    8000408c:	557d                	li	a0,-1
    8000408e:	b7dd                	j	80004074 <dirlink+0x86>
      panic("dirlink read");
    80004090:	00004517          	auipc	a0,0x4
    80004094:	5c850513          	addi	a0,a0,1480 # 80008658 <syscalls+0x1c8>
    80004098:	ffffc097          	auipc	ra,0xffffc
    8000409c:	4a8080e7          	jalr	1192(ra) # 80000540 <panic>
    panic("dirlink");
    800040a0:	00004517          	auipc	a0,0x4
    800040a4:	6d850513          	addi	a0,a0,1752 # 80008778 <syscalls+0x2e8>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	498080e7          	jalr	1176(ra) # 80000540 <panic>

00000000800040b0 <namei>:

struct inode*
namei(char *path)
{
    800040b0:	1101                	addi	sp,sp,-32
    800040b2:	ec06                	sd	ra,24(sp)
    800040b4:	e822                	sd	s0,16(sp)
    800040b6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040b8:	fe040613          	addi	a2,s0,-32
    800040bc:	4581                	li	a1,0
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	dd0080e7          	jalr	-560(ra) # 80003e8e <namex>
}
    800040c6:	60e2                	ld	ra,24(sp)
    800040c8:	6442                	ld	s0,16(sp)
    800040ca:	6105                	addi	sp,sp,32
    800040cc:	8082                	ret

00000000800040ce <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040ce:	1141                	addi	sp,sp,-16
    800040d0:	e406                	sd	ra,8(sp)
    800040d2:	e022                	sd	s0,0(sp)
    800040d4:	0800                	addi	s0,sp,16
    800040d6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040d8:	4585                	li	a1,1
    800040da:	00000097          	auipc	ra,0x0
    800040de:	db4080e7          	jalr	-588(ra) # 80003e8e <namex>
}
    800040e2:	60a2                	ld	ra,8(sp)
    800040e4:	6402                	ld	s0,0(sp)
    800040e6:	0141                	addi	sp,sp,16
    800040e8:	8082                	ret

00000000800040ea <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ea:	1101                	addi	sp,sp,-32
    800040ec:	ec06                	sd	ra,24(sp)
    800040ee:	e822                	sd	s0,16(sp)
    800040f0:	e426                	sd	s1,8(sp)
    800040f2:	e04a                	sd	s2,0(sp)
    800040f4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040f6:	0001e917          	auipc	s2,0x1e
    800040fa:	41290913          	addi	s2,s2,1042 # 80022508 <log>
    800040fe:	01892583          	lw	a1,24(s2)
    80004102:	02892503          	lw	a0,40(s2)
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	ff6080e7          	jalr	-10(ra) # 800030fc <bread>
    8000410e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004110:	02c92683          	lw	a3,44(s2)
    80004114:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004116:	02d05863          	blez	a3,80004146 <write_head+0x5c>
    8000411a:	0001e797          	auipc	a5,0x1e
    8000411e:	41e78793          	addi	a5,a5,1054 # 80022538 <log+0x30>
    80004122:	05c50713          	addi	a4,a0,92
    80004126:	36fd                	addiw	a3,a3,-1
    80004128:	02069613          	slli	a2,a3,0x20
    8000412c:	01e65693          	srli	a3,a2,0x1e
    80004130:	0001e617          	auipc	a2,0x1e
    80004134:	40c60613          	addi	a2,a2,1036 # 8002253c <log+0x34>
    80004138:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000413a:	4390                	lw	a2,0(a5)
    8000413c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413e:	0791                	addi	a5,a5,4
    80004140:	0711                	addi	a4,a4,4
    80004142:	fed79ce3          	bne	a5,a3,8000413a <write_head+0x50>
  }
  bwrite(buf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	0a6080e7          	jalr	166(ra) # 800031ee <bwrite>
  brelse(buf);
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	0da080e7          	jalr	218(ra) # 8000322c <brelse>
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	64a2                	ld	s1,8(sp)
    80004160:	6902                	ld	s2,0(sp)
    80004162:	6105                	addi	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004166:	0001e797          	auipc	a5,0x1e
    8000416a:	3ce7a783          	lw	a5,974(a5) # 80022534 <log+0x2c>
    8000416e:	0af05663          	blez	a5,8000421a <install_trans+0xb4>
{
    80004172:	7139                	addi	sp,sp,-64
    80004174:	fc06                	sd	ra,56(sp)
    80004176:	f822                	sd	s0,48(sp)
    80004178:	f426                	sd	s1,40(sp)
    8000417a:	f04a                	sd	s2,32(sp)
    8000417c:	ec4e                	sd	s3,24(sp)
    8000417e:	e852                	sd	s4,16(sp)
    80004180:	e456                	sd	s5,8(sp)
    80004182:	0080                	addi	s0,sp,64
    80004184:	0001ea97          	auipc	s5,0x1e
    80004188:	3b4a8a93          	addi	s5,s5,948 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000418e:	0001e997          	auipc	s3,0x1e
    80004192:	37a98993          	addi	s3,s3,890 # 80022508 <log>
    80004196:	0189a583          	lw	a1,24(s3)
    8000419a:	014585bb          	addw	a1,a1,s4
    8000419e:	2585                	addiw	a1,a1,1
    800041a0:	0289a503          	lw	a0,40(s3)
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	f58080e7          	jalr	-168(ra) # 800030fc <bread>
    800041ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041ae:	000aa583          	lw	a1,0(s5)
    800041b2:	0289a503          	lw	a0,40(s3)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	f46080e7          	jalr	-186(ra) # 800030fc <bread>
    800041be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c0:	40000613          	li	a2,1024
    800041c4:	05890593          	addi	a1,s2,88
    800041c8:	05850513          	addi	a0,a0,88
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	b88080e7          	jalr	-1144(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	018080e7          	jalr	24(ra) # 800031ee <bwrite>
    bunpin(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	126080e7          	jalr	294(ra) # 80003306 <bunpin>
    brelse(lbuf);
    800041e8:	854a                	mv	a0,s2
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	042080e7          	jalr	66(ra) # 8000322c <brelse>
    brelse(dbuf);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	038080e7          	jalr	56(ra) # 8000322c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fc:	2a05                	addiw	s4,s4,1
    800041fe:	0a91                	addi	s5,s5,4
    80004200:	02c9a783          	lw	a5,44(s3)
    80004204:	f8fa49e3          	blt	s4,a5,80004196 <install_trans+0x30>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    8000421a:	8082                	ret

000000008000421c <initlog>:
{
    8000421c:	7179                	addi	sp,sp,-48
    8000421e:	f406                	sd	ra,40(sp)
    80004220:	f022                	sd	s0,32(sp)
    80004222:	ec26                	sd	s1,24(sp)
    80004224:	e84a                	sd	s2,16(sp)
    80004226:	e44e                	sd	s3,8(sp)
    80004228:	1800                	addi	s0,sp,48
    8000422a:	892a                	mv	s2,a0
    8000422c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000422e:	0001e497          	auipc	s1,0x1e
    80004232:	2da48493          	addi	s1,s1,730 # 80022508 <log>
    80004236:	00004597          	auipc	a1,0x4
    8000423a:	43258593          	addi	a1,a1,1074 # 80008668 <syscalls+0x1d8>
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	92c080e7          	jalr	-1748(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    80004248:	0149a583          	lw	a1,20(s3)
    8000424c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000424e:	0109a783          	lw	a5,16(s3)
    80004252:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004254:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004258:	854a                	mv	a0,s2
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	ea2080e7          	jalr	-350(ra) # 800030fc <bread>
  log.lh.n = lh->n;
    80004262:	4d34                	lw	a3,88(a0)
    80004264:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004266:	02d05663          	blez	a3,80004292 <initlog+0x76>
    8000426a:	05c50793          	addi	a5,a0,92
    8000426e:	0001e717          	auipc	a4,0x1e
    80004272:	2ca70713          	addi	a4,a4,714 # 80022538 <log+0x30>
    80004276:	36fd                	addiw	a3,a3,-1
    80004278:	02069613          	slli	a2,a3,0x20
    8000427c:	01e65693          	srli	a3,a2,0x1e
    80004280:	06050613          	addi	a2,a0,96
    80004284:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004286:	4390                	lw	a2,0(a5)
    80004288:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000428a:	0791                	addi	a5,a5,4
    8000428c:	0711                	addi	a4,a4,4
    8000428e:	fed79ce3          	bne	a5,a3,80004286 <initlog+0x6a>
  brelse(buf);
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	f9a080e7          	jalr	-102(ra) # 8000322c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	ecc080e7          	jalr	-308(ra) # 80004166 <install_trans>
  log.lh.n = 0;
    800042a2:	0001e797          	auipc	a5,0x1e
    800042a6:	2807a923          	sw	zero,658(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	e40080e7          	jalr	-448(ra) # 800040ea <write_head>
}
    800042b2:	70a2                	ld	ra,40(sp)
    800042b4:	7402                	ld	s0,32(sp)
    800042b6:	64e2                	ld	s1,24(sp)
    800042b8:	6942                	ld	s2,16(sp)
    800042ba:	69a2                	ld	s3,8(sp)
    800042bc:	6145                	addi	sp,sp,48
    800042be:	8082                	ret

00000000800042c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042c0:	1101                	addi	sp,sp,-32
    800042c2:	ec06                	sd	ra,24(sp)
    800042c4:	e822                	sd	s0,16(sp)
    800042c6:	e426                	sd	s1,8(sp)
    800042c8:	e04a                	sd	s2,0(sp)
    800042ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042cc:	0001e517          	auipc	a0,0x1e
    800042d0:	23c50513          	addi	a0,a0,572 # 80022508 <log>
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	928080e7          	jalr	-1752(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    800042dc:	0001e497          	auipc	s1,0x1e
    800042e0:	22c48493          	addi	s1,s1,556 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e4:	4979                	li	s2,30
    800042e6:	a039                	j	800042f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042e8:	85a6                	mv	a1,s1
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffe097          	auipc	ra,0xffffe
    800042f0:	1c0080e7          	jalr	448(ra) # 800024ac <sleep>
    if(log.committing){
    800042f4:	50dc                	lw	a5,36(s1)
    800042f6:	fbed                	bnez	a5,800042e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f8:	509c                	lw	a5,32(s1)
    800042fa:	0017871b          	addiw	a4,a5,1
    800042fe:	0007069b          	sext.w	a3,a4
    80004302:	0027179b          	slliw	a5,a4,0x2
    80004306:	9fb9                	addw	a5,a5,a4
    80004308:	0017979b          	slliw	a5,a5,0x1
    8000430c:	54d8                	lw	a4,44(s1)
    8000430e:	9fb9                	addw	a5,a5,a4
    80004310:	00f95963          	bge	s2,a5,80004322 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004314:	85a6                	mv	a1,s1
    80004316:	8526                	mv	a0,s1
    80004318:	ffffe097          	auipc	ra,0xffffe
    8000431c:	194080e7          	jalr	404(ra) # 800024ac <sleep>
    80004320:	bfd1                	j	800042f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004322:	0001e517          	auipc	a0,0x1e
    80004326:	1e650513          	addi	a0,a0,486 # 80022508 <log>
    8000432a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	984080e7          	jalr	-1660(ra) # 80000cb0 <release>
      break;
    }
  }
}
    80004334:	60e2                	ld	ra,24(sp)
    80004336:	6442                	ld	s0,16(sp)
    80004338:	64a2                	ld	s1,8(sp)
    8000433a:	6902                	ld	s2,0(sp)
    8000433c:	6105                	addi	sp,sp,32
    8000433e:	8082                	ret

0000000080004340 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004340:	7139                	addi	sp,sp,-64
    80004342:	fc06                	sd	ra,56(sp)
    80004344:	f822                	sd	s0,48(sp)
    80004346:	f426                	sd	s1,40(sp)
    80004348:	f04a                	sd	s2,32(sp)
    8000434a:	ec4e                	sd	s3,24(sp)
    8000434c:	e852                	sd	s4,16(sp)
    8000434e:	e456                	sd	s5,8(sp)
    80004350:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004352:	0001e497          	auipc	s1,0x1e
    80004356:	1b648493          	addi	s1,s1,438 # 80022508 <log>
    8000435a:	8526                	mv	a0,s1
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	8a0080e7          	jalr	-1888(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    80004364:	509c                	lw	a5,32(s1)
    80004366:	37fd                	addiw	a5,a5,-1
    80004368:	0007891b          	sext.w	s2,a5
    8000436c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000436e:	50dc                	lw	a5,36(s1)
    80004370:	e7b9                	bnez	a5,800043be <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004372:	04091e63          	bnez	s2,800043ce <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004376:	0001e497          	auipc	s1,0x1e
    8000437a:	19248493          	addi	s1,s1,402 # 80022508 <log>
    8000437e:	4785                	li	a5,1
    80004380:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004382:	8526                	mv	a0,s1
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	92c080e7          	jalr	-1748(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000438c:	54dc                	lw	a5,44(s1)
    8000438e:	06f04763          	bgtz	a5,800043fc <end_op+0xbc>
    acquire(&log.lock);
    80004392:	0001e497          	auipc	s1,0x1e
    80004396:	17648493          	addi	s1,s1,374 # 80022508 <log>
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	860080e7          	jalr	-1952(ra) # 80000bfc <acquire>
    log.committing = 0;
    800043a4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	28e080e7          	jalr	654(ra) # 80002638 <wakeup>
    release(&log.lock);
    800043b2:	8526                	mv	a0,s1
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8fc080e7          	jalr	-1796(ra) # 80000cb0 <release>
}
    800043bc:	a03d                	j	800043ea <end_op+0xaa>
    panic("log.committing");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	2b250513          	addi	a0,a0,690 # 80008670 <syscalls+0x1e0>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	17a080e7          	jalr	378(ra) # 80000540 <panic>
    wakeup(&log);
    800043ce:	0001e497          	auipc	s1,0x1e
    800043d2:	13a48493          	addi	s1,s1,314 # 80022508 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	260080e7          	jalr	608(ra) # 80002638 <wakeup>
  release(&log.lock);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8ce080e7          	jalr	-1842(ra) # 80000cb0 <release>
}
    800043ea:	70e2                	ld	ra,56(sp)
    800043ec:	7442                	ld	s0,48(sp)
    800043ee:	74a2                	ld	s1,40(sp)
    800043f0:	7902                	ld	s2,32(sp)
    800043f2:	69e2                	ld	s3,24(sp)
    800043f4:	6a42                	ld	s4,16(sp)
    800043f6:	6aa2                	ld	s5,8(sp)
    800043f8:	6121                	addi	sp,sp,64
    800043fa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fc:	0001ea97          	auipc	s5,0x1e
    80004400:	13ca8a93          	addi	s5,s5,316 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004404:	0001ea17          	auipc	s4,0x1e
    80004408:	104a0a13          	addi	s4,s4,260 # 80022508 <log>
    8000440c:	018a2583          	lw	a1,24(s4)
    80004410:	012585bb          	addw	a1,a1,s2
    80004414:	2585                	addiw	a1,a1,1
    80004416:	028a2503          	lw	a0,40(s4)
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	ce2080e7          	jalr	-798(ra) # 800030fc <bread>
    80004422:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004424:	000aa583          	lw	a1,0(s5)
    80004428:	028a2503          	lw	a0,40(s4)
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	cd0080e7          	jalr	-816(ra) # 800030fc <bread>
    80004434:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004436:	40000613          	li	a2,1024
    8000443a:	05850593          	addi	a1,a0,88
    8000443e:	05848513          	addi	a0,s1,88
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	912080e7          	jalr	-1774(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    8000444a:	8526                	mv	a0,s1
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	da2080e7          	jalr	-606(ra) # 800031ee <bwrite>
    brelse(from);
    80004454:	854e                	mv	a0,s3
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	dd6080e7          	jalr	-554(ra) # 8000322c <brelse>
    brelse(to);
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	dcc080e7          	jalr	-564(ra) # 8000322c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004468:	2905                	addiw	s2,s2,1
    8000446a:	0a91                	addi	s5,s5,4
    8000446c:	02ca2783          	lw	a5,44(s4)
    80004470:	f8f94ee3          	blt	s2,a5,8000440c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c76080e7          	jalr	-906(ra) # 800040ea <write_head>
    install_trans(); // Now install writes to home locations
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	cea080e7          	jalr	-790(ra) # 80004166 <install_trans>
    log.lh.n = 0;
    80004484:	0001e797          	auipc	a5,0x1e
    80004488:	0a07a823          	sw	zero,176(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	c5e080e7          	jalr	-930(ra) # 800040ea <write_head>
    80004494:	bdfd                	j	80004392 <end_op+0x52>

0000000080004496 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	e426                	sd	s1,8(sp)
    8000449e:	e04a                	sd	s2,0(sp)
    800044a0:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a2:	0001e717          	auipc	a4,0x1e
    800044a6:	09272703          	lw	a4,146(a4) # 80022534 <log+0x2c>
    800044aa:	47f5                	li	a5,29
    800044ac:	08e7c063          	blt	a5,a4,8000452c <log_write+0x96>
    800044b0:	84aa                	mv	s1,a0
    800044b2:	0001e797          	auipc	a5,0x1e
    800044b6:	0727a783          	lw	a5,114(a5) # 80022524 <log+0x1c>
    800044ba:	37fd                	addiw	a5,a5,-1
    800044bc:	06f75863          	bge	a4,a5,8000452c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044c0:	0001e797          	auipc	a5,0x1e
    800044c4:	0687a783          	lw	a5,104(a5) # 80022528 <log+0x20>
    800044c8:	06f05a63          	blez	a5,8000453c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044cc:	0001e917          	auipc	s2,0x1e
    800044d0:	03c90913          	addi	s2,s2,60 # 80022508 <log>
    800044d4:	854a                	mv	a0,s2
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	726080e7          	jalr	1830(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044de:	02c92603          	lw	a2,44(s2)
    800044e2:	06c05563          	blez	a2,8000454c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044e6:	44cc                	lw	a1,12(s1)
    800044e8:	0001e717          	auipc	a4,0x1e
    800044ec:	05070713          	addi	a4,a4,80 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044f0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044f2:	4314                	lw	a3,0(a4)
    800044f4:	04b68d63          	beq	a3,a1,8000454e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044f8:	2785                	addiw	a5,a5,1
    800044fa:	0711                	addi	a4,a4,4
    800044fc:	fec79be3          	bne	a5,a2,800044f2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004500:	0621                	addi	a2,a2,8
    80004502:	060a                	slli	a2,a2,0x2
    80004504:	0001e797          	auipc	a5,0x1e
    80004508:	00478793          	addi	a5,a5,4 # 80022508 <log>
    8000450c:	963e                	add	a2,a2,a5
    8000450e:	44dc                	lw	a5,12(s1)
    80004510:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	db6080e7          	jalr	-586(ra) # 800032ca <bpin>
    log.lh.n++;
    8000451c:	0001e717          	auipc	a4,0x1e
    80004520:	fec70713          	addi	a4,a4,-20 # 80022508 <log>
    80004524:	575c                	lw	a5,44(a4)
    80004526:	2785                	addiw	a5,a5,1
    80004528:	d75c                	sw	a5,44(a4)
    8000452a:	a83d                	j	80004568 <log_write+0xd2>
    panic("too big a transaction");
    8000452c:	00004517          	auipc	a0,0x4
    80004530:	15450513          	addi	a0,a0,340 # 80008680 <syscalls+0x1f0>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	00c080e7          	jalr	12(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000453c:	00004517          	auipc	a0,0x4
    80004540:	15c50513          	addi	a0,a0,348 # 80008698 <syscalls+0x208>
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	ffc080e7          	jalr	-4(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000454c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000454e:	00878713          	addi	a4,a5,8
    80004552:	00271693          	slli	a3,a4,0x2
    80004556:	0001e717          	auipc	a4,0x1e
    8000455a:	fb270713          	addi	a4,a4,-78 # 80022508 <log>
    8000455e:	9736                	add	a4,a4,a3
    80004560:	44d4                	lw	a3,12(s1)
    80004562:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004564:	faf607e3          	beq	a2,a5,80004512 <log_write+0x7c>
  }
  release(&log.lock);
    80004568:	0001e517          	auipc	a0,0x1e
    8000456c:	fa050513          	addi	a0,a0,-96 # 80022508 <log>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	740080e7          	jalr	1856(ra) # 80000cb0 <release>
}
    80004578:	60e2                	ld	ra,24(sp)
    8000457a:	6442                	ld	s0,16(sp)
    8000457c:	64a2                	ld	s1,8(sp)
    8000457e:	6902                	ld	s2,0(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret

0000000080004584 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004584:	1101                	addi	sp,sp,-32
    80004586:	ec06                	sd	ra,24(sp)
    80004588:	e822                	sd	s0,16(sp)
    8000458a:	e426                	sd	s1,8(sp)
    8000458c:	e04a                	sd	s2,0(sp)
    8000458e:	1000                	addi	s0,sp,32
    80004590:	84aa                	mv	s1,a0
    80004592:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004594:	00004597          	auipc	a1,0x4
    80004598:	12458593          	addi	a1,a1,292 # 800086b8 <syscalls+0x228>
    8000459c:	0521                	addi	a0,a0,8
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	5ce080e7          	jalr	1486(ra) # 80000b6c <initlock>
  lk->name = name;
    800045a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ae:	0204a423          	sw	zero,40(s1)
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6902                	ld	s2,0(sp)
    800045ba:	6105                	addi	sp,sp,32
    800045bc:	8082                	ret

00000000800045be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045be:	1101                	addi	sp,sp,-32
    800045c0:	ec06                	sd	ra,24(sp)
    800045c2:	e822                	sd	s0,16(sp)
    800045c4:	e426                	sd	s1,8(sp)
    800045c6:	e04a                	sd	s2,0(sp)
    800045c8:	1000                	addi	s0,sp,32
    800045ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045cc:	00850913          	addi	s2,a0,8
    800045d0:	854a                	mv	a0,s2
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	62a080e7          	jalr	1578(ra) # 80000bfc <acquire>
  while (lk->locked) {
    800045da:	409c                	lw	a5,0(s1)
    800045dc:	cb89                	beqz	a5,800045ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045de:	85ca                	mv	a1,s2
    800045e0:	8526                	mv	a0,s1
    800045e2:	ffffe097          	auipc	ra,0xffffe
    800045e6:	eca080e7          	jalr	-310(ra) # 800024ac <sleep>
  while (lk->locked) {
    800045ea:	409c                	lw	a5,0(s1)
    800045ec:	fbed                	bnez	a5,800045de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ee:	4785                	li	a5,1
    800045f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045f2:	ffffd097          	auipc	ra,0xffffd
    800045f6:	4f8080e7          	jalr	1272(ra) # 80001aea <myproc>
    800045fa:	5d1c                	lw	a5,56(a0)
    800045fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	6b0080e7          	jalr	1712(ra) # 80000cb0 <release>
}
    80004608:	60e2                	ld	ra,24(sp)
    8000460a:	6442                	ld	s0,16(sp)
    8000460c:	64a2                	ld	s1,8(sp)
    8000460e:	6902                	ld	s2,0(sp)
    80004610:	6105                	addi	sp,sp,32
    80004612:	8082                	ret

0000000080004614 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004614:	1101                	addi	sp,sp,-32
    80004616:	ec06                	sd	ra,24(sp)
    80004618:	e822                	sd	s0,16(sp)
    8000461a:	e426                	sd	s1,8(sp)
    8000461c:	e04a                	sd	s2,0(sp)
    8000461e:	1000                	addi	s0,sp,32
    80004620:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004622:	00850913          	addi	s2,a0,8
    80004626:	854a                	mv	a0,s2
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	5d4080e7          	jalr	1492(ra) # 80000bfc <acquire>
  lk->locked = 0;
    80004630:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004634:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004638:	8526                	mv	a0,s1
    8000463a:	ffffe097          	auipc	ra,0xffffe
    8000463e:	ffe080e7          	jalr	-2(ra) # 80002638 <wakeup>
  release(&lk->lk);
    80004642:	854a                	mv	a0,s2
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	66c080e7          	jalr	1644(ra) # 80000cb0 <release>
}
    8000464c:	60e2                	ld	ra,24(sp)
    8000464e:	6442                	ld	s0,16(sp)
    80004650:	64a2                	ld	s1,8(sp)
    80004652:	6902                	ld	s2,0(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret

0000000080004658 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004658:	7179                	addi	sp,sp,-48
    8000465a:	f406                	sd	ra,40(sp)
    8000465c:	f022                	sd	s0,32(sp)
    8000465e:	ec26                	sd	s1,24(sp)
    80004660:	e84a                	sd	s2,16(sp)
    80004662:	e44e                	sd	s3,8(sp)
    80004664:	1800                	addi	s0,sp,48
    80004666:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004668:	00850913          	addi	s2,a0,8
    8000466c:	854a                	mv	a0,s2
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	58e080e7          	jalr	1422(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004676:	409c                	lw	a5,0(s1)
    80004678:	ef99                	bnez	a5,80004696 <holdingsleep+0x3e>
    8000467a:	4481                	li	s1,0
  release(&lk->lk);
    8000467c:	854a                	mv	a0,s2
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	632080e7          	jalr	1586(ra) # 80000cb0 <release>
  return r;
}
    80004686:	8526                	mv	a0,s1
    80004688:	70a2                	ld	ra,40(sp)
    8000468a:	7402                	ld	s0,32(sp)
    8000468c:	64e2                	ld	s1,24(sp)
    8000468e:	6942                	ld	s2,16(sp)
    80004690:	69a2                	ld	s3,8(sp)
    80004692:	6145                	addi	sp,sp,48
    80004694:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004696:	0284a983          	lw	s3,40(s1)
    8000469a:	ffffd097          	auipc	ra,0xffffd
    8000469e:	450080e7          	jalr	1104(ra) # 80001aea <myproc>
    800046a2:	5d04                	lw	s1,56(a0)
    800046a4:	413484b3          	sub	s1,s1,s3
    800046a8:	0014b493          	seqz	s1,s1
    800046ac:	bfc1                	j	8000467c <holdingsleep+0x24>

00000000800046ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ae:	1141                	addi	sp,sp,-16
    800046b0:	e406                	sd	ra,8(sp)
    800046b2:	e022                	sd	s0,0(sp)
    800046b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046b6:	00004597          	auipc	a1,0x4
    800046ba:	01258593          	addi	a1,a1,18 # 800086c8 <syscalls+0x238>
    800046be:	0001e517          	auipc	a0,0x1e
    800046c2:	f9250513          	addi	a0,a0,-110 # 80022650 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	4a6080e7          	jalr	1190(ra) # 80000b6c <initlock>
}
    800046ce:	60a2                	ld	ra,8(sp)
    800046d0:	6402                	ld	s0,0(sp)
    800046d2:	0141                	addi	sp,sp,16
    800046d4:	8082                	ret

00000000800046d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046d6:	1101                	addi	sp,sp,-32
    800046d8:	ec06                	sd	ra,24(sp)
    800046da:	e822                	sd	s0,16(sp)
    800046dc:	e426                	sd	s1,8(sp)
    800046de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046e0:	0001e517          	auipc	a0,0x1e
    800046e4:	f7050513          	addi	a0,a0,-144 # 80022650 <ftable>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	514080e7          	jalr	1300(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046f0:	0001e497          	auipc	s1,0x1e
    800046f4:	f7848493          	addi	s1,s1,-136 # 80022668 <ftable+0x18>
    800046f8:	0001f717          	auipc	a4,0x1f
    800046fc:	f1070713          	addi	a4,a4,-240 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    80004700:	40dc                	lw	a5,4(s1)
    80004702:	cf99                	beqz	a5,80004720 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004704:	02848493          	addi	s1,s1,40
    80004708:	fee49ce3          	bne	s1,a4,80004700 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000470c:	0001e517          	auipc	a0,0x1e
    80004710:	f4450513          	addi	a0,a0,-188 # 80022650 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	59c080e7          	jalr	1436(ra) # 80000cb0 <release>
  return 0;
    8000471c:	4481                	li	s1,0
    8000471e:	a819                	j	80004734 <filealloc+0x5e>
      f->ref = 1;
    80004720:	4785                	li	a5,1
    80004722:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004724:	0001e517          	auipc	a0,0x1e
    80004728:	f2c50513          	addi	a0,a0,-212 # 80022650 <ftable>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	584080e7          	jalr	1412(ra) # 80000cb0 <release>
}
    80004734:	8526                	mv	a0,s1
    80004736:	60e2                	ld	ra,24(sp)
    80004738:	6442                	ld	s0,16(sp)
    8000473a:	64a2                	ld	s1,8(sp)
    8000473c:	6105                	addi	sp,sp,32
    8000473e:	8082                	ret

0000000080004740 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004740:	1101                	addi	sp,sp,-32
    80004742:	ec06                	sd	ra,24(sp)
    80004744:	e822                	sd	s0,16(sp)
    80004746:	e426                	sd	s1,8(sp)
    80004748:	1000                	addi	s0,sp,32
    8000474a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000474c:	0001e517          	auipc	a0,0x1e
    80004750:	f0450513          	addi	a0,a0,-252 # 80022650 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	4a8080e7          	jalr	1192(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000475c:	40dc                	lw	a5,4(s1)
    8000475e:	02f05263          	blez	a5,80004782 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004762:	2785                	addiw	a5,a5,1
    80004764:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004766:	0001e517          	auipc	a0,0x1e
    8000476a:	eea50513          	addi	a0,a0,-278 # 80022650 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	542080e7          	jalr	1346(ra) # 80000cb0 <release>
  return f;
}
    80004776:	8526                	mv	a0,s1
    80004778:	60e2                	ld	ra,24(sp)
    8000477a:	6442                	ld	s0,16(sp)
    8000477c:	64a2                	ld	s1,8(sp)
    8000477e:	6105                	addi	sp,sp,32
    80004780:	8082                	ret
    panic("filedup");
    80004782:	00004517          	auipc	a0,0x4
    80004786:	f4e50513          	addi	a0,a0,-178 # 800086d0 <syscalls+0x240>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>

0000000080004792 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004792:	7139                	addi	sp,sp,-64
    80004794:	fc06                	sd	ra,56(sp)
    80004796:	f822                	sd	s0,48(sp)
    80004798:	f426                	sd	s1,40(sp)
    8000479a:	f04a                	sd	s2,32(sp)
    8000479c:	ec4e                	sd	s3,24(sp)
    8000479e:	e852                	sd	s4,16(sp)
    800047a0:	e456                	sd	s5,8(sp)
    800047a2:	0080                	addi	s0,sp,64
    800047a4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047a6:	0001e517          	auipc	a0,0x1e
    800047aa:	eaa50513          	addi	a0,a0,-342 # 80022650 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	44e080e7          	jalr	1102(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047b6:	40dc                	lw	a5,4(s1)
    800047b8:	06f05163          	blez	a5,8000481a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047bc:	37fd                	addiw	a5,a5,-1
    800047be:	0007871b          	sext.w	a4,a5
    800047c2:	c0dc                	sw	a5,4(s1)
    800047c4:	06e04363          	bgtz	a4,8000482a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047c8:	0004a903          	lw	s2,0(s1)
    800047cc:	0094ca83          	lbu	s5,9(s1)
    800047d0:	0104ba03          	ld	s4,16(s1)
    800047d4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047d8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047dc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047e0:	0001e517          	auipc	a0,0x1e
    800047e4:	e7050513          	addi	a0,a0,-400 # 80022650 <ftable>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	4c8080e7          	jalr	1224(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    800047f0:	4785                	li	a5,1
    800047f2:	04f90d63          	beq	s2,a5,8000484c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047f6:	3979                	addiw	s2,s2,-2
    800047f8:	4785                	li	a5,1
    800047fa:	0527e063          	bltu	a5,s2,8000483a <fileclose+0xa8>
    begin_op();
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	ac2080e7          	jalr	-1342(ra) # 800042c0 <begin_op>
    iput(ff.ip);
    80004806:	854e                	mv	a0,s3
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	2b2080e7          	jalr	690(ra) # 80003aba <iput>
    end_op();
    80004810:	00000097          	auipc	ra,0x0
    80004814:	b30080e7          	jalr	-1232(ra) # 80004340 <end_op>
    80004818:	a00d                	j	8000483a <fileclose+0xa8>
    panic("fileclose");
    8000481a:	00004517          	auipc	a0,0x4
    8000481e:	ebe50513          	addi	a0,a0,-322 # 800086d8 <syscalls+0x248>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	d1e080e7          	jalr	-738(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000482a:	0001e517          	auipc	a0,0x1e
    8000482e:	e2650513          	addi	a0,a0,-474 # 80022650 <ftable>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	47e080e7          	jalr	1150(ra) # 80000cb0 <release>
  }
}
    8000483a:	70e2                	ld	ra,56(sp)
    8000483c:	7442                	ld	s0,48(sp)
    8000483e:	74a2                	ld	s1,40(sp)
    80004840:	7902                	ld	s2,32(sp)
    80004842:	69e2                	ld	s3,24(sp)
    80004844:	6a42                	ld	s4,16(sp)
    80004846:	6aa2                	ld	s5,8(sp)
    80004848:	6121                	addi	sp,sp,64
    8000484a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000484c:	85d6                	mv	a1,s5
    8000484e:	8552                	mv	a0,s4
    80004850:	00000097          	auipc	ra,0x0
    80004854:	372080e7          	jalr	882(ra) # 80004bc2 <pipeclose>
    80004858:	b7cd                	j	8000483a <fileclose+0xa8>

000000008000485a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000485a:	715d                	addi	sp,sp,-80
    8000485c:	e486                	sd	ra,72(sp)
    8000485e:	e0a2                	sd	s0,64(sp)
    80004860:	fc26                	sd	s1,56(sp)
    80004862:	f84a                	sd	s2,48(sp)
    80004864:	f44e                	sd	s3,40(sp)
    80004866:	0880                	addi	s0,sp,80
    80004868:	84aa                	mv	s1,a0
    8000486a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000486c:	ffffd097          	auipc	ra,0xffffd
    80004870:	27e080e7          	jalr	638(ra) # 80001aea <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004874:	409c                	lw	a5,0(s1)
    80004876:	37f9                	addiw	a5,a5,-2
    80004878:	4705                	li	a4,1
    8000487a:	04f76763          	bltu	a4,a5,800048c8 <filestat+0x6e>
    8000487e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004880:	6c88                	ld	a0,24(s1)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	07e080e7          	jalr	126(ra) # 80003900 <ilock>
    stati(f->ip, &st);
    8000488a:	fb840593          	addi	a1,s0,-72
    8000488e:	6c88                	ld	a0,24(s1)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	2fa080e7          	jalr	762(ra) # 80003b8a <stati>
    iunlock(f->ip);
    80004898:	6c88                	ld	a0,24(s1)
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	128080e7          	jalr	296(ra) # 800039c2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048a2:	46e1                	li	a3,24
    800048a4:	fb840613          	addi	a2,s0,-72
    800048a8:	85ce                	mv	a1,s3
    800048aa:	05093503          	ld	a0,80(s2)
    800048ae:	ffffd097          	auipc	ra,0xffffd
    800048b2:	dfc080e7          	jalr	-516(ra) # 800016aa <copyout>
    800048b6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048ba:	60a6                	ld	ra,72(sp)
    800048bc:	6406                	ld	s0,64(sp)
    800048be:	74e2                	ld	s1,56(sp)
    800048c0:	7942                	ld	s2,48(sp)
    800048c2:	79a2                	ld	s3,40(sp)
    800048c4:	6161                	addi	sp,sp,80
    800048c6:	8082                	ret
  return -1;
    800048c8:	557d                	li	a0,-1
    800048ca:	bfc5                	j	800048ba <filestat+0x60>

00000000800048cc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048cc:	7179                	addi	sp,sp,-48
    800048ce:	f406                	sd	ra,40(sp)
    800048d0:	f022                	sd	s0,32(sp)
    800048d2:	ec26                	sd	s1,24(sp)
    800048d4:	e84a                	sd	s2,16(sp)
    800048d6:	e44e                	sd	s3,8(sp)
    800048d8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048da:	00854783          	lbu	a5,8(a0)
    800048de:	c3d5                	beqz	a5,80004982 <fileread+0xb6>
    800048e0:	84aa                	mv	s1,a0
    800048e2:	89ae                	mv	s3,a1
    800048e4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e6:	411c                	lw	a5,0(a0)
    800048e8:	4705                	li	a4,1
    800048ea:	04e78963          	beq	a5,a4,8000493c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ee:	470d                	li	a4,3
    800048f0:	04e78d63          	beq	a5,a4,8000494a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f4:	4709                	li	a4,2
    800048f6:	06e79e63          	bne	a5,a4,80004972 <fileread+0xa6>
    ilock(f->ip);
    800048fa:	6d08                	ld	a0,24(a0)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	004080e7          	jalr	4(ra) # 80003900 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004904:	874a                	mv	a4,s2
    80004906:	5094                	lw	a3,32(s1)
    80004908:	864e                	mv	a2,s3
    8000490a:	4585                	li	a1,1
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	2a6080e7          	jalr	678(ra) # 80003bb4 <readi>
    80004916:	892a                	mv	s2,a0
    80004918:	00a05563          	blez	a0,80004922 <fileread+0x56>
      f->off += r;
    8000491c:	509c                	lw	a5,32(s1)
    8000491e:	9fa9                	addw	a5,a5,a0
    80004920:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004922:	6c88                	ld	a0,24(s1)
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	09e080e7          	jalr	158(ra) # 800039c2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000492c:	854a                	mv	a0,s2
    8000492e:	70a2                	ld	ra,40(sp)
    80004930:	7402                	ld	s0,32(sp)
    80004932:	64e2                	ld	s1,24(sp)
    80004934:	6942                	ld	s2,16(sp)
    80004936:	69a2                	ld	s3,8(sp)
    80004938:	6145                	addi	sp,sp,48
    8000493a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000493c:	6908                	ld	a0,16(a0)
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	3f4080e7          	jalr	1012(ra) # 80004d32 <piperead>
    80004946:	892a                	mv	s2,a0
    80004948:	b7d5                	j	8000492c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000494a:	02451783          	lh	a5,36(a0)
    8000494e:	03079693          	slli	a3,a5,0x30
    80004952:	92c1                	srli	a3,a3,0x30
    80004954:	4725                	li	a4,9
    80004956:	02d76863          	bltu	a4,a3,80004986 <fileread+0xba>
    8000495a:	0792                	slli	a5,a5,0x4
    8000495c:	0001e717          	auipc	a4,0x1e
    80004960:	c5470713          	addi	a4,a4,-940 # 800225b0 <devsw>
    80004964:	97ba                	add	a5,a5,a4
    80004966:	639c                	ld	a5,0(a5)
    80004968:	c38d                	beqz	a5,8000498a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000496a:	4505                	li	a0,1
    8000496c:	9782                	jalr	a5
    8000496e:	892a                	mv	s2,a0
    80004970:	bf75                	j	8000492c <fileread+0x60>
    panic("fileread");
    80004972:	00004517          	auipc	a0,0x4
    80004976:	d7650513          	addi	a0,a0,-650 # 800086e8 <syscalls+0x258>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	bc6080e7          	jalr	-1082(ra) # 80000540 <panic>
    return -1;
    80004982:	597d                	li	s2,-1
    80004984:	b765                	j	8000492c <fileread+0x60>
      return -1;
    80004986:	597d                	li	s2,-1
    80004988:	b755                	j	8000492c <fileread+0x60>
    8000498a:	597d                	li	s2,-1
    8000498c:	b745                	j	8000492c <fileread+0x60>

000000008000498e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000498e:	00954783          	lbu	a5,9(a0)
    80004992:	14078563          	beqz	a5,80004adc <filewrite+0x14e>
{
    80004996:	715d                	addi	sp,sp,-80
    80004998:	e486                	sd	ra,72(sp)
    8000499a:	e0a2                	sd	s0,64(sp)
    8000499c:	fc26                	sd	s1,56(sp)
    8000499e:	f84a                	sd	s2,48(sp)
    800049a0:	f44e                	sd	s3,40(sp)
    800049a2:	f052                	sd	s4,32(sp)
    800049a4:	ec56                	sd	s5,24(sp)
    800049a6:	e85a                	sd	s6,16(sp)
    800049a8:	e45e                	sd	s7,8(sp)
    800049aa:	e062                	sd	s8,0(sp)
    800049ac:	0880                	addi	s0,sp,80
    800049ae:	892a                	mv	s2,a0
    800049b0:	8aae                	mv	s5,a1
    800049b2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b4:	411c                	lw	a5,0(a0)
    800049b6:	4705                	li	a4,1
    800049b8:	02e78263          	beq	a5,a4,800049dc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049bc:	470d                	li	a4,3
    800049be:	02e78563          	beq	a5,a4,800049e8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c2:	4709                	li	a4,2
    800049c4:	10e79463          	bne	a5,a4,80004acc <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049c8:	0ec05e63          	blez	a2,80004ac4 <filewrite+0x136>
    int i = 0;
    800049cc:	4981                	li	s3,0
    800049ce:	6b05                	lui	s6,0x1
    800049d0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049d4:	6b85                	lui	s7,0x1
    800049d6:	c00b8b9b          	addiw	s7,s7,-1024
    800049da:	a851                	j	80004a6e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049dc:	6908                	ld	a0,16(a0)
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	254080e7          	jalr	596(ra) # 80004c32 <pipewrite>
    800049e6:	a85d                	j	80004a9c <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049e8:	02451783          	lh	a5,36(a0)
    800049ec:	03079693          	slli	a3,a5,0x30
    800049f0:	92c1                	srli	a3,a3,0x30
    800049f2:	4725                	li	a4,9
    800049f4:	0ed76663          	bltu	a4,a3,80004ae0 <filewrite+0x152>
    800049f8:	0792                	slli	a5,a5,0x4
    800049fa:	0001e717          	auipc	a4,0x1e
    800049fe:	bb670713          	addi	a4,a4,-1098 # 800225b0 <devsw>
    80004a02:	97ba                	add	a5,a5,a4
    80004a04:	679c                	ld	a5,8(a5)
    80004a06:	cff9                	beqz	a5,80004ae4 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a08:	4505                	li	a0,1
    80004a0a:	9782                	jalr	a5
    80004a0c:	a841                	j	80004a9c <filewrite+0x10e>
    80004a0e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	8ae080e7          	jalr	-1874(ra) # 800042c0 <begin_op>
      ilock(f->ip);
    80004a1a:	01893503          	ld	a0,24(s2)
    80004a1e:	fffff097          	auipc	ra,0xfffff
    80004a22:	ee2080e7          	jalr	-286(ra) # 80003900 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a26:	8762                	mv	a4,s8
    80004a28:	02092683          	lw	a3,32(s2)
    80004a2c:	01598633          	add	a2,s3,s5
    80004a30:	4585                	li	a1,1
    80004a32:	01893503          	ld	a0,24(s2)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	274080e7          	jalr	628(ra) # 80003caa <writei>
    80004a3e:	84aa                	mv	s1,a0
    80004a40:	02a05f63          	blez	a0,80004a7e <filewrite+0xf0>
        f->off += r;
    80004a44:	02092783          	lw	a5,32(s2)
    80004a48:	9fa9                	addw	a5,a5,a0
    80004a4a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a4e:	01893503          	ld	a0,24(s2)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	f70080e7          	jalr	-144(ra) # 800039c2 <iunlock>
      end_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	8e6080e7          	jalr	-1818(ra) # 80004340 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a62:	049c1963          	bne	s8,s1,80004ab4 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a66:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a6a:	0349d663          	bge	s3,s4,80004a96 <filewrite+0x108>
      int n1 = n - i;
    80004a6e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a72:	84be                	mv	s1,a5
    80004a74:	2781                	sext.w	a5,a5
    80004a76:	f8fb5ce3          	bge	s6,a5,80004a0e <filewrite+0x80>
    80004a7a:	84de                	mv	s1,s7
    80004a7c:	bf49                	j	80004a0e <filewrite+0x80>
      iunlock(f->ip);
    80004a7e:	01893503          	ld	a0,24(s2)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	f40080e7          	jalr	-192(ra) # 800039c2 <iunlock>
      end_op();
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	8b6080e7          	jalr	-1866(ra) # 80004340 <end_op>
      if(r < 0)
    80004a92:	fc04d8e3          	bgez	s1,80004a62 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a96:	8552                	mv	a0,s4
    80004a98:	033a1863          	bne	s4,s3,80004ac8 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a9c:	60a6                	ld	ra,72(sp)
    80004a9e:	6406                	ld	s0,64(sp)
    80004aa0:	74e2                	ld	s1,56(sp)
    80004aa2:	7942                	ld	s2,48(sp)
    80004aa4:	79a2                	ld	s3,40(sp)
    80004aa6:	7a02                	ld	s4,32(sp)
    80004aa8:	6ae2                	ld	s5,24(sp)
    80004aaa:	6b42                	ld	s6,16(sp)
    80004aac:	6ba2                	ld	s7,8(sp)
    80004aae:	6c02                	ld	s8,0(sp)
    80004ab0:	6161                	addi	sp,sp,80
    80004ab2:	8082                	ret
        panic("short filewrite");
    80004ab4:	00004517          	auipc	a0,0x4
    80004ab8:	c4450513          	addi	a0,a0,-956 # 800086f8 <syscalls+0x268>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	a84080e7          	jalr	-1404(ra) # 80000540 <panic>
    int i = 0;
    80004ac4:	4981                	li	s3,0
    80004ac6:	bfc1                	j	80004a96 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004ac8:	557d                	li	a0,-1
    80004aca:	bfc9                	j	80004a9c <filewrite+0x10e>
    panic("filewrite");
    80004acc:	00004517          	auipc	a0,0x4
    80004ad0:	c3c50513          	addi	a0,a0,-964 # 80008708 <syscalls+0x278>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	a6c080e7          	jalr	-1428(ra) # 80000540 <panic>
    return -1;
    80004adc:	557d                	li	a0,-1
}
    80004ade:	8082                	ret
      return -1;
    80004ae0:	557d                	li	a0,-1
    80004ae2:	bf6d                	j	80004a9c <filewrite+0x10e>
    80004ae4:	557d                	li	a0,-1
    80004ae6:	bf5d                	j	80004a9c <filewrite+0x10e>

0000000080004ae8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ae8:	7179                	addi	sp,sp,-48
    80004aea:	f406                	sd	ra,40(sp)
    80004aec:	f022                	sd	s0,32(sp)
    80004aee:	ec26                	sd	s1,24(sp)
    80004af0:	e84a                	sd	s2,16(sp)
    80004af2:	e44e                	sd	s3,8(sp)
    80004af4:	e052                	sd	s4,0(sp)
    80004af6:	1800                	addi	s0,sp,48
    80004af8:	84aa                	mv	s1,a0
    80004afa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004afc:	0005b023          	sd	zero,0(a1)
    80004b00:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b04:	00000097          	auipc	ra,0x0
    80004b08:	bd2080e7          	jalr	-1070(ra) # 800046d6 <filealloc>
    80004b0c:	e088                	sd	a0,0(s1)
    80004b0e:	c551                	beqz	a0,80004b9a <pipealloc+0xb2>
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	bc6080e7          	jalr	-1082(ra) # 800046d6 <filealloc>
    80004b18:	00aa3023          	sd	a0,0(s4)
    80004b1c:	c92d                	beqz	a0,80004b8e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	fee080e7          	jalr	-18(ra) # 80000b0c <kalloc>
    80004b26:	892a                	mv	s2,a0
    80004b28:	c125                	beqz	a0,80004b88 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b2a:	4985                	li	s3,1
    80004b2c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b30:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b34:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b38:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b3c:	00004597          	auipc	a1,0x4
    80004b40:	bdc58593          	addi	a1,a1,-1060 # 80008718 <syscalls+0x288>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	028080e7          	jalr	40(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004b4c:	609c                	ld	a5,0(s1)
    80004b4e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b52:	609c                	ld	a5,0(s1)
    80004b54:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b58:	609c                	ld	a5,0(s1)
    80004b5a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b5e:	609c                	ld	a5,0(s1)
    80004b60:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b64:	000a3783          	ld	a5,0(s4)
    80004b68:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b6c:	000a3783          	ld	a5,0(s4)
    80004b70:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b74:	000a3783          	ld	a5,0(s4)
    80004b78:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b7c:	000a3783          	ld	a5,0(s4)
    80004b80:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b84:	4501                	li	a0,0
    80004b86:	a025                	j	80004bae <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b88:	6088                	ld	a0,0(s1)
    80004b8a:	e501                	bnez	a0,80004b92 <pipealloc+0xaa>
    80004b8c:	a039                	j	80004b9a <pipealloc+0xb2>
    80004b8e:	6088                	ld	a0,0(s1)
    80004b90:	c51d                	beqz	a0,80004bbe <pipealloc+0xd6>
    fileclose(*f0);
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	c00080e7          	jalr	-1024(ra) # 80004792 <fileclose>
  if(*f1)
    80004b9a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b9e:	557d                	li	a0,-1
  if(*f1)
    80004ba0:	c799                	beqz	a5,80004bae <pipealloc+0xc6>
    fileclose(*f1);
    80004ba2:	853e                	mv	a0,a5
    80004ba4:	00000097          	auipc	ra,0x0
    80004ba8:	bee080e7          	jalr	-1042(ra) # 80004792 <fileclose>
  return -1;
    80004bac:	557d                	li	a0,-1
}
    80004bae:	70a2                	ld	ra,40(sp)
    80004bb0:	7402                	ld	s0,32(sp)
    80004bb2:	64e2                	ld	s1,24(sp)
    80004bb4:	6942                	ld	s2,16(sp)
    80004bb6:	69a2                	ld	s3,8(sp)
    80004bb8:	6a02                	ld	s4,0(sp)
    80004bba:	6145                	addi	sp,sp,48
    80004bbc:	8082                	ret
  return -1;
    80004bbe:	557d                	li	a0,-1
    80004bc0:	b7fd                	j	80004bae <pipealloc+0xc6>

0000000080004bc2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bc2:	1101                	addi	sp,sp,-32
    80004bc4:	ec06                	sd	ra,24(sp)
    80004bc6:	e822                	sd	s0,16(sp)
    80004bc8:	e426                	sd	s1,8(sp)
    80004bca:	e04a                	sd	s2,0(sp)
    80004bcc:	1000                	addi	s0,sp,32
    80004bce:	84aa                	mv	s1,a0
    80004bd0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	02a080e7          	jalr	42(ra) # 80000bfc <acquire>
  if(writable){
    80004bda:	02090d63          	beqz	s2,80004c14 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bde:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004be2:	21848513          	addi	a0,s1,536
    80004be6:	ffffe097          	auipc	ra,0xffffe
    80004bea:	a52080e7          	jalr	-1454(ra) # 80002638 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bee:	2204b783          	ld	a5,544(s1)
    80004bf2:	eb95                	bnez	a5,80004c26 <pipeclose+0x64>
    release(&pi->lock);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	0ba080e7          	jalr	186(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	e10080e7          	jalr	-496(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c08:	60e2                	ld	ra,24(sp)
    80004c0a:	6442                	ld	s0,16(sp)
    80004c0c:	64a2                	ld	s1,8(sp)
    80004c0e:	6902                	ld	s2,0(sp)
    80004c10:	6105                	addi	sp,sp,32
    80004c12:	8082                	ret
    pi->readopen = 0;
    80004c14:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c18:	21c48513          	addi	a0,s1,540
    80004c1c:	ffffe097          	auipc	ra,0xffffe
    80004c20:	a1c080e7          	jalr	-1508(ra) # 80002638 <wakeup>
    80004c24:	b7e9                	j	80004bee <pipeclose+0x2c>
    release(&pi->lock);
    80004c26:	8526                	mv	a0,s1
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	088080e7          	jalr	136(ra) # 80000cb0 <release>
}
    80004c30:	bfe1                	j	80004c08 <pipeclose+0x46>

0000000080004c32 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c32:	711d                	addi	sp,sp,-96
    80004c34:	ec86                	sd	ra,88(sp)
    80004c36:	e8a2                	sd	s0,80(sp)
    80004c38:	e4a6                	sd	s1,72(sp)
    80004c3a:	e0ca                	sd	s2,64(sp)
    80004c3c:	fc4e                	sd	s3,56(sp)
    80004c3e:	f852                	sd	s4,48(sp)
    80004c40:	f456                	sd	s5,40(sp)
    80004c42:	f05a                	sd	s6,32(sp)
    80004c44:	ec5e                	sd	s7,24(sp)
    80004c46:	e862                	sd	s8,16(sp)
    80004c48:	1080                	addi	s0,sp,96
    80004c4a:	84aa                	mv	s1,a0
    80004c4c:	8b2e                	mv	s6,a1
    80004c4e:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	e9a080e7          	jalr	-358(ra) # 80001aea <myproc>
    80004c58:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	fa0080e7          	jalr	-96(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004c64:	09505763          	blez	s5,80004cf2 <pipewrite+0xc0>
    80004c68:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c6a:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c6e:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c72:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c74:	2184a783          	lw	a5,536(s1)
    80004c78:	21c4a703          	lw	a4,540(s1)
    80004c7c:	2007879b          	addiw	a5,a5,512
    80004c80:	02f71b63          	bne	a4,a5,80004cb6 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004c84:	2204a783          	lw	a5,544(s1)
    80004c88:	c3d1                	beqz	a5,80004d0c <pipewrite+0xda>
    80004c8a:	03092783          	lw	a5,48(s2)
    80004c8e:	efbd                	bnez	a5,80004d0c <pipewrite+0xda>
      wakeup(&pi->nread);
    80004c90:	8552                	mv	a0,s4
    80004c92:	ffffe097          	auipc	ra,0xffffe
    80004c96:	9a6080e7          	jalr	-1626(ra) # 80002638 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c9a:	85a6                	mv	a1,s1
    80004c9c:	854e                	mv	a0,s3
    80004c9e:	ffffe097          	auipc	ra,0xffffe
    80004ca2:	80e080e7          	jalr	-2034(ra) # 800024ac <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ca6:	2184a783          	lw	a5,536(s1)
    80004caa:	21c4a703          	lw	a4,540(s1)
    80004cae:	2007879b          	addiw	a5,a5,512
    80004cb2:	fcf709e3          	beq	a4,a5,80004c84 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb6:	4685                	li	a3,1
    80004cb8:	865a                	mv	a2,s6
    80004cba:	faf40593          	addi	a1,s0,-81
    80004cbe:	05093503          	ld	a0,80(s2)
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	a74080e7          	jalr	-1420(ra) # 80001736 <copyin>
    80004cca:	03850563          	beq	a0,s8,80004cf4 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cce:	21c4a783          	lw	a5,540(s1)
    80004cd2:	0017871b          	addiw	a4,a5,1
    80004cd6:	20e4ae23          	sw	a4,540(s1)
    80004cda:	1ff7f793          	andi	a5,a5,511
    80004cde:	97a6                	add	a5,a5,s1
    80004ce0:	faf44703          	lbu	a4,-81(s0)
    80004ce4:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ce8:	2b85                	addiw	s7,s7,1
    80004cea:	0b05                	addi	s6,s6,1
    80004cec:	f97a94e3          	bne	s5,s7,80004c74 <pipewrite+0x42>
    80004cf0:	a011                	j	80004cf4 <pipewrite+0xc2>
    80004cf2:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004cf4:	21848513          	addi	a0,s1,536
    80004cf8:	ffffe097          	auipc	ra,0xffffe
    80004cfc:	940080e7          	jalr	-1728(ra) # 80002638 <wakeup>
  release(&pi->lock);
    80004d00:	8526                	mv	a0,s1
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	fae080e7          	jalr	-82(ra) # 80000cb0 <release>
  return i;
    80004d0a:	a039                	j	80004d18 <pipewrite+0xe6>
        release(&pi->lock);
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	fa2080e7          	jalr	-94(ra) # 80000cb0 <release>
        return -1;
    80004d16:	5bfd                	li	s7,-1
}
    80004d18:	855e                	mv	a0,s7
    80004d1a:	60e6                	ld	ra,88(sp)
    80004d1c:	6446                	ld	s0,80(sp)
    80004d1e:	64a6                	ld	s1,72(sp)
    80004d20:	6906                	ld	s2,64(sp)
    80004d22:	79e2                	ld	s3,56(sp)
    80004d24:	7a42                	ld	s4,48(sp)
    80004d26:	7aa2                	ld	s5,40(sp)
    80004d28:	7b02                	ld	s6,32(sp)
    80004d2a:	6be2                	ld	s7,24(sp)
    80004d2c:	6c42                	ld	s8,16(sp)
    80004d2e:	6125                	addi	sp,sp,96
    80004d30:	8082                	ret

0000000080004d32 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d32:	715d                	addi	sp,sp,-80
    80004d34:	e486                	sd	ra,72(sp)
    80004d36:	e0a2                	sd	s0,64(sp)
    80004d38:	fc26                	sd	s1,56(sp)
    80004d3a:	f84a                	sd	s2,48(sp)
    80004d3c:	f44e                	sd	s3,40(sp)
    80004d3e:	f052                	sd	s4,32(sp)
    80004d40:	ec56                	sd	s5,24(sp)
    80004d42:	e85a                	sd	s6,16(sp)
    80004d44:	0880                	addi	s0,sp,80
    80004d46:	84aa                	mv	s1,a0
    80004d48:	892e                	mv	s2,a1
    80004d4a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	d9e080e7          	jalr	-610(ra) # 80001aea <myproc>
    80004d54:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	ea4080e7          	jalr	-348(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d60:	2184a703          	lw	a4,536(s1)
    80004d64:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d68:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d6c:	02f71463          	bne	a4,a5,80004d94 <piperead+0x62>
    80004d70:	2244a783          	lw	a5,548(s1)
    80004d74:	c385                	beqz	a5,80004d94 <piperead+0x62>
    if(pr->killed){
    80004d76:	030a2783          	lw	a5,48(s4)
    80004d7a:	ebc1                	bnez	a5,80004e0a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d7c:	85a6                	mv	a1,s1
    80004d7e:	854e                	mv	a0,s3
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	72c080e7          	jalr	1836(ra) # 800024ac <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d88:	2184a703          	lw	a4,536(s1)
    80004d8c:	21c4a783          	lw	a5,540(s1)
    80004d90:	fef700e3          	beq	a4,a5,80004d70 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d94:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d96:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d98:	05505363          	blez	s5,80004dde <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d9c:	2184a783          	lw	a5,536(s1)
    80004da0:	21c4a703          	lw	a4,540(s1)
    80004da4:	02f70d63          	beq	a4,a5,80004dde <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004da8:	0017871b          	addiw	a4,a5,1
    80004dac:	20e4ac23          	sw	a4,536(s1)
    80004db0:	1ff7f793          	andi	a5,a5,511
    80004db4:	97a6                	add	a5,a5,s1
    80004db6:	0187c783          	lbu	a5,24(a5)
    80004dba:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dbe:	4685                	li	a3,1
    80004dc0:	fbf40613          	addi	a2,s0,-65
    80004dc4:	85ca                	mv	a1,s2
    80004dc6:	050a3503          	ld	a0,80(s4)
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	8e0080e7          	jalr	-1824(ra) # 800016aa <copyout>
    80004dd2:	01650663          	beq	a0,s6,80004dde <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd6:	2985                	addiw	s3,s3,1
    80004dd8:	0905                	addi	s2,s2,1
    80004dda:	fd3a91e3          	bne	s5,s3,80004d9c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dde:	21c48513          	addi	a0,s1,540
    80004de2:	ffffe097          	auipc	ra,0xffffe
    80004de6:	856080e7          	jalr	-1962(ra) # 80002638 <wakeup>
  release(&pi->lock);
    80004dea:	8526                	mv	a0,s1
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	ec4080e7          	jalr	-316(ra) # 80000cb0 <release>
  return i;
}
    80004df4:	854e                	mv	a0,s3
    80004df6:	60a6                	ld	ra,72(sp)
    80004df8:	6406                	ld	s0,64(sp)
    80004dfa:	74e2                	ld	s1,56(sp)
    80004dfc:	7942                	ld	s2,48(sp)
    80004dfe:	79a2                	ld	s3,40(sp)
    80004e00:	7a02                	ld	s4,32(sp)
    80004e02:	6ae2                	ld	s5,24(sp)
    80004e04:	6b42                	ld	s6,16(sp)
    80004e06:	6161                	addi	sp,sp,80
    80004e08:	8082                	ret
      release(&pi->lock);
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	ea4080e7          	jalr	-348(ra) # 80000cb0 <release>
      return -1;
    80004e14:	59fd                	li	s3,-1
    80004e16:	bff9                	j	80004df4 <piperead+0xc2>

0000000080004e18 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e18:	de010113          	addi	sp,sp,-544
    80004e1c:	20113c23          	sd	ra,536(sp)
    80004e20:	20813823          	sd	s0,528(sp)
    80004e24:	20913423          	sd	s1,520(sp)
    80004e28:	21213023          	sd	s2,512(sp)
    80004e2c:	ffce                	sd	s3,504(sp)
    80004e2e:	fbd2                	sd	s4,496(sp)
    80004e30:	f7d6                	sd	s5,488(sp)
    80004e32:	f3da                	sd	s6,480(sp)
    80004e34:	efde                	sd	s7,472(sp)
    80004e36:	ebe2                	sd	s8,464(sp)
    80004e38:	e7e6                	sd	s9,456(sp)
    80004e3a:	e3ea                	sd	s10,448(sp)
    80004e3c:	ff6e                	sd	s11,440(sp)
    80004e3e:	1400                	addi	s0,sp,544
    80004e40:	892a                	mv	s2,a0
    80004e42:	dea43423          	sd	a0,-536(s0)
    80004e46:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	ca0080e7          	jalr	-864(ra) # 80001aea <myproc>
    80004e52:	84aa                	mv	s1,a0

  begin_op();
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	46c080e7          	jalr	1132(ra) # 800042c0 <begin_op>

  if((ip = namei(path)) == 0){
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	252080e7          	jalr	594(ra) # 800040b0 <namei>
    80004e66:	c93d                	beqz	a0,80004edc <exec+0xc4>
    80004e68:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e6a:	fffff097          	auipc	ra,0xfffff
    80004e6e:	a96080e7          	jalr	-1386(ra) # 80003900 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e72:	04000713          	li	a4,64
    80004e76:	4681                	li	a3,0
    80004e78:	e4840613          	addi	a2,s0,-440
    80004e7c:	4581                	li	a1,0
    80004e7e:	8556                	mv	a0,s5
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	d34080e7          	jalr	-716(ra) # 80003bb4 <readi>
    80004e88:	04000793          	li	a5,64
    80004e8c:	00f51a63          	bne	a0,a5,80004ea0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e90:	e4842703          	lw	a4,-440(s0)
    80004e94:	464c47b7          	lui	a5,0x464c4
    80004e98:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e9c:	04f70663          	beq	a4,a5,80004ee8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ea0:	8556                	mv	a0,s5
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	cc0080e7          	jalr	-832(ra) # 80003b62 <iunlockput>
    end_op();
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	496080e7          	jalr	1174(ra) # 80004340 <end_op>
  }
  return -1;
    80004eb2:	557d                	li	a0,-1
}
    80004eb4:	21813083          	ld	ra,536(sp)
    80004eb8:	21013403          	ld	s0,528(sp)
    80004ebc:	20813483          	ld	s1,520(sp)
    80004ec0:	20013903          	ld	s2,512(sp)
    80004ec4:	79fe                	ld	s3,504(sp)
    80004ec6:	7a5e                	ld	s4,496(sp)
    80004ec8:	7abe                	ld	s5,488(sp)
    80004eca:	7b1e                	ld	s6,480(sp)
    80004ecc:	6bfe                	ld	s7,472(sp)
    80004ece:	6c5e                	ld	s8,464(sp)
    80004ed0:	6cbe                	ld	s9,456(sp)
    80004ed2:	6d1e                	ld	s10,448(sp)
    80004ed4:	7dfa                	ld	s11,440(sp)
    80004ed6:	22010113          	addi	sp,sp,544
    80004eda:	8082                	ret
    end_op();
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	464080e7          	jalr	1124(ra) # 80004340 <end_op>
    return -1;
    80004ee4:	557d                	li	a0,-1
    80004ee6:	b7f9                	j	80004eb4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	cc6080e7          	jalr	-826(ra) # 80001bb0 <proc_pagetable>
    80004ef2:	8b2a                	mv	s6,a0
    80004ef4:	d555                	beqz	a0,80004ea0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef6:	e6842783          	lw	a5,-408(s0)
    80004efa:	e8045703          	lhu	a4,-384(s0)
    80004efe:	c735                	beqz	a4,80004f6a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f00:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f02:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f06:	6a05                	lui	s4,0x1
    80004f08:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f0c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f10:	6d85                	lui	s11,0x1
    80004f12:	7d7d                	lui	s10,0xfffff
    80004f14:	ac1d                	j	8000514a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f16:	00004517          	auipc	a0,0x4
    80004f1a:	80a50513          	addi	a0,a0,-2038 # 80008720 <syscalls+0x290>
    80004f1e:	ffffb097          	auipc	ra,0xffffb
    80004f22:	622080e7          	jalr	1570(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f26:	874a                	mv	a4,s2
    80004f28:	009c86bb          	addw	a3,s9,s1
    80004f2c:	4581                	li	a1,0
    80004f2e:	8556                	mv	a0,s5
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	c84080e7          	jalr	-892(ra) # 80003bb4 <readi>
    80004f38:	2501                	sext.w	a0,a0
    80004f3a:	1aa91863          	bne	s2,a0,800050ea <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f3e:	009d84bb          	addw	s1,s11,s1
    80004f42:	013d09bb          	addw	s3,s10,s3
    80004f46:	1f74f263          	bgeu	s1,s7,8000512a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f4a:	02049593          	slli	a1,s1,0x20
    80004f4e:	9181                	srli	a1,a1,0x20
    80004f50:	95e2                	add	a1,a1,s8
    80004f52:	855a                	mv	a0,s6
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	122080e7          	jalr	290(ra) # 80001076 <walkaddr>
    80004f5c:	862a                	mv	a2,a0
    if(pa == 0)
    80004f5e:	dd45                	beqz	a0,80004f16 <exec+0xfe>
      n = PGSIZE;
    80004f60:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f62:	fd49f2e3          	bgeu	s3,s4,80004f26 <exec+0x10e>
      n = sz - i;
    80004f66:	894e                	mv	s2,s3
    80004f68:	bf7d                	j	80004f26 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f6a:	4481                	li	s1,0
  iunlockput(ip);
    80004f6c:	8556                	mv	a0,s5
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	bf4080e7          	jalr	-1036(ra) # 80003b62 <iunlockput>
  end_op();
    80004f76:	fffff097          	auipc	ra,0xfffff
    80004f7a:	3ca080e7          	jalr	970(ra) # 80004340 <end_op>
  p = myproc();
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	b6c080e7          	jalr	-1172(ra) # 80001aea <myproc>
    80004f86:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f88:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f8c:	6785                	lui	a5,0x1
    80004f8e:	17fd                	addi	a5,a5,-1
    80004f90:	94be                	add	s1,s1,a5
    80004f92:	77fd                	lui	a5,0xfffff
    80004f94:	8fe5                	and	a5,a5,s1
    80004f96:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f9a:	6609                	lui	a2,0x2
    80004f9c:	963e                	add	a2,a2,a5
    80004f9e:	85be                	mv	a1,a5
    80004fa0:	855a                	mv	a0,s6
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	4b8080e7          	jalr	1208(ra) # 8000145a <uvmalloc>
    80004faa:	8c2a                	mv	s8,a0
  ip = 0;
    80004fac:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fae:	12050e63          	beqz	a0,800050ea <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fb2:	75f9                	lui	a1,0xffffe
    80004fb4:	95aa                	add	a1,a1,a0
    80004fb6:	855a                	mv	a0,s6
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	6c0080e7          	jalr	1728(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fc0:	7afd                	lui	s5,0xfffff
    80004fc2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fc4:	df043783          	ld	a5,-528(s0)
    80004fc8:	6388                	ld	a0,0(a5)
    80004fca:	c925                	beqz	a0,8000503a <exec+0x222>
    80004fcc:	e8840993          	addi	s3,s0,-376
    80004fd0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fd4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	ea4080e7          	jalr	-348(ra) # 80000e7c <strlen>
    80004fe0:	0015079b          	addiw	a5,a0,1
    80004fe4:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fe8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fec:	13596363          	bltu	s2,s5,80005112 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ff0:	df043d83          	ld	s11,-528(s0)
    80004ff4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004ff8:	8552                	mv	a0,s4
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	e82080e7          	jalr	-382(ra) # 80000e7c <strlen>
    80005002:	0015069b          	addiw	a3,a0,1
    80005006:	8652                	mv	a2,s4
    80005008:	85ca                	mv	a1,s2
    8000500a:	855a                	mv	a0,s6
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	69e080e7          	jalr	1694(ra) # 800016aa <copyout>
    80005014:	10054363          	bltz	a0,8000511a <exec+0x302>
    ustack[argc] = sp;
    80005018:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000501c:	0485                	addi	s1,s1,1
    8000501e:	008d8793          	addi	a5,s11,8
    80005022:	def43823          	sd	a5,-528(s0)
    80005026:	008db503          	ld	a0,8(s11)
    8000502a:	c911                	beqz	a0,8000503e <exec+0x226>
    if(argc >= MAXARG)
    8000502c:	09a1                	addi	s3,s3,8
    8000502e:	fb3c95e3          	bne	s9,s3,80004fd8 <exec+0x1c0>
  sz = sz1;
    80005032:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005036:	4a81                	li	s5,0
    80005038:	a84d                	j	800050ea <exec+0x2d2>
  sp = sz;
    8000503a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000503c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000503e:	00349793          	slli	a5,s1,0x3
    80005042:	f9040713          	addi	a4,s0,-112
    80005046:	97ba                	add	a5,a5,a4
    80005048:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000504c:	00148693          	addi	a3,s1,1
    80005050:	068e                	slli	a3,a3,0x3
    80005052:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005056:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000505a:	01597663          	bgeu	s2,s5,80005066 <exec+0x24e>
  sz = sz1;
    8000505e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005062:	4a81                	li	s5,0
    80005064:	a059                	j	800050ea <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005066:	e8840613          	addi	a2,s0,-376
    8000506a:	85ca                	mv	a1,s2
    8000506c:	855a                	mv	a0,s6
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	63c080e7          	jalr	1596(ra) # 800016aa <copyout>
    80005076:	0a054663          	bltz	a0,80005122 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000507a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000507e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005082:	de843783          	ld	a5,-536(s0)
    80005086:	0007c703          	lbu	a4,0(a5)
    8000508a:	cf11                	beqz	a4,800050a6 <exec+0x28e>
    8000508c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000508e:	02f00693          	li	a3,47
    80005092:	a039                	j	800050a0 <exec+0x288>
      last = s+1;
    80005094:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005098:	0785                	addi	a5,a5,1
    8000509a:	fff7c703          	lbu	a4,-1(a5)
    8000509e:	c701                	beqz	a4,800050a6 <exec+0x28e>
    if(*s == '/')
    800050a0:	fed71ce3          	bne	a4,a3,80005098 <exec+0x280>
    800050a4:	bfc5                	j	80005094 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a6:	4641                	li	a2,16
    800050a8:	de843583          	ld	a1,-536(s0)
    800050ac:	158b8513          	addi	a0,s7,344
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	d9a080e7          	jalr	-614(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    800050b8:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050bc:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050c0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050c4:	058bb783          	ld	a5,88(s7)
    800050c8:	e6043703          	ld	a4,-416(s0)
    800050cc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ce:	058bb783          	ld	a5,88(s7)
    800050d2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d6:	85ea                	mv	a1,s10
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	b74080e7          	jalr	-1164(ra) # 80001c4c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050e0:	0004851b          	sext.w	a0,s1
    800050e4:	bbc1                	j	80004eb4 <exec+0x9c>
    800050e6:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050ea:	df843583          	ld	a1,-520(s0)
    800050ee:	855a                	mv	a0,s6
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	b5c080e7          	jalr	-1188(ra) # 80001c4c <proc_freepagetable>
  if(ip){
    800050f8:	da0a94e3          	bnez	s5,80004ea0 <exec+0x88>
  return -1;
    800050fc:	557d                	li	a0,-1
    800050fe:	bb5d                	j	80004eb4 <exec+0x9c>
    80005100:	de943c23          	sd	s1,-520(s0)
    80005104:	b7dd                	j	800050ea <exec+0x2d2>
    80005106:	de943c23          	sd	s1,-520(s0)
    8000510a:	b7c5                	j	800050ea <exec+0x2d2>
    8000510c:	de943c23          	sd	s1,-520(s0)
    80005110:	bfe9                	j	800050ea <exec+0x2d2>
  sz = sz1;
    80005112:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005116:	4a81                	li	s5,0
    80005118:	bfc9                	j	800050ea <exec+0x2d2>
  sz = sz1;
    8000511a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511e:	4a81                	li	s5,0
    80005120:	b7e9                	j	800050ea <exec+0x2d2>
  sz = sz1;
    80005122:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005126:	4a81                	li	s5,0
    80005128:	b7c9                	j	800050ea <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512e:	e0843783          	ld	a5,-504(s0)
    80005132:	0017869b          	addiw	a3,a5,1
    80005136:	e0d43423          	sd	a3,-504(s0)
    8000513a:	e0043783          	ld	a5,-512(s0)
    8000513e:	0387879b          	addiw	a5,a5,56
    80005142:	e8045703          	lhu	a4,-384(s0)
    80005146:	e2e6d3e3          	bge	a3,a4,80004f6c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000514a:	2781                	sext.w	a5,a5
    8000514c:	e0f43023          	sd	a5,-512(s0)
    80005150:	03800713          	li	a4,56
    80005154:	86be                	mv	a3,a5
    80005156:	e1040613          	addi	a2,s0,-496
    8000515a:	4581                	li	a1,0
    8000515c:	8556                	mv	a0,s5
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	a56080e7          	jalr	-1450(ra) # 80003bb4 <readi>
    80005166:	03800793          	li	a5,56
    8000516a:	f6f51ee3          	bne	a0,a5,800050e6 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000516e:	e1042783          	lw	a5,-496(s0)
    80005172:	4705                	li	a4,1
    80005174:	fae79de3          	bne	a5,a4,8000512e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005178:	e3843603          	ld	a2,-456(s0)
    8000517c:	e3043783          	ld	a5,-464(s0)
    80005180:	f8f660e3          	bltu	a2,a5,80005100 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005184:	e2043783          	ld	a5,-480(s0)
    80005188:	963e                	add	a2,a2,a5
    8000518a:	f6f66ee3          	bltu	a2,a5,80005106 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518e:	85a6                	mv	a1,s1
    80005190:	855a                	mv	a0,s6
    80005192:	ffffc097          	auipc	ra,0xffffc
    80005196:	2c8080e7          	jalr	712(ra) # 8000145a <uvmalloc>
    8000519a:	dea43c23          	sd	a0,-520(s0)
    8000519e:	d53d                	beqz	a0,8000510c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800051a0:	e2043c03          	ld	s8,-480(s0)
    800051a4:	de043783          	ld	a5,-544(s0)
    800051a8:	00fc77b3          	and	a5,s8,a5
    800051ac:	ff9d                	bnez	a5,800050ea <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051ae:	e1842c83          	lw	s9,-488(s0)
    800051b2:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051b6:	f60b8ae3          	beqz	s7,8000512a <exec+0x312>
    800051ba:	89de                	mv	s3,s7
    800051bc:	4481                	li	s1,0
    800051be:	b371                	j	80004f4a <exec+0x132>

00000000800051c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051c0:	7179                	addi	sp,sp,-48
    800051c2:	f406                	sd	ra,40(sp)
    800051c4:	f022                	sd	s0,32(sp)
    800051c6:	ec26                	sd	s1,24(sp)
    800051c8:	e84a                	sd	s2,16(sp)
    800051ca:	1800                	addi	s0,sp,48
    800051cc:	892e                	mv	s2,a1
    800051ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051d0:	fdc40593          	addi	a1,s0,-36
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	bb4080e7          	jalr	-1100(ra) # 80002d88 <argint>
    800051dc:	04054063          	bltz	a0,8000521c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051e0:	fdc42703          	lw	a4,-36(s0)
    800051e4:	47bd                	li	a5,15
    800051e6:	02e7ed63          	bltu	a5,a4,80005220 <argfd+0x60>
    800051ea:	ffffd097          	auipc	ra,0xffffd
    800051ee:	900080e7          	jalr	-1792(ra) # 80001aea <myproc>
    800051f2:	fdc42703          	lw	a4,-36(s0)
    800051f6:	01a70793          	addi	a5,a4,26
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	953e                	add	a0,a0,a5
    800051fe:	611c                	ld	a5,0(a0)
    80005200:	c395                	beqz	a5,80005224 <argfd+0x64>
    return -1;
  if(pfd)
    80005202:	00090463          	beqz	s2,8000520a <argfd+0x4a>
    *pfd = fd;
    80005206:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000520a:	4501                	li	a0,0
  if(pf)
    8000520c:	c091                	beqz	s1,80005210 <argfd+0x50>
    *pf = f;
    8000520e:	e09c                	sd	a5,0(s1)
}
    80005210:	70a2                	ld	ra,40(sp)
    80005212:	7402                	ld	s0,32(sp)
    80005214:	64e2                	ld	s1,24(sp)
    80005216:	6942                	ld	s2,16(sp)
    80005218:	6145                	addi	sp,sp,48
    8000521a:	8082                	ret
    return -1;
    8000521c:	557d                	li	a0,-1
    8000521e:	bfcd                	j	80005210 <argfd+0x50>
    return -1;
    80005220:	557d                	li	a0,-1
    80005222:	b7fd                	j	80005210 <argfd+0x50>
    80005224:	557d                	li	a0,-1
    80005226:	b7ed                	j	80005210 <argfd+0x50>

0000000080005228 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005228:	1101                	addi	sp,sp,-32
    8000522a:	ec06                	sd	ra,24(sp)
    8000522c:	e822                	sd	s0,16(sp)
    8000522e:	e426                	sd	s1,8(sp)
    80005230:	1000                	addi	s0,sp,32
    80005232:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005234:	ffffd097          	auipc	ra,0xffffd
    80005238:	8b6080e7          	jalr	-1866(ra) # 80001aea <myproc>
    8000523c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000523e:	0d050793          	addi	a5,a0,208
    80005242:	4501                	li	a0,0
    80005244:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005246:	6398                	ld	a4,0(a5)
    80005248:	cb19                	beqz	a4,8000525e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000524a:	2505                	addiw	a0,a0,1
    8000524c:	07a1                	addi	a5,a5,8
    8000524e:	fed51ce3          	bne	a0,a3,80005246 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005252:	557d                	li	a0,-1
}
    80005254:	60e2                	ld	ra,24(sp)
    80005256:	6442                	ld	s0,16(sp)
    80005258:	64a2                	ld	s1,8(sp)
    8000525a:	6105                	addi	sp,sp,32
    8000525c:	8082                	ret
      p->ofile[fd] = f;
    8000525e:	01a50793          	addi	a5,a0,26
    80005262:	078e                	slli	a5,a5,0x3
    80005264:	963e                	add	a2,a2,a5
    80005266:	e204                	sd	s1,0(a2)
      return fd;
    80005268:	b7f5                	j	80005254 <fdalloc+0x2c>

000000008000526a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000526a:	715d                	addi	sp,sp,-80
    8000526c:	e486                	sd	ra,72(sp)
    8000526e:	e0a2                	sd	s0,64(sp)
    80005270:	fc26                	sd	s1,56(sp)
    80005272:	f84a                	sd	s2,48(sp)
    80005274:	f44e                	sd	s3,40(sp)
    80005276:	f052                	sd	s4,32(sp)
    80005278:	ec56                	sd	s5,24(sp)
    8000527a:	0880                	addi	s0,sp,80
    8000527c:	89ae                	mv	s3,a1
    8000527e:	8ab2                	mv	s5,a2
    80005280:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005282:	fb040593          	addi	a1,s0,-80
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	e48080e7          	jalr	-440(ra) # 800040ce <nameiparent>
    8000528e:	892a                	mv	s2,a0
    80005290:	12050e63          	beqz	a0,800053cc <create+0x162>
    return 0;

  ilock(dp);
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	66c080e7          	jalr	1644(ra) # 80003900 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000529c:	4601                	li	a2,0
    8000529e:	fb040593          	addi	a1,s0,-80
    800052a2:	854a                	mv	a0,s2
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	b3a080e7          	jalr	-1222(ra) # 80003dde <dirlookup>
    800052ac:	84aa                	mv	s1,a0
    800052ae:	c921                	beqz	a0,800052fe <create+0x94>
    iunlockput(dp);
    800052b0:	854a                	mv	a0,s2
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	8b0080e7          	jalr	-1872(ra) # 80003b62 <iunlockput>
    ilock(ip);
    800052ba:	8526                	mv	a0,s1
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	644080e7          	jalr	1604(ra) # 80003900 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052c4:	2981                	sext.w	s3,s3
    800052c6:	4789                	li	a5,2
    800052c8:	02f99463          	bne	s3,a5,800052f0 <create+0x86>
    800052cc:	0444d783          	lhu	a5,68(s1)
    800052d0:	37f9                	addiw	a5,a5,-2
    800052d2:	17c2                	slli	a5,a5,0x30
    800052d4:	93c1                	srli	a5,a5,0x30
    800052d6:	4705                	li	a4,1
    800052d8:	00f76c63          	bltu	a4,a5,800052f0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052dc:	8526                	mv	a0,s1
    800052de:	60a6                	ld	ra,72(sp)
    800052e0:	6406                	ld	s0,64(sp)
    800052e2:	74e2                	ld	s1,56(sp)
    800052e4:	7942                	ld	s2,48(sp)
    800052e6:	79a2                	ld	s3,40(sp)
    800052e8:	7a02                	ld	s4,32(sp)
    800052ea:	6ae2                	ld	s5,24(sp)
    800052ec:	6161                	addi	sp,sp,80
    800052ee:	8082                	ret
    iunlockput(ip);
    800052f0:	8526                	mv	a0,s1
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	870080e7          	jalr	-1936(ra) # 80003b62 <iunlockput>
    return 0;
    800052fa:	4481                	li	s1,0
    800052fc:	b7c5                	j	800052dc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052fe:	85ce                	mv	a1,s3
    80005300:	00092503          	lw	a0,0(s2)
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	464080e7          	jalr	1124(ra) # 80003768 <ialloc>
    8000530c:	84aa                	mv	s1,a0
    8000530e:	c521                	beqz	a0,80005356 <create+0xec>
  ilock(ip);
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	5f0080e7          	jalr	1520(ra) # 80003900 <ilock>
  ip->major = major;
    80005318:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000531c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005320:	4a05                	li	s4,1
    80005322:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	50e080e7          	jalr	1294(ra) # 80003836 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005330:	2981                	sext.w	s3,s3
    80005332:	03498a63          	beq	s3,s4,80005366 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005336:	40d0                	lw	a2,4(s1)
    80005338:	fb040593          	addi	a1,s0,-80
    8000533c:	854a                	mv	a0,s2
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	cb0080e7          	jalr	-848(ra) # 80003fee <dirlink>
    80005346:	06054b63          	bltz	a0,800053bc <create+0x152>
  iunlockput(dp);
    8000534a:	854a                	mv	a0,s2
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	816080e7          	jalr	-2026(ra) # 80003b62 <iunlockput>
  return ip;
    80005354:	b761                	j	800052dc <create+0x72>
    panic("create: ialloc");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	3ea50513          	addi	a0,a0,1002 # 80008740 <syscalls+0x2b0>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1e2080e7          	jalr	482(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    80005366:	04a95783          	lhu	a5,74(s2)
    8000536a:	2785                	addiw	a5,a5,1
    8000536c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005370:	854a                	mv	a0,s2
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	4c4080e7          	jalr	1220(ra) # 80003836 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000537a:	40d0                	lw	a2,4(s1)
    8000537c:	00003597          	auipc	a1,0x3
    80005380:	3d458593          	addi	a1,a1,980 # 80008750 <syscalls+0x2c0>
    80005384:	8526                	mv	a0,s1
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	c68080e7          	jalr	-920(ra) # 80003fee <dirlink>
    8000538e:	00054f63          	bltz	a0,800053ac <create+0x142>
    80005392:	00492603          	lw	a2,4(s2)
    80005396:	00003597          	auipc	a1,0x3
    8000539a:	3c258593          	addi	a1,a1,962 # 80008758 <syscalls+0x2c8>
    8000539e:	8526                	mv	a0,s1
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	c4e080e7          	jalr	-946(ra) # 80003fee <dirlink>
    800053a8:	f80557e3          	bgez	a0,80005336 <create+0xcc>
      panic("create dots");
    800053ac:	00003517          	auipc	a0,0x3
    800053b0:	3b450513          	addi	a0,a0,948 # 80008760 <syscalls+0x2d0>
    800053b4:	ffffb097          	auipc	ra,0xffffb
    800053b8:	18c080e7          	jalr	396(ra) # 80000540 <panic>
    panic("create: dirlink");
    800053bc:	00003517          	auipc	a0,0x3
    800053c0:	3b450513          	addi	a0,a0,948 # 80008770 <syscalls+0x2e0>
    800053c4:	ffffb097          	auipc	ra,0xffffb
    800053c8:	17c080e7          	jalr	380(ra) # 80000540 <panic>
    return 0;
    800053cc:	84aa                	mv	s1,a0
    800053ce:	b739                	j	800052dc <create+0x72>

00000000800053d0 <sys_dup>:
{
    800053d0:	7179                	addi	sp,sp,-48
    800053d2:	f406                	sd	ra,40(sp)
    800053d4:	f022                	sd	s0,32(sp)
    800053d6:	ec26                	sd	s1,24(sp)
    800053d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053da:	fd840613          	addi	a2,s0,-40
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	dde080e7          	jalr	-546(ra) # 800051c0 <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053ec:	02054363          	bltz	a0,80005412 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053f0:	fd843503          	ld	a0,-40(s0)
    800053f4:	00000097          	auipc	ra,0x0
    800053f8:	e34080e7          	jalr	-460(ra) # 80005228 <fdalloc>
    800053fc:	84aa                	mv	s1,a0
    return -1;
    800053fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005400:	00054963          	bltz	a0,80005412 <sys_dup+0x42>
  filedup(f);
    80005404:	fd843503          	ld	a0,-40(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	338080e7          	jalr	824(ra) # 80004740 <filedup>
  return fd;
    80005410:	87a6                	mv	a5,s1
}
    80005412:	853e                	mv	a0,a5
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	64e2                	ld	s1,24(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_read>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	fe840613          	addi	a2,s0,-24
    8000542a:	4581                	li	a1,0
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	d92080e7          	jalr	-622(ra) # 800051c0 <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	04054163          	bltz	a0,8000547a <sys_read+0x5c>
    8000543c:	fe440593          	addi	a1,s0,-28
    80005440:	4509                	li	a0,2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	946080e7          	jalr	-1722(ra) # 80002d88 <argint>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	02054763          	bltz	a0,8000547a <sys_read+0x5c>
    80005450:	fd840593          	addi	a1,s0,-40
    80005454:	4505                	li	a0,1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	954080e7          	jalr	-1708(ra) # 80002daa <argaddr>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	00054d63          	bltz	a0,8000547a <sys_read+0x5c>
  return fileread(f, p, n);
    80005464:	fe442603          	lw	a2,-28(s0)
    80005468:	fd843583          	ld	a1,-40(s0)
    8000546c:	fe843503          	ld	a0,-24(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	45c080e7          	jalr	1116(ra) # 800048cc <fileread>
    80005478:	87aa                	mv	a5,a0
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_write>:
{
    80005484:	7179                	addi	sp,sp,-48
    80005486:	f406                	sd	ra,40(sp)
    80005488:	f022                	sd	s0,32(sp)
    8000548a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548c:	fe840613          	addi	a2,s0,-24
    80005490:	4581                	li	a1,0
    80005492:	4501                	li	a0,0
    80005494:	00000097          	auipc	ra,0x0
    80005498:	d2c080e7          	jalr	-724(ra) # 800051c0 <argfd>
    return -1;
    8000549c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000549e:	04054163          	bltz	a0,800054e0 <sys_write+0x5c>
    800054a2:	fe440593          	addi	a1,s0,-28
    800054a6:	4509                	li	a0,2
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	8e0080e7          	jalr	-1824(ra) # 80002d88 <argint>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	02054763          	bltz	a0,800054e0 <sys_write+0x5c>
    800054b6:	fd840593          	addi	a1,s0,-40
    800054ba:	4505                	li	a0,1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	8ee080e7          	jalr	-1810(ra) # 80002daa <argaddr>
    return -1;
    800054c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c6:	00054d63          	bltz	a0,800054e0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054ca:	fe442603          	lw	a2,-28(s0)
    800054ce:	fd843583          	ld	a1,-40(s0)
    800054d2:	fe843503          	ld	a0,-24(s0)
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	4b8080e7          	jalr	1208(ra) # 8000498e <filewrite>
    800054de:	87aa                	mv	a5,a0
}
    800054e0:	853e                	mv	a0,a5
    800054e2:	70a2                	ld	ra,40(sp)
    800054e4:	7402                	ld	s0,32(sp)
    800054e6:	6145                	addi	sp,sp,48
    800054e8:	8082                	ret

00000000800054ea <sys_close>:
{
    800054ea:	1101                	addi	sp,sp,-32
    800054ec:	ec06                	sd	ra,24(sp)
    800054ee:	e822                	sd	s0,16(sp)
    800054f0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054f2:	fe040613          	addi	a2,s0,-32
    800054f6:	fec40593          	addi	a1,s0,-20
    800054fa:	4501                	li	a0,0
    800054fc:	00000097          	auipc	ra,0x0
    80005500:	cc4080e7          	jalr	-828(ra) # 800051c0 <argfd>
    return -1;
    80005504:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005506:	02054463          	bltz	a0,8000552e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	5e0080e7          	jalr	1504(ra) # 80001aea <myproc>
    80005512:	fec42783          	lw	a5,-20(s0)
    80005516:	07e9                	addi	a5,a5,26
    80005518:	078e                	slli	a5,a5,0x3
    8000551a:	97aa                	add	a5,a5,a0
    8000551c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005520:	fe043503          	ld	a0,-32(s0)
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	26e080e7          	jalr	622(ra) # 80004792 <fileclose>
  return 0;
    8000552c:	4781                	li	a5,0
}
    8000552e:	853e                	mv	a0,a5
    80005530:	60e2                	ld	ra,24(sp)
    80005532:	6442                	ld	s0,16(sp)
    80005534:	6105                	addi	sp,sp,32
    80005536:	8082                	ret

0000000080005538 <sys_fstat>:
{
    80005538:	1101                	addi	sp,sp,-32
    8000553a:	ec06                	sd	ra,24(sp)
    8000553c:	e822                	sd	s0,16(sp)
    8000553e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005540:	fe840613          	addi	a2,s0,-24
    80005544:	4581                	li	a1,0
    80005546:	4501                	li	a0,0
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	c78080e7          	jalr	-904(ra) # 800051c0 <argfd>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005552:	02054563          	bltz	a0,8000557c <sys_fstat+0x44>
    80005556:	fe040593          	addi	a1,s0,-32
    8000555a:	4505                	li	a0,1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	84e080e7          	jalr	-1970(ra) # 80002daa <argaddr>
    return -1;
    80005564:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005566:	00054b63          	bltz	a0,8000557c <sys_fstat+0x44>
  return filestat(f, st);
    8000556a:	fe043583          	ld	a1,-32(s0)
    8000556e:	fe843503          	ld	a0,-24(s0)
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	2e8080e7          	jalr	744(ra) # 8000485a <filestat>
    8000557a:	87aa                	mv	a5,a0
}
    8000557c:	853e                	mv	a0,a5
    8000557e:	60e2                	ld	ra,24(sp)
    80005580:	6442                	ld	s0,16(sp)
    80005582:	6105                	addi	sp,sp,32
    80005584:	8082                	ret

0000000080005586 <sys_link>:
{
    80005586:	7169                	addi	sp,sp,-304
    80005588:	f606                	sd	ra,296(sp)
    8000558a:	f222                	sd	s0,288(sp)
    8000558c:	ee26                	sd	s1,280(sp)
    8000558e:	ea4a                	sd	s2,272(sp)
    80005590:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005592:	08000613          	li	a2,128
    80005596:	ed040593          	addi	a1,s0,-304
    8000559a:	4501                	li	a0,0
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	830080e7          	jalr	-2000(ra) # 80002dcc <argstr>
    return -1;
    800055a4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a6:	10054e63          	bltz	a0,800056c2 <sys_link+0x13c>
    800055aa:	08000613          	li	a2,128
    800055ae:	f5040593          	addi	a1,s0,-176
    800055b2:	4505                	li	a0,1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	818080e7          	jalr	-2024(ra) # 80002dcc <argstr>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055be:	10054263          	bltz	a0,800056c2 <sys_link+0x13c>
  begin_op();
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	cfe080e7          	jalr	-770(ra) # 800042c0 <begin_op>
  if((ip = namei(old)) == 0){
    800055ca:	ed040513          	addi	a0,s0,-304
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	ae2080e7          	jalr	-1310(ra) # 800040b0 <namei>
    800055d6:	84aa                	mv	s1,a0
    800055d8:	c551                	beqz	a0,80005664 <sys_link+0xde>
  ilock(ip);
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	326080e7          	jalr	806(ra) # 80003900 <ilock>
  if(ip->type == T_DIR){
    800055e2:	04449703          	lh	a4,68(s1)
    800055e6:	4785                	li	a5,1
    800055e8:	08f70463          	beq	a4,a5,80005670 <sys_link+0xea>
  ip->nlink++;
    800055ec:	04a4d783          	lhu	a5,74(s1)
    800055f0:	2785                	addiw	a5,a5,1
    800055f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	23e080e7          	jalr	574(ra) # 80003836 <iupdate>
  iunlock(ip);
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	3c0080e7          	jalr	960(ra) # 800039c2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000560a:	fd040593          	addi	a1,s0,-48
    8000560e:	f5040513          	addi	a0,s0,-176
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	abc080e7          	jalr	-1348(ra) # 800040ce <nameiparent>
    8000561a:	892a                	mv	s2,a0
    8000561c:	c935                	beqz	a0,80005690 <sys_link+0x10a>
  ilock(dp);
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	2e2080e7          	jalr	738(ra) # 80003900 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005626:	00092703          	lw	a4,0(s2)
    8000562a:	409c                	lw	a5,0(s1)
    8000562c:	04f71d63          	bne	a4,a5,80005686 <sys_link+0x100>
    80005630:	40d0                	lw	a2,4(s1)
    80005632:	fd040593          	addi	a1,s0,-48
    80005636:	854a                	mv	a0,s2
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	9b6080e7          	jalr	-1610(ra) # 80003fee <dirlink>
    80005640:	04054363          	bltz	a0,80005686 <sys_link+0x100>
  iunlockput(dp);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	51c080e7          	jalr	1308(ra) # 80003b62 <iunlockput>
  iput(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	46a080e7          	jalr	1130(ra) # 80003aba <iput>
  end_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	ce8080e7          	jalr	-792(ra) # 80004340 <end_op>
  return 0;
    80005660:	4781                	li	a5,0
    80005662:	a085                	j	800056c2 <sys_link+0x13c>
    end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	cdc080e7          	jalr	-804(ra) # 80004340 <end_op>
    return -1;
    8000566c:	57fd                	li	a5,-1
    8000566e:	a891                	j	800056c2 <sys_link+0x13c>
    iunlockput(ip);
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	4f0080e7          	jalr	1264(ra) # 80003b62 <iunlockput>
    end_op();
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	cc6080e7          	jalr	-826(ra) # 80004340 <end_op>
    return -1;
    80005682:	57fd                	li	a5,-1
    80005684:	a83d                	j	800056c2 <sys_link+0x13c>
    iunlockput(dp);
    80005686:	854a                	mv	a0,s2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	4da080e7          	jalr	1242(ra) # 80003b62 <iunlockput>
  ilock(ip);
    80005690:	8526                	mv	a0,s1
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	26e080e7          	jalr	622(ra) # 80003900 <ilock>
  ip->nlink--;
    8000569a:	04a4d783          	lhu	a5,74(s1)
    8000569e:	37fd                	addiw	a5,a5,-1
    800056a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	190080e7          	jalr	400(ra) # 80003836 <iupdate>
  iunlockput(ip);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	4b2080e7          	jalr	1202(ra) # 80003b62 <iunlockput>
  end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	c88080e7          	jalr	-888(ra) # 80004340 <end_op>
  return -1;
    800056c0:	57fd                	li	a5,-1
}
    800056c2:	853e                	mv	a0,a5
    800056c4:	70b2                	ld	ra,296(sp)
    800056c6:	7412                	ld	s0,288(sp)
    800056c8:	64f2                	ld	s1,280(sp)
    800056ca:	6952                	ld	s2,272(sp)
    800056cc:	6155                	addi	sp,sp,304
    800056ce:	8082                	ret

00000000800056d0 <sys_unlink>:
{
    800056d0:	7151                	addi	sp,sp,-240
    800056d2:	f586                	sd	ra,232(sp)
    800056d4:	f1a2                	sd	s0,224(sp)
    800056d6:	eda6                	sd	s1,216(sp)
    800056d8:	e9ca                	sd	s2,208(sp)
    800056da:	e5ce                	sd	s3,200(sp)
    800056dc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056de:	08000613          	li	a2,128
    800056e2:	f3040593          	addi	a1,s0,-208
    800056e6:	4501                	li	a0,0
    800056e8:	ffffd097          	auipc	ra,0xffffd
    800056ec:	6e4080e7          	jalr	1764(ra) # 80002dcc <argstr>
    800056f0:	18054163          	bltz	a0,80005872 <sys_unlink+0x1a2>
  begin_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	bcc080e7          	jalr	-1076(ra) # 800042c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056fc:	fb040593          	addi	a1,s0,-80
    80005700:	f3040513          	addi	a0,s0,-208
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	9ca080e7          	jalr	-1590(ra) # 800040ce <nameiparent>
    8000570c:	84aa                	mv	s1,a0
    8000570e:	c979                	beqz	a0,800057e4 <sys_unlink+0x114>
  ilock(dp);
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	1f0080e7          	jalr	496(ra) # 80003900 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005718:	00003597          	auipc	a1,0x3
    8000571c:	03858593          	addi	a1,a1,56 # 80008750 <syscalls+0x2c0>
    80005720:	fb040513          	addi	a0,s0,-80
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	6a0080e7          	jalr	1696(ra) # 80003dc4 <namecmp>
    8000572c:	14050a63          	beqz	a0,80005880 <sys_unlink+0x1b0>
    80005730:	00003597          	auipc	a1,0x3
    80005734:	02858593          	addi	a1,a1,40 # 80008758 <syscalls+0x2c8>
    80005738:	fb040513          	addi	a0,s0,-80
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	688080e7          	jalr	1672(ra) # 80003dc4 <namecmp>
    80005744:	12050e63          	beqz	a0,80005880 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005748:	f2c40613          	addi	a2,s0,-212
    8000574c:	fb040593          	addi	a1,s0,-80
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	68c080e7          	jalr	1676(ra) # 80003dde <dirlookup>
    8000575a:	892a                	mv	s2,a0
    8000575c:	12050263          	beqz	a0,80005880 <sys_unlink+0x1b0>
  ilock(ip);
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	1a0080e7          	jalr	416(ra) # 80003900 <ilock>
  if(ip->nlink < 1)
    80005768:	04a91783          	lh	a5,74(s2)
    8000576c:	08f05263          	blez	a5,800057f0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005770:	04491703          	lh	a4,68(s2)
    80005774:	4785                	li	a5,1
    80005776:	08f70563          	beq	a4,a5,80005800 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000577a:	4641                	li	a2,16
    8000577c:	4581                	li	a1,0
    8000577e:	fc040513          	addi	a0,s0,-64
    80005782:	ffffb097          	auipc	ra,0xffffb
    80005786:	576080e7          	jalr	1398(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000578a:	4741                	li	a4,16
    8000578c:	f2c42683          	lw	a3,-212(s0)
    80005790:	fc040613          	addi	a2,s0,-64
    80005794:	4581                	li	a1,0
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	512080e7          	jalr	1298(ra) # 80003caa <writei>
    800057a0:	47c1                	li	a5,16
    800057a2:	0af51563          	bne	a0,a5,8000584c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057a6:	04491703          	lh	a4,68(s2)
    800057aa:	4785                	li	a5,1
    800057ac:	0af70863          	beq	a4,a5,8000585c <sys_unlink+0x18c>
  iunlockput(dp);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	3b0080e7          	jalr	944(ra) # 80003b62 <iunlockput>
  ip->nlink--;
    800057ba:	04a95783          	lhu	a5,74(s2)
    800057be:	37fd                	addiw	a5,a5,-1
    800057c0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	070080e7          	jalr	112(ra) # 80003836 <iupdate>
  iunlockput(ip);
    800057ce:	854a                	mv	a0,s2
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	392080e7          	jalr	914(ra) # 80003b62 <iunlockput>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	b68080e7          	jalr	-1176(ra) # 80004340 <end_op>
  return 0;
    800057e0:	4501                	li	a0,0
    800057e2:	a84d                	j	80005894 <sys_unlink+0x1c4>
    end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	b5c080e7          	jalr	-1188(ra) # 80004340 <end_op>
    return -1;
    800057ec:	557d                	li	a0,-1
    800057ee:	a05d                	j	80005894 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057f0:	00003517          	auipc	a0,0x3
    800057f4:	f9050513          	addi	a0,a0,-112 # 80008780 <syscalls+0x2f0>
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	d48080e7          	jalr	-696(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005800:	04c92703          	lw	a4,76(s2)
    80005804:	02000793          	li	a5,32
    80005808:	f6e7f9e3          	bgeu	a5,a4,8000577a <sys_unlink+0xaa>
    8000580c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005810:	4741                	li	a4,16
    80005812:	86ce                	mv	a3,s3
    80005814:	f1840613          	addi	a2,s0,-232
    80005818:	4581                	li	a1,0
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	398080e7          	jalr	920(ra) # 80003bb4 <readi>
    80005824:	47c1                	li	a5,16
    80005826:	00f51b63          	bne	a0,a5,8000583c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000582a:	f1845783          	lhu	a5,-232(s0)
    8000582e:	e7a1                	bnez	a5,80005876 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005830:	29c1                	addiw	s3,s3,16
    80005832:	04c92783          	lw	a5,76(s2)
    80005836:	fcf9ede3          	bltu	s3,a5,80005810 <sys_unlink+0x140>
    8000583a:	b781                	j	8000577a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000583c:	00003517          	auipc	a0,0x3
    80005840:	f5c50513          	addi	a0,a0,-164 # 80008798 <syscalls+0x308>
    80005844:	ffffb097          	auipc	ra,0xffffb
    80005848:	cfc080e7          	jalr	-772(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000584c:	00003517          	auipc	a0,0x3
    80005850:	f6450513          	addi	a0,a0,-156 # 800087b0 <syscalls+0x320>
    80005854:	ffffb097          	auipc	ra,0xffffb
    80005858:	cec080e7          	jalr	-788(ra) # 80000540 <panic>
    dp->nlink--;
    8000585c:	04a4d783          	lhu	a5,74(s1)
    80005860:	37fd                	addiw	a5,a5,-1
    80005862:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005866:	8526                	mv	a0,s1
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	fce080e7          	jalr	-50(ra) # 80003836 <iupdate>
    80005870:	b781                	j	800057b0 <sys_unlink+0xe0>
    return -1;
    80005872:	557d                	li	a0,-1
    80005874:	a005                	j	80005894 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	2ea080e7          	jalr	746(ra) # 80003b62 <iunlockput>
  iunlockput(dp);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	2e0080e7          	jalr	736(ra) # 80003b62 <iunlockput>
  end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	ab6080e7          	jalr	-1354(ra) # 80004340 <end_op>
  return -1;
    80005892:	557d                	li	a0,-1
}
    80005894:	70ae                	ld	ra,232(sp)
    80005896:	740e                	ld	s0,224(sp)
    80005898:	64ee                	ld	s1,216(sp)
    8000589a:	694e                	ld	s2,208(sp)
    8000589c:	69ae                	ld	s3,200(sp)
    8000589e:	616d                	addi	sp,sp,240
    800058a0:	8082                	ret

00000000800058a2 <sys_open>:

uint64
sys_open(void)
{
    800058a2:	7131                	addi	sp,sp,-192
    800058a4:	fd06                	sd	ra,184(sp)
    800058a6:	f922                	sd	s0,176(sp)
    800058a8:	f526                	sd	s1,168(sp)
    800058aa:	f14a                	sd	s2,160(sp)
    800058ac:	ed4e                	sd	s3,152(sp)
    800058ae:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b0:	08000613          	li	a2,128
    800058b4:	f5040593          	addi	a1,s0,-176
    800058b8:	4501                	li	a0,0
    800058ba:	ffffd097          	auipc	ra,0xffffd
    800058be:	512080e7          	jalr	1298(ra) # 80002dcc <argstr>
    return -1;
    800058c2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058c4:	0c054163          	bltz	a0,80005986 <sys_open+0xe4>
    800058c8:	f4c40593          	addi	a1,s0,-180
    800058cc:	4505                	li	a0,1
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	4ba080e7          	jalr	1210(ra) # 80002d88 <argint>
    800058d6:	0a054863          	bltz	a0,80005986 <sys_open+0xe4>

  begin_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	9e6080e7          	jalr	-1562(ra) # 800042c0 <begin_op>

  if(omode & O_CREATE){
    800058e2:	f4c42783          	lw	a5,-180(s0)
    800058e6:	2007f793          	andi	a5,a5,512
    800058ea:	cbdd                	beqz	a5,800059a0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058ec:	4681                	li	a3,0
    800058ee:	4601                	li	a2,0
    800058f0:	4589                	li	a1,2
    800058f2:	f5040513          	addi	a0,s0,-176
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	974080e7          	jalr	-1676(ra) # 8000526a <create>
    800058fe:	892a                	mv	s2,a0
    if(ip == 0){
    80005900:	c959                	beqz	a0,80005996 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005902:	04491703          	lh	a4,68(s2)
    80005906:	478d                	li	a5,3
    80005908:	00f71763          	bne	a4,a5,80005916 <sys_open+0x74>
    8000590c:	04695703          	lhu	a4,70(s2)
    80005910:	47a5                	li	a5,9
    80005912:	0ce7ec63          	bltu	a5,a4,800059ea <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	dc0080e7          	jalr	-576(ra) # 800046d6 <filealloc>
    8000591e:	89aa                	mv	s3,a0
    80005920:	10050263          	beqz	a0,80005a24 <sys_open+0x182>
    80005924:	00000097          	auipc	ra,0x0
    80005928:	904080e7          	jalr	-1788(ra) # 80005228 <fdalloc>
    8000592c:	84aa                	mv	s1,a0
    8000592e:	0e054663          	bltz	a0,80005a1a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005932:	04491703          	lh	a4,68(s2)
    80005936:	478d                	li	a5,3
    80005938:	0cf70463          	beq	a4,a5,80005a00 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000593c:	4789                	li	a5,2
    8000593e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005942:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005946:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000594a:	f4c42783          	lw	a5,-180(s0)
    8000594e:	0017c713          	xori	a4,a5,1
    80005952:	8b05                	andi	a4,a4,1
    80005954:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005958:	0037f713          	andi	a4,a5,3
    8000595c:	00e03733          	snez	a4,a4
    80005960:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005964:	4007f793          	andi	a5,a5,1024
    80005968:	c791                	beqz	a5,80005974 <sys_open+0xd2>
    8000596a:	04491703          	lh	a4,68(s2)
    8000596e:	4789                	li	a5,2
    80005970:	08f70f63          	beq	a4,a5,80005a0e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005974:	854a                	mv	a0,s2
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	04c080e7          	jalr	76(ra) # 800039c2 <iunlock>
  end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	9c2080e7          	jalr	-1598(ra) # 80004340 <end_op>

  return fd;
}
    80005986:	8526                	mv	a0,s1
    80005988:	70ea                	ld	ra,184(sp)
    8000598a:	744a                	ld	s0,176(sp)
    8000598c:	74aa                	ld	s1,168(sp)
    8000598e:	790a                	ld	s2,160(sp)
    80005990:	69ea                	ld	s3,152(sp)
    80005992:	6129                	addi	sp,sp,192
    80005994:	8082                	ret
      end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	9aa080e7          	jalr	-1622(ra) # 80004340 <end_op>
      return -1;
    8000599e:	b7e5                	j	80005986 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059a0:	f5040513          	addi	a0,s0,-176
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	70c080e7          	jalr	1804(ra) # 800040b0 <namei>
    800059ac:	892a                	mv	s2,a0
    800059ae:	c905                	beqz	a0,800059de <sys_open+0x13c>
    ilock(ip);
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	f50080e7          	jalr	-176(ra) # 80003900 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059b8:	04491703          	lh	a4,68(s2)
    800059bc:	4785                	li	a5,1
    800059be:	f4f712e3          	bne	a4,a5,80005902 <sys_open+0x60>
    800059c2:	f4c42783          	lw	a5,-180(s0)
    800059c6:	dba1                	beqz	a5,80005916 <sys_open+0x74>
      iunlockput(ip);
    800059c8:	854a                	mv	a0,s2
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	198080e7          	jalr	408(ra) # 80003b62 <iunlockput>
      end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	96e080e7          	jalr	-1682(ra) # 80004340 <end_op>
      return -1;
    800059da:	54fd                	li	s1,-1
    800059dc:	b76d                	j	80005986 <sys_open+0xe4>
      end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	962080e7          	jalr	-1694(ra) # 80004340 <end_op>
      return -1;
    800059e6:	54fd                	li	s1,-1
    800059e8:	bf79                	j	80005986 <sys_open+0xe4>
    iunlockput(ip);
    800059ea:	854a                	mv	a0,s2
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	176080e7          	jalr	374(ra) # 80003b62 <iunlockput>
    end_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	94c080e7          	jalr	-1716(ra) # 80004340 <end_op>
    return -1;
    800059fc:	54fd                	li	s1,-1
    800059fe:	b761                	j	80005986 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a00:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a04:	04691783          	lh	a5,70(s2)
    80005a08:	02f99223          	sh	a5,36(s3)
    80005a0c:	bf2d                	j	80005946 <sys_open+0xa4>
    itrunc(ip);
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	ffe080e7          	jalr	-2(ra) # 80003a0e <itrunc>
    80005a18:	bfb1                	j	80005974 <sys_open+0xd2>
      fileclose(f);
    80005a1a:	854e                	mv	a0,s3
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	d76080e7          	jalr	-650(ra) # 80004792 <fileclose>
    iunlockput(ip);
    80005a24:	854a                	mv	a0,s2
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	13c080e7          	jalr	316(ra) # 80003b62 <iunlockput>
    end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	912080e7          	jalr	-1774(ra) # 80004340 <end_op>
    return -1;
    80005a36:	54fd                	li	s1,-1
    80005a38:	b7b9                	j	80005986 <sys_open+0xe4>

0000000080005a3a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a3a:	7175                	addi	sp,sp,-144
    80005a3c:	e506                	sd	ra,136(sp)
    80005a3e:	e122                	sd	s0,128(sp)
    80005a40:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	87e080e7          	jalr	-1922(ra) # 800042c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a4a:	08000613          	li	a2,128
    80005a4e:	f7040593          	addi	a1,s0,-144
    80005a52:	4501                	li	a0,0
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	378080e7          	jalr	888(ra) # 80002dcc <argstr>
    80005a5c:	02054963          	bltz	a0,80005a8e <sys_mkdir+0x54>
    80005a60:	4681                	li	a3,0
    80005a62:	4601                	li	a2,0
    80005a64:	4585                	li	a1,1
    80005a66:	f7040513          	addi	a0,s0,-144
    80005a6a:	00000097          	auipc	ra,0x0
    80005a6e:	800080e7          	jalr	-2048(ra) # 8000526a <create>
    80005a72:	cd11                	beqz	a0,80005a8e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	0ee080e7          	jalr	238(ra) # 80003b62 <iunlockput>
  end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	8c4080e7          	jalr	-1852(ra) # 80004340 <end_op>
  return 0;
    80005a84:	4501                	li	a0,0
}
    80005a86:	60aa                	ld	ra,136(sp)
    80005a88:	640a                	ld	s0,128(sp)
    80005a8a:	6149                	addi	sp,sp,144
    80005a8c:	8082                	ret
    end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	8b2080e7          	jalr	-1870(ra) # 80004340 <end_op>
    return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	b7fd                	j	80005a86 <sys_mkdir+0x4c>

0000000080005a9a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a9a:	7135                	addi	sp,sp,-160
    80005a9c:	ed06                	sd	ra,152(sp)
    80005a9e:	e922                	sd	s0,144(sp)
    80005aa0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	81e080e7          	jalr	-2018(ra) # 800042c0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aaa:	08000613          	li	a2,128
    80005aae:	f7040593          	addi	a1,s0,-144
    80005ab2:	4501                	li	a0,0
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	318080e7          	jalr	792(ra) # 80002dcc <argstr>
    80005abc:	04054a63          	bltz	a0,80005b10 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ac0:	f6c40593          	addi	a1,s0,-148
    80005ac4:	4505                	li	a0,1
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	2c2080e7          	jalr	706(ra) # 80002d88 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ace:	04054163          	bltz	a0,80005b10 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ad2:	f6840593          	addi	a1,s0,-152
    80005ad6:	4509                	li	a0,2
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	2b0080e7          	jalr	688(ra) # 80002d88 <argint>
     argint(1, &major) < 0 ||
    80005ae0:	02054863          	bltz	a0,80005b10 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ae4:	f6841683          	lh	a3,-152(s0)
    80005ae8:	f6c41603          	lh	a2,-148(s0)
    80005aec:	458d                	li	a1,3
    80005aee:	f7040513          	addi	a0,s0,-144
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	778080e7          	jalr	1912(ra) # 8000526a <create>
     argint(2, &minor) < 0 ||
    80005afa:	c919                	beqz	a0,80005b10 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	066080e7          	jalr	102(ra) # 80003b62 <iunlockput>
  end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	83c080e7          	jalr	-1988(ra) # 80004340 <end_op>
  return 0;
    80005b0c:	4501                	li	a0,0
    80005b0e:	a031                	j	80005b1a <sys_mknod+0x80>
    end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	830080e7          	jalr	-2000(ra) # 80004340 <end_op>
    return -1;
    80005b18:	557d                	li	a0,-1
}
    80005b1a:	60ea                	ld	ra,152(sp)
    80005b1c:	644a                	ld	s0,144(sp)
    80005b1e:	610d                	addi	sp,sp,160
    80005b20:	8082                	ret

0000000080005b22 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b22:	7135                	addi	sp,sp,-160
    80005b24:	ed06                	sd	ra,152(sp)
    80005b26:	e922                	sd	s0,144(sp)
    80005b28:	e526                	sd	s1,136(sp)
    80005b2a:	e14a                	sd	s2,128(sp)
    80005b2c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b2e:	ffffc097          	auipc	ra,0xffffc
    80005b32:	fbc080e7          	jalr	-68(ra) # 80001aea <myproc>
    80005b36:	892a                	mv	s2,a0
  
  begin_op();
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	788080e7          	jalr	1928(ra) # 800042c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b40:	08000613          	li	a2,128
    80005b44:	f6040593          	addi	a1,s0,-160
    80005b48:	4501                	li	a0,0
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	282080e7          	jalr	642(ra) # 80002dcc <argstr>
    80005b52:	04054b63          	bltz	a0,80005ba8 <sys_chdir+0x86>
    80005b56:	f6040513          	addi	a0,s0,-160
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	556080e7          	jalr	1366(ra) # 800040b0 <namei>
    80005b62:	84aa                	mv	s1,a0
    80005b64:	c131                	beqz	a0,80005ba8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	d9a080e7          	jalr	-614(ra) # 80003900 <ilock>
  if(ip->type != T_DIR){
    80005b6e:	04449703          	lh	a4,68(s1)
    80005b72:	4785                	li	a5,1
    80005b74:	04f71063          	bne	a4,a5,80005bb4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b78:	8526                	mv	a0,s1
    80005b7a:	ffffe097          	auipc	ra,0xffffe
    80005b7e:	e48080e7          	jalr	-440(ra) # 800039c2 <iunlock>
  iput(p->cwd);
    80005b82:	15093503          	ld	a0,336(s2)
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	f34080e7          	jalr	-204(ra) # 80003aba <iput>
  end_op();
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	7b2080e7          	jalr	1970(ra) # 80004340 <end_op>
  p->cwd = ip;
    80005b96:	14993823          	sd	s1,336(s2)
  return 0;
    80005b9a:	4501                	li	a0,0
}
    80005b9c:	60ea                	ld	ra,152(sp)
    80005b9e:	644a                	ld	s0,144(sp)
    80005ba0:	64aa                	ld	s1,136(sp)
    80005ba2:	690a                	ld	s2,128(sp)
    80005ba4:	610d                	addi	sp,sp,160
    80005ba6:	8082                	ret
    end_op();
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	798080e7          	jalr	1944(ra) # 80004340 <end_op>
    return -1;
    80005bb0:	557d                	li	a0,-1
    80005bb2:	b7ed                	j	80005b9c <sys_chdir+0x7a>
    iunlockput(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	fac080e7          	jalr	-84(ra) # 80003b62 <iunlockput>
    end_op();
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	782080e7          	jalr	1922(ra) # 80004340 <end_op>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	bfd1                	j	80005b9c <sys_chdir+0x7a>

0000000080005bca <sys_exec>:

uint64
sys_exec(void)
{
    80005bca:	7145                	addi	sp,sp,-464
    80005bcc:	e786                	sd	ra,456(sp)
    80005bce:	e3a2                	sd	s0,448(sp)
    80005bd0:	ff26                	sd	s1,440(sp)
    80005bd2:	fb4a                	sd	s2,432(sp)
    80005bd4:	f74e                	sd	s3,424(sp)
    80005bd6:	f352                	sd	s4,416(sp)
    80005bd8:	ef56                	sd	s5,408(sp)
    80005bda:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bdc:	08000613          	li	a2,128
    80005be0:	f4040593          	addi	a1,s0,-192
    80005be4:	4501                	li	a0,0
    80005be6:	ffffd097          	auipc	ra,0xffffd
    80005bea:	1e6080e7          	jalr	486(ra) # 80002dcc <argstr>
    return -1;
    80005bee:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bf0:	0c054a63          	bltz	a0,80005cc4 <sys_exec+0xfa>
    80005bf4:	e3840593          	addi	a1,s0,-456
    80005bf8:	4505                	li	a0,1
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	1b0080e7          	jalr	432(ra) # 80002daa <argaddr>
    80005c02:	0c054163          	bltz	a0,80005cc4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c06:	10000613          	li	a2,256
    80005c0a:	4581                	li	a1,0
    80005c0c:	e4040513          	addi	a0,s0,-448
    80005c10:	ffffb097          	auipc	ra,0xffffb
    80005c14:	0e8080e7          	jalr	232(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c18:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c1c:	89a6                	mv	s3,s1
    80005c1e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c20:	02000a13          	li	s4,32
    80005c24:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c28:	00391793          	slli	a5,s2,0x3
    80005c2c:	e3040593          	addi	a1,s0,-464
    80005c30:	e3843503          	ld	a0,-456(s0)
    80005c34:	953e                	add	a0,a0,a5
    80005c36:	ffffd097          	auipc	ra,0xffffd
    80005c3a:	0b8080e7          	jalr	184(ra) # 80002cee <fetchaddr>
    80005c3e:	02054a63          	bltz	a0,80005c72 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c42:	e3043783          	ld	a5,-464(s0)
    80005c46:	c3b9                	beqz	a5,80005c8c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	ec4080e7          	jalr	-316(ra) # 80000b0c <kalloc>
    80005c50:	85aa                	mv	a1,a0
    80005c52:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c56:	cd11                	beqz	a0,80005c72 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c58:	6605                	lui	a2,0x1
    80005c5a:	e3043503          	ld	a0,-464(s0)
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	0e2080e7          	jalr	226(ra) # 80002d40 <fetchstr>
    80005c66:	00054663          	bltz	a0,80005c72 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c6a:	0905                	addi	s2,s2,1
    80005c6c:	09a1                	addi	s3,s3,8
    80005c6e:	fb491be3          	bne	s2,s4,80005c24 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c72:	10048913          	addi	s2,s1,256
    80005c76:	6088                	ld	a0,0(s1)
    80005c78:	c529                	beqz	a0,80005cc2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c7a:	ffffb097          	auipc	ra,0xffffb
    80005c7e:	d96080e7          	jalr	-618(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c82:	04a1                	addi	s1,s1,8
    80005c84:	ff2499e3          	bne	s1,s2,80005c76 <sys_exec+0xac>
  return -1;
    80005c88:	597d                	li	s2,-1
    80005c8a:	a82d                	j	80005cc4 <sys_exec+0xfa>
      argv[i] = 0;
    80005c8c:	0a8e                	slli	s5,s5,0x3
    80005c8e:	fc040793          	addi	a5,s0,-64
    80005c92:	9abe                	add	s5,s5,a5
    80005c94:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005c98:	e4040593          	addi	a1,s0,-448
    80005c9c:	f4040513          	addi	a0,s0,-192
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	178080e7          	jalr	376(ra) # 80004e18 <exec>
    80005ca8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005caa:	10048993          	addi	s3,s1,256
    80005cae:	6088                	ld	a0,0(s1)
    80005cb0:	c911                	beqz	a0,80005cc4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cb2:	ffffb097          	auipc	ra,0xffffb
    80005cb6:	d5e080e7          	jalr	-674(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cba:	04a1                	addi	s1,s1,8
    80005cbc:	ff3499e3          	bne	s1,s3,80005cae <sys_exec+0xe4>
    80005cc0:	a011                	j	80005cc4 <sys_exec+0xfa>
  return -1;
    80005cc2:	597d                	li	s2,-1
}
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	60be                	ld	ra,456(sp)
    80005cc8:	641e                	ld	s0,448(sp)
    80005cca:	74fa                	ld	s1,440(sp)
    80005ccc:	795a                	ld	s2,432(sp)
    80005cce:	79ba                	ld	s3,424(sp)
    80005cd0:	7a1a                	ld	s4,416(sp)
    80005cd2:	6afa                	ld	s5,408(sp)
    80005cd4:	6179                	addi	sp,sp,464
    80005cd6:	8082                	ret

0000000080005cd8 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cd8:	7139                	addi	sp,sp,-64
    80005cda:	fc06                	sd	ra,56(sp)
    80005cdc:	f822                	sd	s0,48(sp)
    80005cde:	f426                	sd	s1,40(sp)
    80005ce0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	e08080e7          	jalr	-504(ra) # 80001aea <myproc>
    80005cea:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cec:	fd840593          	addi	a1,s0,-40
    80005cf0:	4501                	li	a0,0
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	0b8080e7          	jalr	184(ra) # 80002daa <argaddr>
    return -1;
    80005cfa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cfc:	0e054063          	bltz	a0,80005ddc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d00:	fc840593          	addi	a1,s0,-56
    80005d04:	fd040513          	addi	a0,s0,-48
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	de0080e7          	jalr	-544(ra) # 80004ae8 <pipealloc>
    return -1;
    80005d10:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d12:	0c054563          	bltz	a0,80005ddc <sys_pipe+0x104>
  fd0 = -1;
    80005d16:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d1a:	fd043503          	ld	a0,-48(s0)
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	50a080e7          	jalr	1290(ra) # 80005228 <fdalloc>
    80005d26:	fca42223          	sw	a0,-60(s0)
    80005d2a:	08054c63          	bltz	a0,80005dc2 <sys_pipe+0xea>
    80005d2e:	fc843503          	ld	a0,-56(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	4f6080e7          	jalr	1270(ra) # 80005228 <fdalloc>
    80005d3a:	fca42023          	sw	a0,-64(s0)
    80005d3e:	06054863          	bltz	a0,80005dae <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d42:	4691                	li	a3,4
    80005d44:	fc440613          	addi	a2,s0,-60
    80005d48:	fd843583          	ld	a1,-40(s0)
    80005d4c:	68a8                	ld	a0,80(s1)
    80005d4e:	ffffc097          	auipc	ra,0xffffc
    80005d52:	95c080e7          	jalr	-1700(ra) # 800016aa <copyout>
    80005d56:	02054063          	bltz	a0,80005d76 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d5a:	4691                	li	a3,4
    80005d5c:	fc040613          	addi	a2,s0,-64
    80005d60:	fd843583          	ld	a1,-40(s0)
    80005d64:	0591                	addi	a1,a1,4
    80005d66:	68a8                	ld	a0,80(s1)
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	942080e7          	jalr	-1726(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d70:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d72:	06055563          	bgez	a0,80005ddc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d76:	fc442783          	lw	a5,-60(s0)
    80005d7a:	07e9                	addi	a5,a5,26
    80005d7c:	078e                	slli	a5,a5,0x3
    80005d7e:	97a6                	add	a5,a5,s1
    80005d80:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d84:	fc042503          	lw	a0,-64(s0)
    80005d88:	0569                	addi	a0,a0,26
    80005d8a:	050e                	slli	a0,a0,0x3
    80005d8c:	9526                	add	a0,a0,s1
    80005d8e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d92:	fd043503          	ld	a0,-48(s0)
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	9fc080e7          	jalr	-1540(ra) # 80004792 <fileclose>
    fileclose(wf);
    80005d9e:	fc843503          	ld	a0,-56(s0)
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	9f0080e7          	jalr	-1552(ra) # 80004792 <fileclose>
    return -1;
    80005daa:	57fd                	li	a5,-1
    80005dac:	a805                	j	80005ddc <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dae:	fc442783          	lw	a5,-60(s0)
    80005db2:	0007c863          	bltz	a5,80005dc2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005db6:	01a78513          	addi	a0,a5,26
    80005dba:	050e                	slli	a0,a0,0x3
    80005dbc:	9526                	add	a0,a0,s1
    80005dbe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc2:	fd043503          	ld	a0,-48(s0)
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	9cc080e7          	jalr	-1588(ra) # 80004792 <fileclose>
    fileclose(wf);
    80005dce:	fc843503          	ld	a0,-56(s0)
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	9c0080e7          	jalr	-1600(ra) # 80004792 <fileclose>
    return -1;
    80005dda:	57fd                	li	a5,-1
}
    80005ddc:	853e                	mv	a0,a5
    80005dde:	70e2                	ld	ra,56(sp)
    80005de0:	7442                	ld	s0,48(sp)
    80005de2:	74a2                	ld	s1,40(sp)
    80005de4:	6121                	addi	sp,sp,64
    80005de6:	8082                	ret
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	d73fc0ef          	jal	ra,80002ba2 <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	710c                	ld	a1,32(a0)
    80005e8c:	7510                	ld	a2,40(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	bf6080e7          	jalr	-1034(ra) # 80001abe <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	953e                	add	a0,a0,a5
    80005eec:	00052023          	sw	zero,0(a0)
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	bbe080e7          	jalr	-1090(ra) # 80001abe <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5179b          	slliw	a5,a0,0xd
    80005f0c:	0c201537          	lui	a0,0xc201
    80005f10:	953e                	add	a0,a0,a5
  return irq;
}
    80005f12:	4148                	lw	a0,4(a0)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	b96080e7          	jalr	-1130(ra) # 80001abe <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cc63          	blt	a5,a0,80005fa8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f54:	0001e797          	auipc	a5,0x1e
    80005f58:	0ac78793          	addi	a5,a5,172 # 80024000 <disk>
    80005f5c:	00a78733          	add	a4,a5,a0
    80005f60:	6789                	lui	a5,0x2
    80005f62:	97ba                	add	a5,a5,a4
    80005f64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f68:	eba1                	bnez	a5,80005fb8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f6a:	00451713          	slli	a4,a0,0x4
    80005f6e:	00020797          	auipc	a5,0x20
    80005f72:	0927b783          	ld	a5,146(a5) # 80026000 <disk+0x2000>
    80005f76:	97ba                	add	a5,a5,a4
    80005f78:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f7c:	0001e797          	auipc	a5,0x1e
    80005f80:	08478793          	addi	a5,a5,132 # 80024000 <disk>
    80005f84:	97aa                	add	a5,a5,a0
    80005f86:	6509                	lui	a0,0x2
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	4785                	li	a5,1
    80005f8c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f90:	00020517          	auipc	a0,0x20
    80005f94:	08850513          	addi	a0,a0,136 # 80026018 <disk+0x2018>
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	6a0080e7          	jalr	1696(ra) # 80002638 <wakeup>
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	81850513          	addi	a0,a0,-2024 # 800087c0 <syscalls+0x330>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	590080e7          	jalr	1424(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	82050513          	addi	a0,a0,-2016 # 800087d8 <syscalls+0x348>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>

0000000080005fc8 <virtio_disk_init>:
{
    80005fc8:	1101                	addi	sp,sp,-32
    80005fca:	ec06                	sd	ra,24(sp)
    80005fcc:	e822                	sd	s0,16(sp)
    80005fce:	e426                	sd	s1,8(sp)
    80005fd0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd2:	00003597          	auipc	a1,0x3
    80005fd6:	81e58593          	addi	a1,a1,-2018 # 800087f0 <syscalls+0x360>
    80005fda:	00020517          	auipc	a0,0x20
    80005fde:	0ce50513          	addi	a0,a0,206 # 800260a8 <disk+0x20a8>
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	b8a080e7          	jalr	-1142(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fea:	100017b7          	lui	a5,0x10001
    80005fee:	4398                	lw	a4,0(a5)
    80005ff0:	2701                	sext.w	a4,a4
    80005ff2:	747277b7          	lui	a5,0x74727
    80005ff6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ffa:	0ef71163          	bne	a4,a5,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ffe:	100017b7          	lui	a5,0x10001
    80006002:	43dc                	lw	a5,4(a5)
    80006004:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006006:	4705                	li	a4,1
    80006008:	0ce79a63          	bne	a5,a4,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600c:	100017b7          	lui	a5,0x10001
    80006010:	479c                	lw	a5,8(a5)
    80006012:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006014:	4709                	li	a4,2
    80006016:	0ce79363          	bne	a5,a4,800060dc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	47d8                	lw	a4,12(a5)
    80006020:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006022:	554d47b7          	lui	a5,0x554d4
    80006026:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000602a:	0af71963          	bne	a4,a5,800060dc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	4705                	li	a4,1
    80006034:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	470d                	li	a4,3
    80006038:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000603a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000603c:	c7ffe737          	lui	a4,0xc7ffe
    80006040:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80006044:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006046:	2701                	sext.w	a4,a4
    80006048:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604a:	472d                	li	a4,11
    8000604c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604e:	473d                	li	a4,15
    80006050:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006052:	6705                	lui	a4,0x1
    80006054:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006056:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000605a:	5bdc                	lw	a5,52(a5)
    8000605c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000605e:	c7d9                	beqz	a5,800060ec <virtio_disk_init+0x124>
  if(max < NUM)
    80006060:	471d                	li	a4,7
    80006062:	08f77d63          	bgeu	a4,a5,800060fc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006066:	100014b7          	lui	s1,0x10001
    8000606a:	47a1                	li	a5,8
    8000606c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000606e:	6609                	lui	a2,0x2
    80006070:	4581                	li	a1,0
    80006072:	0001e517          	auipc	a0,0x1e
    80006076:	f8e50513          	addi	a0,a0,-114 # 80024000 <disk>
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	c7e080e7          	jalr	-898(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006082:	0001e717          	auipc	a4,0x1e
    80006086:	f7e70713          	addi	a4,a4,-130 # 80024000 <disk>
    8000608a:	00c75793          	srli	a5,a4,0xc
    8000608e:	2781                	sext.w	a5,a5
    80006090:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006092:	00020797          	auipc	a5,0x20
    80006096:	f6e78793          	addi	a5,a5,-146 # 80026000 <disk+0x2000>
    8000609a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000609c:	0001e717          	auipc	a4,0x1e
    800060a0:	fe470713          	addi	a4,a4,-28 # 80024080 <disk+0x80>
    800060a4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060a6:	0001f717          	auipc	a4,0x1f
    800060aa:	f5a70713          	addi	a4,a4,-166 # 80025000 <disk+0x1000>
    800060ae:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060b0:	4705                	li	a4,1
    800060b2:	00e78c23          	sb	a4,24(a5)
    800060b6:	00e78ca3          	sb	a4,25(a5)
    800060ba:	00e78d23          	sb	a4,26(a5)
    800060be:	00e78da3          	sb	a4,27(a5)
    800060c2:	00e78e23          	sb	a4,28(a5)
    800060c6:	00e78ea3          	sb	a4,29(a5)
    800060ca:	00e78f23          	sb	a4,30(a5)
    800060ce:	00e78fa3          	sb	a4,31(a5)
}
    800060d2:	60e2                	ld	ra,24(sp)
    800060d4:	6442                	ld	s0,16(sp)
    800060d6:	64a2                	ld	s1,8(sp)
    800060d8:	6105                	addi	sp,sp,32
    800060da:	8082                	ret
    panic("could not find virtio disk");
    800060dc:	00002517          	auipc	a0,0x2
    800060e0:	72450513          	addi	a0,a0,1828 # 80008800 <syscalls+0x370>
    800060e4:	ffffa097          	auipc	ra,0xffffa
    800060e8:	45c080e7          	jalr	1116(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800060ec:	00002517          	auipc	a0,0x2
    800060f0:	73450513          	addi	a0,a0,1844 # 80008820 <syscalls+0x390>
    800060f4:	ffffa097          	auipc	ra,0xffffa
    800060f8:	44c080e7          	jalr	1100(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800060fc:	00002517          	auipc	a0,0x2
    80006100:	74450513          	addi	a0,a0,1860 # 80008840 <syscalls+0x3b0>
    80006104:	ffffa097          	auipc	ra,0xffffa
    80006108:	43c080e7          	jalr	1084(ra) # 80000540 <panic>

000000008000610c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000610c:	7175                	addi	sp,sp,-144
    8000610e:	e506                	sd	ra,136(sp)
    80006110:	e122                	sd	s0,128(sp)
    80006112:	fca6                	sd	s1,120(sp)
    80006114:	f8ca                	sd	s2,112(sp)
    80006116:	f4ce                	sd	s3,104(sp)
    80006118:	f0d2                	sd	s4,96(sp)
    8000611a:	ecd6                	sd	s5,88(sp)
    8000611c:	e8da                	sd	s6,80(sp)
    8000611e:	e4de                	sd	s7,72(sp)
    80006120:	e0e2                	sd	s8,64(sp)
    80006122:	fc66                	sd	s9,56(sp)
    80006124:	f86a                	sd	s10,48(sp)
    80006126:	f46e                	sd	s11,40(sp)
    80006128:	0900                	addi	s0,sp,144
    8000612a:	8aaa                	mv	s5,a0
    8000612c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000612e:	00c52c83          	lw	s9,12(a0)
    80006132:	001c9c9b          	slliw	s9,s9,0x1
    80006136:	1c82                	slli	s9,s9,0x20
    80006138:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000613c:	00020517          	auipc	a0,0x20
    80006140:	f6c50513          	addi	a0,a0,-148 # 800260a8 <disk+0x20a8>
    80006144:	ffffb097          	auipc	ra,0xffffb
    80006148:	ab8080e7          	jalr	-1352(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    8000614c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000614e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006150:	0001ec17          	auipc	s8,0x1e
    80006154:	eb0c0c13          	addi	s8,s8,-336 # 80024000 <disk>
    80006158:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000615a:	4b0d                	li	s6,3
    8000615c:	a0ad                	j	800061c6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000615e:	00fc0733          	add	a4,s8,a5
    80006162:	975e                	add	a4,a4,s7
    80006164:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006168:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000616a:	0207c563          	bltz	a5,80006194 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000616e:	2905                	addiw	s2,s2,1
    80006170:	0611                	addi	a2,a2,4
    80006172:	19690d63          	beq	s2,s6,8000630c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006176:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006178:	00020717          	auipc	a4,0x20
    8000617c:	ea070713          	addi	a4,a4,-352 # 80026018 <disk+0x2018>
    80006180:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006182:	00074683          	lbu	a3,0(a4)
    80006186:	fee1                	bnez	a3,8000615e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006188:	2785                	addiw	a5,a5,1
    8000618a:	0705                	addi	a4,a4,1
    8000618c:	fe979be3          	bne	a5,s1,80006182 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006190:	57fd                	li	a5,-1
    80006192:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006194:	01205d63          	blez	s2,800061ae <virtio_disk_rw+0xa2>
    80006198:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000619a:	000a2503          	lw	a0,0(s4)
    8000619e:	00000097          	auipc	ra,0x0
    800061a2:	da8080e7          	jalr	-600(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    800061a6:	2d85                	addiw	s11,s11,1
    800061a8:	0a11                	addi	s4,s4,4
    800061aa:	ffb918e3          	bne	s2,s11,8000619a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061ae:	00020597          	auipc	a1,0x20
    800061b2:	efa58593          	addi	a1,a1,-262 # 800260a8 <disk+0x20a8>
    800061b6:	00020517          	auipc	a0,0x20
    800061ba:	e6250513          	addi	a0,a0,-414 # 80026018 <disk+0x2018>
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	2ee080e7          	jalr	750(ra) # 800024ac <sleep>
  for(int i = 0; i < 3; i++){
    800061c6:	f8040a13          	addi	s4,s0,-128
{
    800061ca:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061cc:	894e                	mv	s2,s3
    800061ce:	b765                	j	80006176 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061d0:	00020717          	auipc	a4,0x20
    800061d4:	e3073703          	ld	a4,-464(a4) # 80026000 <disk+0x2000>
    800061d8:	973e                	add	a4,a4,a5
    800061da:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061de:	0001e517          	auipc	a0,0x1e
    800061e2:	e2250513          	addi	a0,a0,-478 # 80024000 <disk>
    800061e6:	00020717          	auipc	a4,0x20
    800061ea:	e1a70713          	addi	a4,a4,-486 # 80026000 <disk+0x2000>
    800061ee:	6314                	ld	a3,0(a4)
    800061f0:	96be                	add	a3,a3,a5
    800061f2:	00c6d603          	lhu	a2,12(a3)
    800061f6:	00166613          	ori	a2,a2,1
    800061fa:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061fe:	f8842683          	lw	a3,-120(s0)
    80006202:	6310                	ld	a2,0(a4)
    80006204:	97b2                	add	a5,a5,a2
    80006206:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000620a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000620e:	0612                	slli	a2,a2,0x4
    80006210:	962a                	add	a2,a2,a0
    80006212:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006216:	00469793          	slli	a5,a3,0x4
    8000621a:	630c                	ld	a1,0(a4)
    8000621c:	95be                	add	a1,a1,a5
    8000621e:	6689                	lui	a3,0x2
    80006220:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006224:	96ca                	add	a3,a3,s2
    80006226:	96aa                	add	a3,a3,a0
    80006228:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000622a:	6314                	ld	a3,0(a4)
    8000622c:	96be                	add	a3,a3,a5
    8000622e:	4585                	li	a1,1
    80006230:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006232:	6314                	ld	a3,0(a4)
    80006234:	96be                	add	a3,a3,a5
    80006236:	4509                	li	a0,2
    80006238:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000623c:	6314                	ld	a3,0(a4)
    8000623e:	97b6                	add	a5,a5,a3
    80006240:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006244:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006248:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000624c:	6714                	ld	a3,8(a4)
    8000624e:	0026d783          	lhu	a5,2(a3)
    80006252:	8b9d                	andi	a5,a5,7
    80006254:	0789                	addi	a5,a5,2
    80006256:	0786                	slli	a5,a5,0x1
    80006258:	97b6                	add	a5,a5,a3
    8000625a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000625e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006262:	6718                	ld	a4,8(a4)
    80006264:	00275783          	lhu	a5,2(a4)
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000626e:	100017b7          	lui	a5,0x10001
    80006272:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006276:	004aa783          	lw	a5,4(s5)
    8000627a:	02b79163          	bne	a5,a1,8000629c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000627e:	00020917          	auipc	s2,0x20
    80006282:	e2a90913          	addi	s2,s2,-470 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006286:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006288:	85ca                	mv	a1,s2
    8000628a:	8556                	mv	a0,s5
    8000628c:	ffffc097          	auipc	ra,0xffffc
    80006290:	220080e7          	jalr	544(ra) # 800024ac <sleep>
  while(b->disk == 1) {
    80006294:	004aa783          	lw	a5,4(s5)
    80006298:	fe9788e3          	beq	a5,s1,80006288 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000629c:	f8042483          	lw	s1,-128(s0)
    800062a0:	20048793          	addi	a5,s1,512
    800062a4:	00479713          	slli	a4,a5,0x4
    800062a8:	0001e797          	auipc	a5,0x1e
    800062ac:	d5878793          	addi	a5,a5,-680 # 80024000 <disk>
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b6:	00020917          	auipc	s2,0x20
    800062ba:	d4a90913          	addi	s2,s2,-694 # 80026000 <disk+0x2000>
    800062be:	a019                	j	800062c4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800062c0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062c4:	8526                	mv	a0,s1
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	c80080e7          	jalr	-896(ra) # 80005f46 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062ce:	0492                	slli	s1,s1,0x4
    800062d0:	00093783          	ld	a5,0(s2)
    800062d4:	94be                	add	s1,s1,a5
    800062d6:	00c4d783          	lhu	a5,12(s1)
    800062da:	8b85                	andi	a5,a5,1
    800062dc:	f3f5                	bnez	a5,800062c0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062de:	00020517          	auipc	a0,0x20
    800062e2:	dca50513          	addi	a0,a0,-566 # 800260a8 <disk+0x20a8>
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	9ca080e7          	jalr	-1590(ra) # 80000cb0 <release>
}
    800062ee:	60aa                	ld	ra,136(sp)
    800062f0:	640a                	ld	s0,128(sp)
    800062f2:	74e6                	ld	s1,120(sp)
    800062f4:	7946                	ld	s2,112(sp)
    800062f6:	79a6                	ld	s3,104(sp)
    800062f8:	7a06                	ld	s4,96(sp)
    800062fa:	6ae6                	ld	s5,88(sp)
    800062fc:	6b46                	ld	s6,80(sp)
    800062fe:	6ba6                	ld	s7,72(sp)
    80006300:	6c06                	ld	s8,64(sp)
    80006302:	7ce2                	ld	s9,56(sp)
    80006304:	7d42                	ld	s10,48(sp)
    80006306:	7da2                	ld	s11,40(sp)
    80006308:	6149                	addi	sp,sp,144
    8000630a:	8082                	ret
  if(write)
    8000630c:	01a037b3          	snez	a5,s10
    80006310:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006314:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006318:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000631c:	f8042483          	lw	s1,-128(s0)
    80006320:	00449913          	slli	s2,s1,0x4
    80006324:	00020997          	auipc	s3,0x20
    80006328:	cdc98993          	addi	s3,s3,-804 # 80026000 <disk+0x2000>
    8000632c:	0009ba03          	ld	s4,0(s3)
    80006330:	9a4a                	add	s4,s4,s2
    80006332:	f7040513          	addi	a0,s0,-144
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	d82080e7          	jalr	-638(ra) # 800010b8 <kvmpa>
    8000633e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006342:	0009b783          	ld	a5,0(s3)
    80006346:	97ca                	add	a5,a5,s2
    80006348:	4741                	li	a4,16
    8000634a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000634c:	0009b783          	ld	a5,0(s3)
    80006350:	97ca                	add	a5,a5,s2
    80006352:	4705                	li	a4,1
    80006354:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006358:	f8442783          	lw	a5,-124(s0)
    8000635c:	0009b703          	ld	a4,0(s3)
    80006360:	974a                	add	a4,a4,s2
    80006362:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006366:	0792                	slli	a5,a5,0x4
    80006368:	0009b703          	ld	a4,0(s3)
    8000636c:	973e                	add	a4,a4,a5
    8000636e:	058a8693          	addi	a3,s5,88
    80006372:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006374:	0009b703          	ld	a4,0(s3)
    80006378:	973e                	add	a4,a4,a5
    8000637a:	40000693          	li	a3,1024
    8000637e:	c714                	sw	a3,8(a4)
  if(write)
    80006380:	e40d18e3          	bnez	s10,800061d0 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006384:	00020717          	auipc	a4,0x20
    80006388:	c7c73703          	ld	a4,-900(a4) # 80026000 <disk+0x2000>
    8000638c:	973e                	add	a4,a4,a5
    8000638e:	4689                	li	a3,2
    80006390:	00d71623          	sh	a3,12(a4)
    80006394:	b5a9                	j	800061de <virtio_disk_rw+0xd2>

0000000080006396 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006396:	1101                	addi	sp,sp,-32
    80006398:	ec06                	sd	ra,24(sp)
    8000639a:	e822                	sd	s0,16(sp)
    8000639c:	e426                	sd	s1,8(sp)
    8000639e:	e04a                	sd	s2,0(sp)
    800063a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063a2:	00020517          	auipc	a0,0x20
    800063a6:	d0650513          	addi	a0,a0,-762 # 800260a8 <disk+0x20a8>
    800063aa:	ffffb097          	auipc	ra,0xffffb
    800063ae:	852080e7          	jalr	-1966(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063b2:	00020717          	auipc	a4,0x20
    800063b6:	c4e70713          	addi	a4,a4,-946 # 80026000 <disk+0x2000>
    800063ba:	02075783          	lhu	a5,32(a4)
    800063be:	6b18                	ld	a4,16(a4)
    800063c0:	00275683          	lhu	a3,2(a4)
    800063c4:	8ebd                	xor	a3,a3,a5
    800063c6:	8a9d                	andi	a3,a3,7
    800063c8:	cab9                	beqz	a3,8000641e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063ca:	0001e917          	auipc	s2,0x1e
    800063ce:	c3690913          	addi	s2,s2,-970 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063d2:	00020497          	auipc	s1,0x20
    800063d6:	c2e48493          	addi	s1,s1,-978 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063da:	078e                	slli	a5,a5,0x3
    800063dc:	97ba                	add	a5,a5,a4
    800063de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063e0:	20078713          	addi	a4,a5,512
    800063e4:	0712                	slli	a4,a4,0x4
    800063e6:	974a                	add	a4,a4,s2
    800063e8:	03074703          	lbu	a4,48(a4)
    800063ec:	ef21                	bnez	a4,80006444 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063ee:	20078793          	addi	a5,a5,512
    800063f2:	0792                	slli	a5,a5,0x4
    800063f4:	97ca                	add	a5,a5,s2
    800063f6:	7798                	ld	a4,40(a5)
    800063f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063fc:	7788                	ld	a0,40(a5)
    800063fe:	ffffc097          	auipc	ra,0xffffc
    80006402:	23a080e7          	jalr	570(ra) # 80002638 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006406:	0204d783          	lhu	a5,32(s1)
    8000640a:	2785                	addiw	a5,a5,1
    8000640c:	8b9d                	andi	a5,a5,7
    8000640e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006412:	6898                	ld	a4,16(s1)
    80006414:	00275683          	lhu	a3,2(a4)
    80006418:	8a9d                	andi	a3,a3,7
    8000641a:	fcf690e3          	bne	a3,a5,800063da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000641e:	10001737          	lui	a4,0x10001
    80006422:	533c                	lw	a5,96(a4)
    80006424:	8b8d                	andi	a5,a5,3
    80006426:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006428:	00020517          	auipc	a0,0x20
    8000642c:	c8050513          	addi	a0,a0,-896 # 800260a8 <disk+0x20a8>
    80006430:	ffffb097          	auipc	ra,0xffffb
    80006434:	880080e7          	jalr	-1920(ra) # 80000cb0 <release>
}
    80006438:	60e2                	ld	ra,24(sp)
    8000643a:	6442                	ld	s0,16(sp)
    8000643c:	64a2                	ld	s1,8(sp)
    8000643e:	6902                	ld	s2,0(sp)
    80006440:	6105                	addi	sp,sp,32
    80006442:	8082                	ret
      panic("virtio_disk_intr status");
    80006444:	00002517          	auipc	a0,0x2
    80006448:	41c50513          	addi	a0,a0,1052 # 80008860 <syscalls+0x3d0>
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	0f4080e7          	jalr	244(ra) # 80000540 <panic>
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

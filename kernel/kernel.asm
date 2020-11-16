
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
    8000005e:	eb678793          	addi	a5,a5,-330 # 80005f10 <timervec>
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
    80000128:	6e0080e7          	jalr	1760(ra) # 80002804 <either_copyin>
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
    800001cc:	96e080e7          	jalr	-1682(ra) # 80001b36 <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	2f6080e7          	jalr	758(ra) # 800024ce <sleep>
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
    80000218:	59a080e7          	jalr	1434(ra) # 800027ae <either_copyout>
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
    800002f8:	566080e7          	jalr	1382(ra) # 8000285a <procdump>
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
    8000044c:	244080e7          	jalr	580(ra) # 8000268c <wakeup>
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
    800008a4:	dec080e7          	jalr	-532(ra) # 8000268c <wakeup>
    
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
    8000093e:	b94080e7          	jalr	-1132(ra) # 800024ce <sleep>
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
    80000b9a:	f84080e7          	jalr	-124(ra) # 80001b1a <mycpu>
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
    80000bcc:	f52080e7          	jalr	-174(ra) # 80001b1a <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f46080e7          	jalr	-186(ra) # 80001b1a <mycpu>
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
    80000bf0:	f2e080e7          	jalr	-210(ra) # 80001b1a <mycpu>
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
    80000c30:	eee080e7          	jalr	-274(ra) # 80001b1a <mycpu>
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
    80000c5c:	ec2080e7          	jalr	-318(ra) # 80001b1a <mycpu>
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
    80000eb2:	c5c080e7          	jalr	-932(ra) # 80001b0a <cpuid>
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
    80000ece:	c40080e7          	jalr	-960(ra) # 80001b0a <cpuid>
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
    80000ef0:	ab0080e7          	jalr	-1360(ra) # 8000299c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	05c080e7          	jalr	92(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1f2080e7          	jalr	498(ra) # 800020ee <scheduler>
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
    80000f50:	aee080e7          	jalr	-1298(ra) # 80001a3a <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a20080e7          	jalr	-1504(ra) # 80002974 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	a40080e7          	jalr	-1472(ra) # 8000299c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fd6080e7          	jalr	-42(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fe4080e7          	jalr	-28(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	186080e7          	jalr	390(ra) # 800030fa <binit>
    iinit();         // inode cache
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	818080e7          	jalr	-2024(ra) # 80003794 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7b6080e7          	jalr	1974(ra) # 8000473a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0cc080e7          	jalr	204(ra) # 80006058 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	eba080e7          	jalr	-326(ra) # 80001e4e <userinit>
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
    // should be moved to Q2
    p->change = 3;
    // total sleep time = existing sleep'd time + waketime - zzstart
    p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
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
    p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
    800018c0:	16c4a783          	lw	a5,364(s1)
    800018c4:	00007717          	auipc	a4,0x7
    800018c8:	75c72703          	lw	a4,1884(a4) # 80009020 <ticks>
    800018cc:	9fb9                	addw	a5,a5,a4
    800018ce:	17c4a703          	lw	a4,380(s1)
    800018d2:	9f99                	subw	a5,a5,a4
    800018d4:	16f4a623          	sw	a5,364(s1)
}
    800018d8:	bf75                	j	80001894 <wakeup1+0x1c>

00000000800018da <getportion>:
{
    800018da:	1101                	addi	sp,sp,-32
    800018dc:	ec06                	sd	ra,24(sp)
    800018de:	e822                	sd	s0,16(sp)
    800018e0:	e426                	sd	s1,8(sp)
    800018e2:	e04a                	sd	s2,0(sp)
    800018e4:	1000                	addi	s0,sp,32
    800018e6:	84aa                	mv	s1,a0
  int total = p->Qtime[2] + p->Qtime[1] + p->Qtime[0];
    800018e8:	17452603          	lw	a2,372(a0)
    800018ec:	17052683          	lw	a3,368(a0)
    800018f0:	16c52703          	lw	a4,364(a0)
    800018f4:	00d607bb          	addw	a5,a2,a3
    800018f8:	00e7893b          	addw	s2,a5,a4
  printf("total %dms Q1 %dms Q2 %dms Q3 %dms\n", total, p->Qtime[2], p->Qtime[1], p->Qtime[0]);
    800018fc:	0009059b          	sext.w	a1,s2
    80001900:	00007517          	auipc	a0,0x7
    80001904:	8f050513          	addi	a0,a0,-1808 # 800081f0 <digits+0x1b0>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	c82080e7          	jalr	-894(ra) # 8000058a <printf>
  p->Qtime[2] = p->Qtime[2] * 100 / total;
    80001910:	06400793          	li	a5,100
    80001914:	1744a703          	lw	a4,372(s1)
    80001918:	02e7873b          	mulw	a4,a5,a4
    8000191c:	0327473b          	divw	a4,a4,s2
    80001920:	16e4aa23          	sw	a4,372(s1)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    80001924:	1704a703          	lw	a4,368(s1)
    80001928:	02e7873b          	mulw	a4,a5,a4
    8000192c:	0327473b          	divw	a4,a4,s2
    80001930:	16e4a823          	sw	a4,368(s1)
  p->Qtime[0] = p->Qtime[0] * 100 / total;
    80001934:	16c4a703          	lw	a4,364(s1)
    80001938:	02e787bb          	mulw	a5,a5,a4
    8000193c:	0327c7bb          	divw	a5,a5,s2
    80001940:	16f4a623          	sw	a5,364(s1)
}
    80001944:	60e2                	ld	ra,24(sp)
    80001946:	6442                	ld	s0,16(sp)
    80001948:	64a2                	ld	s1,8(sp)
    8000194a:	6902                	ld	s2,0(sp)
    8000194c:	6105                	addi	sp,sp,32
    8000194e:	8082                	ret

0000000080001950 <findproc>:
{
    80001950:	1141                	addi	sp,sp,-16
    80001952:	e422                	sd	s0,8(sp)
    80001954:	0800                	addi	s0,sp,16
    if (Q[priority][index] == obj)
    80001956:	00959713          	slli	a4,a1,0x9
    8000195a:	00010797          	auipc	a5,0x10
    8000195e:	ff678793          	addi	a5,a5,-10 # 80011950 <Q>
    80001962:	97ba                	add	a5,a5,a4
    80001964:	639c                	ld	a5,0(a5)
    80001966:	02f50263          	beq	a0,a5,8000198a <findproc+0x3a>
    8000196a:	86aa                	mv	a3,a0
    8000196c:	00010797          	auipc	a5,0x10
    80001970:	fec78793          	addi	a5,a5,-20 # 80011958 <Q+0x8>
    80001974:	97ba                	add	a5,a5,a4
  int index = 0;
    80001976:	4501                	li	a0,0
    index++;
    80001978:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    8000197a:	07a1                	addi	a5,a5,8
    8000197c:	ff87b703          	ld	a4,-8(a5)
    80001980:	fed71ce3          	bne	a4,a3,80001978 <findproc+0x28>
}
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret
  int index = 0;
    8000198a:	4501                	li	a0,0
    8000198c:	bfe5                	j	80001984 <findproc+0x34>

000000008000198e <movequeue>:
{
    8000198e:	7179                	addi	sp,sp,-48
    80001990:	f406                	sd	ra,40(sp)
    80001992:	f022                	sd	s0,32(sp)
    80001994:	ec26                	sd	s1,24(sp)
    80001996:	e84a                	sd	s2,16(sp)
    80001998:	e44e                	sd	s3,8(sp)
    8000199a:	1800                	addi	s0,sp,48
    8000199c:	84aa                	mv	s1,a0
    8000199e:	892e                	mv	s2,a1
  if (opt != INSERT)
    800019a0:	4785                	li	a5,1
    800019a2:	06f60163          	beq	a2,a5,80001a04 <movequeue+0x76>
    800019a6:	89b2                	mv	s3,a2
    int pos = findproc(obj, obj->priority);
    800019a8:	17852583          	lw	a1,376(a0)
    800019ac:	00000097          	auipc	ra,0x0
    800019b0:	fa4080e7          	jalr	-92(ra) # 80001950 <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    800019b4:	03e00793          	li	a5,62
    800019b8:	02a7c863          	blt	a5,a0,800019e8 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    800019bc:	00010697          	auipc	a3,0x10
    800019c0:	f9468693          	addi	a3,a3,-108 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    800019c4:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    800019c8:	1784a783          	lw	a5,376(s1)
    800019cc:	862a                	mv	a2,a0
    800019ce:	2505                	addiw	a0,a0,1
    800019d0:	079a                	slli	a5,a5,0x6
    800019d2:	00a78733          	add	a4,a5,a0
    800019d6:	070e                	slli	a4,a4,0x3
    800019d8:	9736                	add	a4,a4,a3
    800019da:	6318                	ld	a4,0(a4)
    800019dc:	97b2                	add	a5,a5,a2
    800019de:	078e                	slli	a5,a5,0x3
    800019e0:	97b6                	add	a5,a5,a3
    800019e2:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    800019e4:	feb512e3          	bne	a0,a1,800019c8 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    800019e8:	1784a783          	lw	a5,376(s1)
    800019ec:	00979713          	slli	a4,a5,0x9
    800019f0:	00010797          	auipc	a5,0x10
    800019f4:	f6078793          	addi	a5,a5,-160 # 80011950 <Q>
    800019f8:	97ba                	add	a5,a5,a4
    800019fa:	1e07bc23          	sd	zero,504(a5)
  if (opt != DELETE)
    800019fe:	4789                	li	a5,2
    80001a00:	02f98463          	beq	s3,a5,80001a28 <movequeue+0x9a>
    int endstart = findproc(0, priority);
    80001a04:	85ca                	mv	a1,s2
    80001a06:	4501                	li	a0,0
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	f48080e7          	jalr	-184(ra) # 80001950 <findproc>
    Q[priority][endstart] = obj;
    80001a10:	00691793          	slli	a5,s2,0x6
    80001a14:	97aa                	add	a5,a5,a0
    80001a16:	078e                	slli	a5,a5,0x3
    80001a18:	00010717          	auipc	a4,0x10
    80001a1c:	f3870713          	addi	a4,a4,-200 # 80011950 <Q>
    80001a20:	97ba                	add	a5,a5,a4
    80001a22:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    80001a24:	1724ac23          	sw	s2,376(s1)
  obj->change = 0;
    80001a28:	1604a423          	sw	zero,360(s1)
}
    80001a2c:	70a2                	ld	ra,40(sp)
    80001a2e:	7402                	ld	s0,32(sp)
    80001a30:	64e2                	ld	s1,24(sp)
    80001a32:	6942                	ld	s2,16(sp)
    80001a34:	69a2                	ld	s3,8(sp)
    80001a36:	6145                	addi	sp,sp,48
    80001a38:	8082                	ret

0000000080001a3a <procinit>:
{
    80001a3a:	715d                	addi	sp,sp,-80
    80001a3c:	e486                	sd	ra,72(sp)
    80001a3e:	e0a2                	sd	s0,64(sp)
    80001a40:	fc26                	sd	s1,56(sp)
    80001a42:	f84a                	sd	s2,48(sp)
    80001a44:	f44e                	sd	s3,40(sp)
    80001a46:	f052                	sd	s4,32(sp)
    80001a48:	ec56                	sd	s5,24(sp)
    80001a4a:	e85a                	sd	s6,16(sp)
    80001a4c:	e45e                	sd	s7,8(sp)
    80001a4e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a50:	00006597          	auipc	a1,0x6
    80001a54:	7c858593          	addi	a1,a1,1992 # 80008218 <digits+0x1d8>
    80001a58:	00010517          	auipc	a0,0x10
    80001a5c:	4f850513          	addi	a0,a0,1272 # 80011f50 <pid_lock>
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	10c080e7          	jalr	268(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a68:	00011917          	auipc	s2,0x11
    80001a6c:	90090913          	addi	s2,s2,-1792 # 80012368 <proc>
    initlock(&p->lock, "proc");
    80001a70:	00006b97          	auipc	s7,0x6
    80001a74:	7b0b8b93          	addi	s7,s7,1968 # 80008220 <digits+0x1e0>
    uint64 va = KSTACK((int)(p - proc));
    80001a78:	8b4a                	mv	s6,s2
    80001a7a:	00006a97          	auipc	s5,0x6
    80001a7e:	586a8a93          	addi	s5,s5,1414 # 80008000 <etext>
    80001a82:	040009b7          	lui	s3,0x4000
    80001a86:	19fd                	addi	s3,s3,-1
    80001a88:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8a:	00017a17          	auipc	s4,0x17
    80001a8e:	8dea0a13          	addi	s4,s4,-1826 # 80018368 <tickslock>
    initlock(&p->lock, "proc");
    80001a92:	85de                	mv	a1,s7
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	0d6080e7          	jalr	214(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	06e080e7          	jalr	110(ra) # 80000b0c <kalloc>
    80001aa6:	85aa                	mv	a1,a0
    if (pa == 0)
    80001aa8:	c929                	beqz	a0,80001afa <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001aaa:	416904b3          	sub	s1,s2,s6
    80001aae:	849d                	srai	s1,s1,0x7
    80001ab0:	000ab783          	ld	a5,0(s5)
    80001ab4:	02f484b3          	mul	s1,s1,a5
    80001ab8:	2485                	addiw	s1,s1,1
    80001aba:	00d4949b          	slliw	s1,s1,0xd
    80001abe:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ac2:	4699                	li	a3,6
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	6dc080e7          	jalr	1756(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001ad0:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001ad4:	18090913          	addi	s2,s2,384
    80001ad8:	fb491de3          	bne	s2,s4,80001a92 <procinit+0x58>
  kvminithart();
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	4d0080e7          	jalr	1232(ra) # 80000fac <kvminithart>
}
    80001ae4:	60a6                	ld	ra,72(sp)
    80001ae6:	6406                	ld	s0,64(sp)
    80001ae8:	74e2                	ld	s1,56(sp)
    80001aea:	7942                	ld	s2,48(sp)
    80001aec:	79a2                	ld	s3,40(sp)
    80001aee:	7a02                	ld	s4,32(sp)
    80001af0:	6ae2                	ld	s5,24(sp)
    80001af2:	6b42                	ld	s6,16(sp)
    80001af4:	6ba2                	ld	s7,8(sp)
    80001af6:	6161                	addi	sp,sp,80
    80001af8:	8082                	ret
      panic("kalloc");
    80001afa:	00006517          	auipc	a0,0x6
    80001afe:	72e50513          	addi	a0,a0,1838 # 80008228 <digits+0x1e8>
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	a3e080e7          	jalr	-1474(ra) # 80000540 <panic>

0000000080001b0a <cpuid>:
{
    80001b0a:	1141                	addi	sp,sp,-16
    80001b0c:	e422                	sd	s0,8(sp)
    80001b0e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b10:	8512                	mv	a0,tp
}
    80001b12:	2501                	sext.w	a0,a0
    80001b14:	6422                	ld	s0,8(sp)
    80001b16:	0141                	addi	sp,sp,16
    80001b18:	8082                	ret

0000000080001b1a <mycpu>:
{
    80001b1a:	1141                	addi	sp,sp,-16
    80001b1c:	e422                	sd	s0,8(sp)
    80001b1e:	0800                	addi	s0,sp,16
    80001b20:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b22:	2781                	sext.w	a5,a5
    80001b24:	079e                	slli	a5,a5,0x7
}
    80001b26:	00010517          	auipc	a0,0x10
    80001b2a:	44250513          	addi	a0,a0,1090 # 80011f68 <cpus>
    80001b2e:	953e                	add	a0,a0,a5
    80001b30:	6422                	ld	s0,8(sp)
    80001b32:	0141                	addi	sp,sp,16
    80001b34:	8082                	ret

0000000080001b36 <myproc>:
{
    80001b36:	1101                	addi	sp,sp,-32
    80001b38:	ec06                	sd	ra,24(sp)
    80001b3a:	e822                	sd	s0,16(sp)
    80001b3c:	e426                	sd	s1,8(sp)
    80001b3e:	1000                	addi	s0,sp,32
  push_off();
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	070080e7          	jalr	112(ra) # 80000bb0 <push_off>
    80001b48:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b4a:	2781                	sext.w	a5,a5
    80001b4c:	079e                	slli	a5,a5,0x7
    80001b4e:	00010717          	auipc	a4,0x10
    80001b52:	e0270713          	addi	a4,a4,-510 # 80011950 <Q>
    80001b56:	97ba                	add	a5,a5,a4
    80001b58:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	0f4080e7          	jalr	244(ra) # 80000c50 <pop_off>
}
    80001b64:	8526                	mv	a0,s1
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6105                	addi	sp,sp,32
    80001b6e:	8082                	ret

0000000080001b70 <forkret>:
{
    80001b70:	1141                	addi	sp,sp,-16
    80001b72:	e406                	sd	ra,8(sp)
    80001b74:	e022                	sd	s0,0(sp)
    80001b76:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	fbe080e7          	jalr	-66(ra) # 80001b36 <myproc>
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	130080e7          	jalr	304(ra) # 80000cb0 <release>
  if (first)
    80001b88:	00007797          	auipc	a5,0x7
    80001b8c:	d087a783          	lw	a5,-760(a5) # 80008890 <first.1>
    80001b90:	eb89                	bnez	a5,80001ba2 <forkret+0x32>
  usertrapret();
    80001b92:	00001097          	auipc	ra,0x1
    80001b96:	e22080e7          	jalr	-478(ra) # 800029b4 <usertrapret>
}
    80001b9a:	60a2                	ld	ra,8(sp)
    80001b9c:	6402                	ld	s0,0(sp)
    80001b9e:	0141                	addi	sp,sp,16
    80001ba0:	8082                	ret
    first = 0;
    80001ba2:	00007797          	auipc	a5,0x7
    80001ba6:	ce07a723          	sw	zero,-786(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001baa:	4505                	li	a0,1
    80001bac:	00002097          	auipc	ra,0x2
    80001bb0:	b68080e7          	jalr	-1176(ra) # 80003714 <fsinit>
    80001bb4:	bff9                	j	80001b92 <forkret+0x22>

0000000080001bb6 <allocpid>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bc2:	00010917          	auipc	s2,0x10
    80001bc6:	38e90913          	addi	s2,s2,910 # 80011f50 <pid_lock>
    80001bca:	854a                	mv	a0,s2
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	030080e7          	jalr	48(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001bd4:	00007797          	auipc	a5,0x7
    80001bd8:	cc078793          	addi	a5,a5,-832 # 80008894 <nextpid>
    80001bdc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bde:	0014871b          	addiw	a4,s1,1
    80001be2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001be4:	854a                	mv	a0,s2
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0ca080e7          	jalr	202(ra) # 80000cb0 <release>
}
    80001bee:	8526                	mv	a0,s1
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6902                	ld	s2,0(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <proc_pagetable>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	e04a                	sd	s2,0(sp)
    80001c06:	1000                	addi	s0,sp,32
    80001c08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	768080e7          	jalr	1896(ra) # 80001372 <uvmcreate>
    80001c12:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c14:	c121                	beqz	a0,80001c54 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c16:	4729                	li	a4,10
    80001c18:	00005697          	auipc	a3,0x5
    80001c1c:	3e868693          	addi	a3,a3,1000 # 80007000 <_trampoline>
    80001c20:	6605                	lui	a2,0x1
    80001c22:	040005b7          	lui	a1,0x4000
    80001c26:	15fd                	addi	a1,a1,-1
    80001c28:	05b2                	slli	a1,a1,0xc
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	4ec080e7          	jalr	1260(ra) # 80001116 <mappages>
    80001c32:	02054863          	bltz	a0,80001c62 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c36:	4719                	li	a4,6
    80001c38:	05893683          	ld	a3,88(s2)
    80001c3c:	6605                	lui	a2,0x1
    80001c3e:	020005b7          	lui	a1,0x2000
    80001c42:	15fd                	addi	a1,a1,-1
    80001c44:	05b6                	slli	a1,a1,0xd
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	4ce080e7          	jalr	1230(ra) # 80001116 <mappages>
    80001c50:	02054163          	bltz	a0,80001c72 <proc_pagetable+0x76>
}
    80001c54:	8526                	mv	a0,s1
    80001c56:	60e2                	ld	ra,24(sp)
    80001c58:	6442                	ld	s0,16(sp)
    80001c5a:	64a2                	ld	s1,8(sp)
    80001c5c:	6902                	ld	s2,0(sp)
    80001c5e:	6105                	addi	sp,sp,32
    80001c60:	8082                	ret
    uvmfree(pagetable, 0);
    80001c62:	4581                	li	a1,0
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	908080e7          	jalr	-1784(ra) # 8000156e <uvmfree>
    return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	b7d5                	j	80001c54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c72:	4681                	li	a3,0
    80001c74:	4605                	li	a2,1
    80001c76:	040005b7          	lui	a1,0x4000
    80001c7a:	15fd                	addi	a1,a1,-1
    80001c7c:	05b2                	slli	a1,a1,0xc
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	62e080e7          	jalr	1582(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c88:	4581                	li	a1,0
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	8e2080e7          	jalr	-1822(ra) # 8000156e <uvmfree>
    return 0;
    80001c94:	4481                	li	s1,0
    80001c96:	bf7d                	j	80001c54 <proc_pagetable+0x58>

0000000080001c98 <proc_freepagetable>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	e04a                	sd	s2,0(sp)
    80001ca2:	1000                	addi	s0,sp,32
    80001ca4:	84aa                	mv	s1,a0
    80001ca6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca8:	4681                	li	a3,0
    80001caa:	4605                	li	a2,1
    80001cac:	040005b7          	lui	a1,0x4000
    80001cb0:	15fd                	addi	a1,a1,-1
    80001cb2:	05b2                	slli	a1,a1,0xc
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	5fa080e7          	jalr	1530(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cbc:	4681                	li	a3,0
    80001cbe:	4605                	li	a2,1
    80001cc0:	020005b7          	lui	a1,0x2000
    80001cc4:	15fd                	addi	a1,a1,-1
    80001cc6:	05b6                	slli	a1,a1,0xd
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	5e4080e7          	jalr	1508(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001cd2:	85ca                	mv	a1,s2
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	898080e7          	jalr	-1896(ra) # 8000156e <uvmfree>
}
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6902                	ld	s2,0(sp)
    80001ce6:	6105                	addi	sp,sp,32
    80001ce8:	8082                	ret

0000000080001cea <freeproc>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	1000                	addi	s0,sp,32
    80001cf4:	84aa                	mv	s1,a0
  getportion(p);
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	be4080e7          	jalr	-1052(ra) # 800018da <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cfe:	16c4a783          	lw	a5,364(s1)
    80001d02:	1704a703          	lw	a4,368(s1)
    80001d06:	1744a683          	lw	a3,372(s1)
    80001d0a:	5c90                	lw	a2,56(s1)
    80001d0c:	15848593          	addi	a1,s1,344
    80001d10:	00006517          	auipc	a0,0x6
    80001d14:	52050513          	addi	a0,a0,1312 # 80008230 <digits+0x1f0>
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	872080e7          	jalr	-1934(ra) # 8000058a <printf>
  if (p->trapframe)
    80001d20:	6ca8                	ld	a0,88(s1)
    80001d22:	c509                	beqz	a0,80001d2c <freeproc+0x42>
    kfree((void *)p->trapframe);
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	cec080e7          	jalr	-788(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001d2c:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001d30:	68a8                	ld	a0,80(s1)
    80001d32:	c511                	beqz	a0,80001d3e <freeproc+0x54>
    proc_freepagetable(p->pagetable, p->sz);
    80001d34:	64ac                	ld	a1,72(s1)
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	f62080e7          	jalr	-158(ra) # 80001c98 <proc_freepagetable>
  p->pagetable = 0;
    80001d3e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d42:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d46:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d4a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d4e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d52:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d56:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d5a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d5e:	0004ac23          	sw	zero,24(s1)
  p->change = 0;
    80001d62:	1604a423          	sw	zero,360(s1)
  p->Qtime[2] = 0;
    80001d66:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001d6a:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001d6e:	1604a623          	sw	zero,364(s1)
  p->priority = 0;
    80001d72:	1604ac23          	sw	zero,376(s1)
  movequeue(p, 0, DELETE);
    80001d76:	4609                	li	a2,2
    80001d78:	4581                	li	a1,0
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	c12080e7          	jalr	-1006(ra) # 8000198e <movequeue>
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6105                	addi	sp,sp,32
    80001d8c:	8082                	ret

0000000080001d8e <allocproc>:
{
    80001d8e:	1101                	addi	sp,sp,-32
    80001d90:	ec06                	sd	ra,24(sp)
    80001d92:	e822                	sd	s0,16(sp)
    80001d94:	e426                	sd	s1,8(sp)
    80001d96:	e04a                	sd	s2,0(sp)
    80001d98:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d9a:	00010497          	auipc	s1,0x10
    80001d9e:	5ce48493          	addi	s1,s1,1486 # 80012368 <proc>
    80001da2:	00016917          	auipc	s2,0x16
    80001da6:	5c690913          	addi	s2,s2,1478 # 80018368 <tickslock>
    acquire(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	e50080e7          	jalr	-432(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001db4:	4c9c                	lw	a5,24(s1)
    80001db6:	cf81                	beqz	a5,80001dce <allocproc+0x40>
      release(&p->lock);
    80001db8:	8526                	mv	a0,s1
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	ef6080e7          	jalr	-266(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc2:	18048493          	addi	s1,s1,384
    80001dc6:	ff2492e3          	bne	s1,s2,80001daa <allocproc+0x1c>
  return 0;
    80001dca:	4481                	li	s1,0
    80001dcc:	a0b9                	j	80001e1a <allocproc+0x8c>
  p->pid = allocpid();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	de8080e7          	jalr	-536(ra) # 80001bb6 <allocpid>
    80001dd6:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	d34080e7          	jalr	-716(ra) # 80000b0c <kalloc>
    80001de0:	892a                	mv	s2,a0
    80001de2:	eca8                	sd	a0,88(s1)
    80001de4:	c131                	beqz	a0,80001e28 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001de6:	8526                	mv	a0,s1
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	e14080e7          	jalr	-492(ra) # 80001bfc <proc_pagetable>
    80001df0:	892a                	mv	s2,a0
    80001df2:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001df4:	c129                	beqz	a0,80001e36 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001df6:	07000613          	li	a2,112
    80001dfa:	4581                	li	a1,0
    80001dfc:	06048513          	addi	a0,s1,96
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	ef8080e7          	jalr	-264(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001e08:	00000797          	auipc	a5,0x0
    80001e0c:	d6878793          	addi	a5,a5,-664 # 80001b70 <forkret>
    80001e10:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e12:	60bc                	ld	a5,64(s1)
    80001e14:	6705                	lui	a4,0x1
    80001e16:	97ba                	add	a5,a5,a4
    80001e18:	f4bc                	sd	a5,104(s1)
}
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	60e2                	ld	ra,24(sp)
    80001e1e:	6442                	ld	s0,16(sp)
    80001e20:	64a2                	ld	s1,8(sp)
    80001e22:	6902                	ld	s2,0(sp)
    80001e24:	6105                	addi	sp,sp,32
    80001e26:	8082                	ret
    release(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e86080e7          	jalr	-378(ra) # 80000cb0 <release>
    return 0;
    80001e32:	84ca                	mv	s1,s2
    80001e34:	b7dd                	j	80001e1a <allocproc+0x8c>
    freeproc(p);
    80001e36:	8526                	mv	a0,s1
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	eb2080e7          	jalr	-334(ra) # 80001cea <freeproc>
    release(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e6e080e7          	jalr	-402(ra) # 80000cb0 <release>
    return 0;
    80001e4a:	84ca                	mv	s1,s2
    80001e4c:	b7f9                	j	80001e1a <allocproc+0x8c>

0000000080001e4e <userinit>:
{
    80001e4e:	1101                	addi	sp,sp,-32
    80001e50:	ec06                	sd	ra,24(sp)
    80001e52:	e822                	sd	s0,16(sp)
    80001e54:	e426                	sd	s1,8(sp)
    80001e56:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	f36080e7          	jalr	-202(ra) # 80001d8e <allocproc>
    80001e60:	84aa                	mv	s1,a0
  initproc = p;
    80001e62:	00007797          	auipc	a5,0x7
    80001e66:	1aa7bb23          	sd	a0,438(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e6a:	03400613          	li	a2,52
    80001e6e:	00007597          	auipc	a1,0x7
    80001e72:	a3258593          	addi	a1,a1,-1486 # 800088a0 <initcode>
    80001e76:	6928                	ld	a0,80(a0)
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	528080e7          	jalr	1320(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e80:	6785                	lui	a5,0x1
    80001e82:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e84:	6cb8                	ld	a4,88(s1)
    80001e86:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e8a:	6cb8                	ld	a4,88(s1)
    80001e8c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e8e:	4641                	li	a2,16
    80001e90:	00006597          	auipc	a1,0x6
    80001e94:	3d058593          	addi	a1,a1,976 # 80008260 <digits+0x220>
    80001e98:	15848513          	addi	a0,s1,344
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	fae080e7          	jalr	-82(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001ea4:	00006517          	auipc	a0,0x6
    80001ea8:	3cc50513          	addi	a0,a0,972 # 80008270 <digits+0x230>
    80001eac:	00002097          	auipc	ra,0x2
    80001eb0:	290080e7          	jalr	656(ra) # 8000413c <namei>
    80001eb4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eb8:	4789                	li	a5,2
    80001eba:	cc9c                	sw	a5,24(s1)
  movequeue(p, 2, INSERT);
    80001ebc:	4605                	li	a2,1
    80001ebe:	4589                	li	a1,2
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	00000097          	auipc	ra,0x0
    80001ec6:	acc080e7          	jalr	-1332(ra) # 8000198e <movequeue>
  p->Qtime[2] = 0;
    80001eca:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001ece:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001ed2:	1604a623          	sw	zero,364(s1)
  release(&p->lock);
    80001ed6:	8526                	mv	a0,s1
    80001ed8:	fffff097          	auipc	ra,0xfffff
    80001edc:	dd8080e7          	jalr	-552(ra) # 80000cb0 <release>
}
    80001ee0:	60e2                	ld	ra,24(sp)
    80001ee2:	6442                	ld	s0,16(sp)
    80001ee4:	64a2                	ld	s1,8(sp)
    80001ee6:	6105                	addi	sp,sp,32
    80001ee8:	8082                	ret

0000000080001eea <growproc>:
{
    80001eea:	1101                	addi	sp,sp,-32
    80001eec:	ec06                	sd	ra,24(sp)
    80001eee:	e822                	sd	s0,16(sp)
    80001ef0:	e426                	sd	s1,8(sp)
    80001ef2:	e04a                	sd	s2,0(sp)
    80001ef4:	1000                	addi	s0,sp,32
    80001ef6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	c3e080e7          	jalr	-962(ra) # 80001b36 <myproc>
    80001f00:	892a                	mv	s2,a0
  sz = p->sz;
    80001f02:	652c                	ld	a1,72(a0)
    80001f04:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001f08:	00904f63          	bgtz	s1,80001f26 <growproc+0x3c>
  else if (n < 0)
    80001f0c:	0204cc63          	bltz	s1,80001f44 <growproc+0x5a>
  p->sz = sz;
    80001f10:	1602                	slli	a2,a2,0x20
    80001f12:	9201                	srli	a2,a2,0x20
    80001f14:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f18:	4501                	li	a0,0
}
    80001f1a:	60e2                	ld	ra,24(sp)
    80001f1c:	6442                	ld	s0,16(sp)
    80001f1e:	64a2                	ld	s1,8(sp)
    80001f20:	6902                	ld	s2,0(sp)
    80001f22:	6105                	addi	sp,sp,32
    80001f24:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f26:	9e25                	addw	a2,a2,s1
    80001f28:	1602                	slli	a2,a2,0x20
    80001f2a:	9201                	srli	a2,a2,0x20
    80001f2c:	1582                	slli	a1,a1,0x20
    80001f2e:	9181                	srli	a1,a1,0x20
    80001f30:	6928                	ld	a0,80(a0)
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	528080e7          	jalr	1320(ra) # 8000145a <uvmalloc>
    80001f3a:	0005061b          	sext.w	a2,a0
    80001f3e:	fa69                	bnez	a2,80001f10 <growproc+0x26>
      return -1;
    80001f40:	557d                	li	a0,-1
    80001f42:	bfe1                	j	80001f1a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f44:	9e25                	addw	a2,a2,s1
    80001f46:	1602                	slli	a2,a2,0x20
    80001f48:	9201                	srli	a2,a2,0x20
    80001f4a:	1582                	slli	a1,a1,0x20
    80001f4c:	9181                	srli	a1,a1,0x20
    80001f4e:	6928                	ld	a0,80(a0)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	4c2080e7          	jalr	1218(ra) # 80001412 <uvmdealloc>
    80001f58:	0005061b          	sext.w	a2,a0
    80001f5c:	bf55                	j	80001f10 <growproc+0x26>

0000000080001f5e <fork>:
{
    80001f5e:	7139                	addi	sp,sp,-64
    80001f60:	fc06                	sd	ra,56(sp)
    80001f62:	f822                	sd	s0,48(sp)
    80001f64:	f426                	sd	s1,40(sp)
    80001f66:	f04a                	sd	s2,32(sp)
    80001f68:	ec4e                	sd	s3,24(sp)
    80001f6a:	e852                	sd	s4,16(sp)
    80001f6c:	e456                	sd	s5,8(sp)
    80001f6e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	bc6080e7          	jalr	-1082(ra) # 80001b36 <myproc>
    80001f78:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	e14080e7          	jalr	-492(ra) # 80001d8e <allocproc>
    80001f82:	10050163          	beqz	a0,80002084 <fork+0x126>
    80001f86:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f88:	048ab603          	ld	a2,72(s5)
    80001f8c:	692c                	ld	a1,80(a0)
    80001f8e:	050ab503          	ld	a0,80(s5)
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	614080e7          	jalr	1556(ra) # 800015a6 <uvmcopy>
    80001f9a:	04054a63          	bltz	a0,80001fee <fork+0x90>
  np->sz = p->sz;
    80001f9e:	048ab783          	ld	a5,72(s5)
    80001fa2:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001fa6:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001faa:	058ab683          	ld	a3,88(s5)
    80001fae:	87b6                	mv	a5,a3
    80001fb0:	0589b703          	ld	a4,88(s3)
    80001fb4:	12068693          	addi	a3,a3,288
    80001fb8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fbc:	6788                	ld	a0,8(a5)
    80001fbe:	6b8c                	ld	a1,16(a5)
    80001fc0:	6f90                	ld	a2,24(a5)
    80001fc2:	01073023          	sd	a6,0(a4)
    80001fc6:	e708                	sd	a0,8(a4)
    80001fc8:	eb0c                	sd	a1,16(a4)
    80001fca:	ef10                	sd	a2,24(a4)
    80001fcc:	02078793          	addi	a5,a5,32
    80001fd0:	02070713          	addi	a4,a4,32
    80001fd4:	fed792e3          	bne	a5,a3,80001fb8 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001fd8:	0589b783          	ld	a5,88(s3)
    80001fdc:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fe0:	0d0a8493          	addi	s1,s5,208
    80001fe4:	0d098913          	addi	s2,s3,208
    80001fe8:	150a8a13          	addi	s4,s5,336
    80001fec:	a00d                	j	8000200e <fork+0xb0>
    freeproc(np);
    80001fee:	854e                	mv	a0,s3
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	cfa080e7          	jalr	-774(ra) # 80001cea <freeproc>
    release(&np->lock);
    80001ff8:	854e                	mv	a0,s3
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	cb6080e7          	jalr	-842(ra) # 80000cb0 <release>
    return -1;
    80002002:	54fd                	li	s1,-1
    80002004:	a0b5                	j	80002070 <fork+0x112>
  for (i = 0; i < NOFILE; i++)
    80002006:	04a1                	addi	s1,s1,8
    80002008:	0921                	addi	s2,s2,8
    8000200a:	01448b63          	beq	s1,s4,80002020 <fork+0xc2>
    if (p->ofile[i])
    8000200e:	6088                	ld	a0,0(s1)
    80002010:	d97d                	beqz	a0,80002006 <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80002012:	00002097          	auipc	ra,0x2
    80002016:	7ba080e7          	jalr	1978(ra) # 800047cc <filedup>
    8000201a:	00a93023          	sd	a0,0(s2)
    8000201e:	b7e5                	j	80002006 <fork+0xa8>
  np->cwd = idup(p->cwd);
    80002020:	150ab503          	ld	a0,336(s5)
    80002024:	00002097          	auipc	ra,0x2
    80002028:	92a080e7          	jalr	-1750(ra) # 8000394e <idup>
    8000202c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002030:	4641                	li	a2,16
    80002032:	158a8593          	addi	a1,s5,344
    80002036:	15898513          	addi	a0,s3,344
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	e10080e7          	jalr	-496(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80002042:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002046:	4789                	li	a5,2
    80002048:	00f9ac23          	sw	a5,24(s3)
  movequeue(np, 2, INSERT);
    8000204c:	4605                	li	a2,1
    8000204e:	4589                	li	a1,2
    80002050:	854e                	mv	a0,s3
    80002052:	00000097          	auipc	ra,0x0
    80002056:	93c080e7          	jalr	-1732(ra) # 8000198e <movequeue>
  np->Qtime[2] = 0;
    8000205a:	1609aa23          	sw	zero,372(s3)
  np->Qtime[1] = 0;
    8000205e:	1609a823          	sw	zero,368(s3)
  np->Qtime[0] = 0;
    80002062:	1609a623          	sw	zero,364(s3)
  release(&np->lock);
    80002066:	854e                	mv	a0,s3
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c48080e7          	jalr	-952(ra) # 80000cb0 <release>
}
    80002070:	8526                	mv	a0,s1
    80002072:	70e2                	ld	ra,56(sp)
    80002074:	7442                	ld	s0,48(sp)
    80002076:	74a2                	ld	s1,40(sp)
    80002078:	7902                	ld	s2,32(sp)
    8000207a:	69e2                	ld	s3,24(sp)
    8000207c:	6a42                	ld	s4,16(sp)
    8000207e:	6aa2                	ld	s5,8(sp)
    80002080:	6121                	addi	sp,sp,64
    80002082:	8082                	ret
    return -1;
    80002084:	54fd                	li	s1,-1
    80002086:	b7ed                	j	80002070 <fork+0x112>

0000000080002088 <reparent>:
{
    80002088:	7179                	addi	sp,sp,-48
    8000208a:	f406                	sd	ra,40(sp)
    8000208c:	f022                	sd	s0,32(sp)
    8000208e:	ec26                	sd	s1,24(sp)
    80002090:	e84a                	sd	s2,16(sp)
    80002092:	e44e                	sd	s3,8(sp)
    80002094:	e052                	sd	s4,0(sp)
    80002096:	1800                	addi	s0,sp,48
    80002098:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000209a:	00010497          	auipc	s1,0x10
    8000209e:	2ce48493          	addi	s1,s1,718 # 80012368 <proc>
      pp->parent = initproc;
    800020a2:	00007a17          	auipc	s4,0x7
    800020a6:	f76a0a13          	addi	s4,s4,-138 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800020aa:	00016997          	auipc	s3,0x16
    800020ae:	2be98993          	addi	s3,s3,702 # 80018368 <tickslock>
    800020b2:	a029                	j	800020bc <reparent+0x34>
    800020b4:	18048493          	addi	s1,s1,384
    800020b8:	03348363          	beq	s1,s3,800020de <reparent+0x56>
    if (pp->parent == p)
    800020bc:	709c                	ld	a5,32(s1)
    800020be:	ff279be3          	bne	a5,s2,800020b4 <reparent+0x2c>
      acquire(&pp->lock);
    800020c2:	8526                	mv	a0,s1
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b38080e7          	jalr	-1224(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    800020cc:	000a3783          	ld	a5,0(s4)
    800020d0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bdc080e7          	jalr	-1060(ra) # 80000cb0 <release>
    800020dc:	bfe1                	j	800020b4 <reparent+0x2c>
}
    800020de:	70a2                	ld	ra,40(sp)
    800020e0:	7402                	ld	s0,32(sp)
    800020e2:	64e2                	ld	s1,24(sp)
    800020e4:	6942                	ld	s2,16(sp)
    800020e6:	69a2                	ld	s3,8(sp)
    800020e8:	6a02                	ld	s4,0(sp)
    800020ea:	6145                	addi	sp,sp,48
    800020ec:	8082                	ret

00000000800020ee <scheduler>:
{
    800020ee:	711d                	addi	sp,sp,-96
    800020f0:	ec86                	sd	ra,88(sp)
    800020f2:	e8a2                	sd	s0,80(sp)
    800020f4:	e4a6                	sd	s1,72(sp)
    800020f6:	e0ca                	sd	s2,64(sp)
    800020f8:	fc4e                	sd	s3,56(sp)
    800020fa:	f852                	sd	s4,48(sp)
    800020fc:	f456                	sd	s5,40(sp)
    800020fe:	f05a                	sd	s6,32(sp)
    80002100:	ec5e                	sd	s7,24(sp)
    80002102:	e862                	sd	s8,16(sp)
    80002104:	e466                	sd	s9,8(sp)
    80002106:	e06a                	sd	s10,0(sp)
    80002108:	1080                	addi	s0,sp,96
    8000210a:	8792                	mv	a5,tp
  int id = r_tp();
    8000210c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000210e:	00779c13          	slli	s8,a5,0x7
    80002112:	00010717          	auipc	a4,0x10
    80002116:	83e70713          	addi	a4,a4,-1986 # 80011950 <Q>
    8000211a:	9762                	add	a4,a4,s8
    8000211c:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    80002120:	00010717          	auipc	a4,0x10
    80002124:	e5070713          	addi	a4,a4,-432 # 80011f70 <cpus+0x8>
    80002128:	9c3a                	add	s8,s8,a4
  int exec = 0;
    8000212a:	4b81                	li	s7,0
      switch (p->change)
    8000212c:	4a0d                	li	s4,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000212e:	00016a97          	auipc	s5,0x16
    80002132:	23aa8a93          	addi	s5,s5,570 # 80018368 <tickslock>
        c->proc = p;
    80002136:	00010c97          	auipc	s9,0x10
    8000213a:	81ac8c93          	addi	s9,s9,-2022 # 80011950 <Q>
    8000213e:	079e                	slli	a5,a5,0x7
    80002140:	00fc8b33          	add	s6,s9,a5
    80002144:	a8ed                	j	8000223e <scheduler+0x150>
      exec = 0;
    80002146:	4b81                	li	s7,0
    80002148:	a8e5                	j	80002240 <scheduler+0x152>
        movequeue(p, 0, MOVE);
    8000214a:	4601                	li	a2,0
    8000214c:	4581                	li	a1,0
    8000214e:	8526                	mv	a0,s1
    80002150:	00000097          	auipc	ra,0x0
    80002154:	83e080e7          	jalr	-1986(ra) # 8000198e <movequeue>
      release(&p->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b56080e7          	jalr	-1194(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002162:	18048493          	addi	s1,s1,384
    80002166:	03548f63          	beq	s1,s5,800021a4 <scheduler+0xb6>
      acquire(&p->lock);
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a90080e7          	jalr	-1392(ra) # 80000bfc <acquire>
      switch (p->change)
    80002174:	1684a783          	lw	a5,360(s1)
    80002178:	fd2789e3          	beq	a5,s2,8000214a <scheduler+0x5c>
    8000217c:	01478c63          	beq	a5,s4,80002194 <scheduler+0xa6>
    80002180:	fd379ce3          	bne	a5,s3,80002158 <scheduler+0x6a>
        movequeue(p, 1, MOVE);
    80002184:	4601                	li	a2,0
    80002186:	85ce                	mv	a1,s3
    80002188:	8526                	mv	a0,s1
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	804080e7          	jalr	-2044(ra) # 8000198e <movequeue>
        break;
    80002192:	b7d9                	j	80002158 <scheduler+0x6a>
        movequeue(p, 2, MOVE);
    80002194:	4601                	li	a2,0
    80002196:	85ca                	mv	a1,s2
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	7f4080e7          	jalr	2036(ra) # 8000198e <movequeue>
        break;
    800021a2:	bf5d                	j	80002158 <scheduler+0x6a>
    int tail2 = findproc(0, 2) - 1;
    800021a4:	85ca                	mv	a1,s2
    800021a6:	4501                	li	a0,0
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	7a8080e7          	jalr	1960(ra) # 80001950 <findproc>
    for (int i = 0; i <= tail2; i++)
    800021b0:	06a05263          	blez	a0,80002214 <scheduler+0x126>
    800021b4:	00010997          	auipc	s3,0x10
    800021b8:	b9c98993          	addi	s3,s3,-1124 # 80011d50 <Q+0x400>
    800021bc:	fff50d1b          	addiw	s10,a0,-1
    800021c0:	020d1793          	slli	a5,s10,0x20
    800021c4:	01d7dd13          	srli	s10,a5,0x1d
    800021c8:	00010797          	auipc	a5,0x10
    800021cc:	b9078793          	addi	a5,a5,-1136 # 80011d58 <Q+0x408>
    800021d0:	9d3e                	add	s10,s10,a5
    800021d2:	a809                	j	800021e4 <scheduler+0xf6>
      release(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	ada080e7          	jalr	-1318(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    800021de:	09a1                	addi	s3,s3,8
    800021e0:	03a98a63          	beq	s3,s10,80002214 <scheduler+0x126>
      p = Q[2][i];
    800021e4:	0009b483          	ld	s1,0(s3)
      acquire(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	a12080e7          	jalr	-1518(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    800021f2:	4c9c                	lw	a5,24(s1)
    800021f4:	ff2790e3          	bne	a5,s2,800021d4 <scheduler+0xe6>
        p->state = RUNNING;
    800021f8:	0144ac23          	sw	s4,24(s1)
        c->proc = p;
    800021fc:	609b3c23          	sd	s1,1560(s6) # 1618 <_entry-0x7fffe9e8>
        swtch(&c->context, &p->context);
    80002200:	06048593          	addi	a1,s1,96
    80002204:	8562                	mv	a0,s8
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	704080e7          	jalr	1796(ra) # 8000290a <swtch>
        c->proc = 0;
    8000220e:	600b3c23          	sd	zero,1560(s6)
    80002212:	b7c9                	j	800021d4 <scheduler+0xe6>
    p = Q[1][exec];
    80002214:	040b8793          	addi	a5,s7,64
    80002218:	078e                	slli	a5,a5,0x3
    8000221a:	97e6                	add	a5,a5,s9
    8000221c:	6384                	ld	s1,0(a5)
    if (p == 0)
    8000221e:	d485                	beqz	s1,80002146 <scheduler+0x58>
    acquire(&p->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9da080e7          	jalr	-1574(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000222a:	4c98                	lw	a4,24(s1)
    8000222c:	4789                	li	a5,2
    8000222e:	02f70563          	beq	a4,a5,80002258 <scheduler+0x16a>
    release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a7c080e7          	jalr	-1412(ra) # 80000cb0 <release>
    exec++;
    8000223c:	2b85                	addiw	s7,s7,1
      switch (p->change)
    8000223e:	4909                	li	s2,2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002240:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002244:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002248:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000224c:	00010497          	auipc	s1,0x10
    80002250:	11c48493          	addi	s1,s1,284 # 80012368 <proc>
      switch (p->change)
    80002254:	4985                	li	s3,1
    80002256:	bf11                	j	8000216a <scheduler+0x7c>
      p->state = RUNNING;
    80002258:	0144ac23          	sw	s4,24(s1)
      c->proc = p;
    8000225c:	609b3c23          	sd	s1,1560(s6)
      swtch(&c->context, &p->context);
    80002260:	06048593          	addi	a1,s1,96
    80002264:	8562                	mv	a0,s8
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	6a4080e7          	jalr	1700(ra) # 8000290a <swtch>
      c->proc = 0;
    8000226e:	600b3c23          	sd	zero,1560(s6)
    80002272:	b7c1                	j	80002232 <scheduler+0x144>

0000000080002274 <sched>:
{
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	8b4080e7          	jalr	-1868(ra) # 80001b36 <myproc>
    8000228a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	8f6080e7          	jalr	-1802(ra) # 80000b82 <holding>
    80002294:	c93d                	beqz	a0,8000230a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002296:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002298:	2781                	sext.w	a5,a5
    8000229a:	079e                	slli	a5,a5,0x7
    8000229c:	0000f717          	auipc	a4,0xf
    800022a0:	6b470713          	addi	a4,a4,1716 # 80011950 <Q>
    800022a4:	97ba                	add	a5,a5,a4
    800022a6:	6907a703          	lw	a4,1680(a5)
    800022aa:	4785                	li	a5,1
    800022ac:	06f71763          	bne	a4,a5,8000231a <sched+0xa6>
  if (p->state == RUNNING)
    800022b0:	4c98                	lw	a4,24(s1)
    800022b2:	478d                	li	a5,3
    800022b4:	06f70b63          	beq	a4,a5,8000232a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022bc:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022be:	efb5                	bnez	a5,8000233a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022c2:	0000f917          	auipc	s2,0xf
    800022c6:	68e90913          	addi	s2,s2,1678 # 80011950 <Q>
    800022ca:	2781                	sext.w	a5,a5
    800022cc:	079e                	slli	a5,a5,0x7
    800022ce:	97ca                	add	a5,a5,s2
    800022d0:	6947a983          	lw	s3,1684(a5)
    800022d4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d6:	2781                	sext.w	a5,a5
    800022d8:	079e                	slli	a5,a5,0x7
    800022da:	00010597          	auipc	a1,0x10
    800022de:	c9658593          	addi	a1,a1,-874 # 80011f70 <cpus+0x8>
    800022e2:	95be                	add	a1,a1,a5
    800022e4:	06048513          	addi	a0,s1,96
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	622080e7          	jalr	1570(ra) # 8000290a <swtch>
    800022f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022f2:	2781                	sext.w	a5,a5
    800022f4:	079e                	slli	a5,a5,0x7
    800022f6:	97ca                	add	a5,a5,s2
    800022f8:	6937aa23          	sw	s3,1684(a5)
}
    800022fc:	70a2                	ld	ra,40(sp)
    800022fe:	7402                	ld	s0,32(sp)
    80002300:	64e2                	ld	s1,24(sp)
    80002302:	6942                	ld	s2,16(sp)
    80002304:	69a2                	ld	s3,8(sp)
    80002306:	6145                	addi	sp,sp,48
    80002308:	8082                	ret
    panic("sched p->lock");
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	f6e50513          	addi	a0,a0,-146 # 80008278 <digits+0x238>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	22e080e7          	jalr	558(ra) # 80000540 <panic>
    panic("sched locks");
    8000231a:	00006517          	auipc	a0,0x6
    8000231e:	f6e50513          	addi	a0,a0,-146 # 80008288 <digits+0x248>
    80002322:	ffffe097          	auipc	ra,0xffffe
    80002326:	21e080e7          	jalr	542(ra) # 80000540 <panic>
    panic("sched running");
    8000232a:	00006517          	auipc	a0,0x6
    8000232e:	f6e50513          	addi	a0,a0,-146 # 80008298 <digits+0x258>
    80002332:	ffffe097          	auipc	ra,0xffffe
    80002336:	20e080e7          	jalr	526(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	f6e50513          	addi	a0,a0,-146 # 800082a8 <digits+0x268>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fe080e7          	jalr	510(ra) # 80000540 <panic>

000000008000234a <exit>:
{
    8000234a:	7179                	addi	sp,sp,-48
    8000234c:	f406                	sd	ra,40(sp)
    8000234e:	f022                	sd	s0,32(sp)
    80002350:	ec26                	sd	s1,24(sp)
    80002352:	e84a                	sd	s2,16(sp)
    80002354:	e44e                	sd	s3,8(sp)
    80002356:	e052                	sd	s4,0(sp)
    80002358:	1800                	addi	s0,sp,48
    8000235a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	7da080e7          	jalr	2010(ra) # 80001b36 <myproc>
    80002364:	892a                	mv	s2,a0
  if (p == initproc)
    80002366:	00007797          	auipc	a5,0x7
    8000236a:	cb27b783          	ld	a5,-846(a5) # 80009018 <initproc>
    8000236e:	0d050493          	addi	s1,a0,208
    80002372:	15050993          	addi	s3,a0,336
    80002376:	02a79363          	bne	a5,a0,8000239c <exit+0x52>
    panic("init exiting");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	f4650513          	addi	a0,a0,-186 # 800082c0 <digits+0x280>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1be080e7          	jalr	446(ra) # 80000540 <panic>
      fileclose(f);
    8000238a:	00002097          	auipc	ra,0x2
    8000238e:	494080e7          	jalr	1172(ra) # 8000481e <fileclose>
      p->ofile[fd] = 0;
    80002392:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002396:	04a1                	addi	s1,s1,8
    80002398:	01348563          	beq	s1,s3,800023a2 <exit+0x58>
    if (p->ofile[fd])
    8000239c:	6088                	ld	a0,0(s1)
    8000239e:	f575                	bnez	a0,8000238a <exit+0x40>
    800023a0:	bfdd                	j	80002396 <exit+0x4c>
  begin_op();
    800023a2:	00002097          	auipc	ra,0x2
    800023a6:	faa080e7          	jalr	-86(ra) # 8000434c <begin_op>
  iput(p->cwd);
    800023aa:	15093503          	ld	a0,336(s2)
    800023ae:	00001097          	auipc	ra,0x1
    800023b2:	798080e7          	jalr	1944(ra) # 80003b46 <iput>
  end_op();
    800023b6:	00002097          	auipc	ra,0x2
    800023ba:	016080e7          	jalr	22(ra) # 800043cc <end_op>
  p->cwd = 0;
    800023be:	14093823          	sd	zero,336(s2)
  acquire(&initproc->lock);
    800023c2:	00007497          	auipc	s1,0x7
    800023c6:	c5648493          	addi	s1,s1,-938 # 80009018 <initproc>
    800023ca:	6088                	ld	a0,0(s1)
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	830080e7          	jalr	-2000(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    800023d4:	6088                	ld	a0,0(s1)
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	4a2080e7          	jalr	1186(ra) # 80001878 <wakeup1>
  release(&initproc->lock);
    800023de:	6088                	ld	a0,0(s1)
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8d0080e7          	jalr	-1840(ra) # 80000cb0 <release>
  acquire(&p->lock);
    800023e8:	854a                	mv	a0,s2
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	812080e7          	jalr	-2030(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    800023f2:	02093483          	ld	s1,32(s2)
  release(&p->lock);
    800023f6:	854a                	mv	a0,s2
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	8b8080e7          	jalr	-1864(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7fa080e7          	jalr	2042(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    8000240a:	854a                	mv	a0,s2
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	7f0080e7          	jalr	2032(ra) # 80000bfc <acquire>
  reparent(p);
    80002414:	854a                	mv	a0,s2
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	c72080e7          	jalr	-910(ra) # 80002088 <reparent>
  wakeup1(original_parent);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	458080e7          	jalr	1112(ra) # 80001878 <wakeup1>
  p->xstate = status;
    80002428:	03492a23          	sw	s4,52(s2)
  p->state = ZOMBIE;
    8000242c:	4791                	li	a5,4
    8000242e:	00f92c23          	sw	a5,24(s2)
  p->change = 2;
    80002432:	4789                	li	a5,2
    80002434:	16f92423          	sw	a5,360(s2)
  p->zzstart = ticks;
    80002438:	00007797          	auipc	a5,0x7
    8000243c:	be87a783          	lw	a5,-1048(a5) # 80009020 <ticks>
    80002440:	16f92e23          	sw	a5,380(s2)
  release(&original_parent->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	86a080e7          	jalr	-1942(ra) # 80000cb0 <release>
  sched();
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	e26080e7          	jalr	-474(ra) # 80002274 <sched>
  panic("zombie exit");
    80002456:	00006517          	auipc	a0,0x6
    8000245a:	e7a50513          	addi	a0,a0,-390 # 800082d0 <digits+0x290>
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	0e2080e7          	jalr	226(ra) # 80000540 <panic>

0000000080002466 <yield>:
{
    80002466:	1101                	addi	sp,sp,-32
    80002468:	ec06                	sd	ra,24(sp)
    8000246a:	e822                	sd	s0,16(sp)
    8000246c:	e426                	sd	s1,8(sp)
    8000246e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	6c6080e7          	jalr	1734(ra) # 80001b36 <myproc>
    80002478:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	782080e7          	jalr	1922(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    80002482:	4789                	li	a5,2
    80002484:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    80002486:	1784a703          	lw	a4,376(s1)
    8000248a:	02f70363          	beq	a4,a5,800024b0 <yield+0x4a>
  else if (p->priority == 1)
    8000248e:	4785                	li	a5,1
    80002490:	02f70963          	beq	a4,a5,800024c2 <yield+0x5c>
  sched();
    80002494:	00000097          	auipc	ra,0x0
    80002498:	de0080e7          	jalr	-544(ra) # 80002274 <sched>
  release(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	812080e7          	jalr	-2030(ra) # 80000cb0 <release>
}
    800024a6:	60e2                	ld	ra,24(sp)
    800024a8:	6442                	ld	s0,16(sp)
    800024aa:	64a2                	ld	s1,8(sp)
    800024ac:	6105                	addi	sp,sp,32
    800024ae:	8082                	ret
    p->change = 1;
    800024b0:	4785                	li	a5,1
    800024b2:	16f4a423          	sw	a5,360(s1)
    (p->Qtime[2])++;
    800024b6:	1744a783          	lw	a5,372(s1)
    800024ba:	2785                	addiw	a5,a5,1
    800024bc:	16f4aa23          	sw	a5,372(s1)
    800024c0:	bfd1                	j	80002494 <yield+0x2e>
    (p->Qtime[1])++;
    800024c2:	1704a783          	lw	a5,368(s1)
    800024c6:	2785                	addiw	a5,a5,1
    800024c8:	16f4a823          	sw	a5,368(s1)
    800024cc:	b7e1                	j	80002494 <yield+0x2e>

00000000800024ce <sleep>:
{
    800024ce:	7179                	addi	sp,sp,-48
    800024d0:	f406                	sd	ra,40(sp)
    800024d2:	f022                	sd	s0,32(sp)
    800024d4:	ec26                	sd	s1,24(sp)
    800024d6:	e84a                	sd	s2,16(sp)
    800024d8:	e44e                	sd	s3,8(sp)
    800024da:	1800                	addi	s0,sp,48
    800024dc:	89aa                	mv	s3,a0
    800024de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	656080e7          	jalr	1622(ra) # 80001b36 <myproc>
    800024e8:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    800024ea:	05250f63          	beq	a0,s2,80002548 <sleep+0x7a>
    acquire(&p->lock); //DOC: sleeplock1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	70e080e7          	jalr	1806(ra) # 80000bfc <acquire>
    release(lk);
    800024f6:	854a                	mv	a0,s2
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	7b8080e7          	jalr	1976(ra) # 80000cb0 <release>
  p->chan = chan;
    80002500:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002504:	4785                	li	a5,1
    80002506:	cc9c                	sw	a5,24(s1)
  p->change = 2;
    80002508:	4789                	li	a5,2
    8000250a:	16f4a423          	sw	a5,360(s1)
  p->zzstart = ticks;
    8000250e:	00007797          	auipc	a5,0x7
    80002512:	b127a783          	lw	a5,-1262(a5) # 80009020 <ticks>
    80002516:	16f4ae23          	sw	a5,380(s1)
  sched();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	d5a080e7          	jalr	-678(ra) # 80002274 <sched>
  p->chan = 0;
    80002522:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	788080e7          	jalr	1928(ra) # 80000cb0 <release>
    acquire(lk);
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	6ca080e7          	jalr	1738(ra) # 80000bfc <acquire>
}
    8000253a:	70a2                	ld	ra,40(sp)
    8000253c:	7402                	ld	s0,32(sp)
    8000253e:	64e2                	ld	s1,24(sp)
    80002540:	6942                	ld	s2,16(sp)
    80002542:	69a2                	ld	s3,8(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret
  p->chan = chan;
    80002548:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000254c:	4785                	li	a5,1
    8000254e:	cd1c                	sw	a5,24(a0)
  p->change = 2;
    80002550:	4789                	li	a5,2
    80002552:	16f52423          	sw	a5,360(a0)
  p->zzstart = ticks;
    80002556:	00007797          	auipc	a5,0x7
    8000255a:	aca7a783          	lw	a5,-1334(a5) # 80009020 <ticks>
    8000255e:	16f52e23          	sw	a5,380(a0)
  sched();
    80002562:	00000097          	auipc	ra,0x0
    80002566:	d12080e7          	jalr	-750(ra) # 80002274 <sched>
  p->chan = 0;
    8000256a:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    8000256e:	b7f1                	j	8000253a <sleep+0x6c>

0000000080002570 <wait>:
{
    80002570:	715d                	addi	sp,sp,-80
    80002572:	e486                	sd	ra,72(sp)
    80002574:	e0a2                	sd	s0,64(sp)
    80002576:	fc26                	sd	s1,56(sp)
    80002578:	f84a                	sd	s2,48(sp)
    8000257a:	f44e                	sd	s3,40(sp)
    8000257c:	f052                	sd	s4,32(sp)
    8000257e:	ec56                	sd	s5,24(sp)
    80002580:	e85a                	sd	s6,16(sp)
    80002582:	e45e                	sd	s7,8(sp)
    80002584:	0880                	addi	s0,sp,80
    80002586:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	5ae080e7          	jalr	1454(ra) # 80001b36 <myproc>
    80002590:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	66a080e7          	jalr	1642(ra) # 80000bfc <acquire>
    havekids = 0;
    8000259a:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000259c:	4a11                	li	s4,4
        havekids = 1;
    8000259e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800025a0:	00016997          	auipc	s3,0x16
    800025a4:	dc898993          	addi	s3,s3,-568 # 80018368 <tickslock>
    havekids = 0;
    800025a8:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025aa:	00010497          	auipc	s1,0x10
    800025ae:	dbe48493          	addi	s1,s1,-578 # 80012368 <proc>
    800025b2:	a8b5                	j	8000262e <wait+0xbe>
          pid = np->pid;
    800025b4:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025b8:	000b0e63          	beqz	s6,800025d4 <wait+0x64>
    800025bc:	4691                	li	a3,4
    800025be:	03448613          	addi	a2,s1,52
    800025c2:	85da                	mv	a1,s6
    800025c4:	05093503          	ld	a0,80(s2)
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	0e2080e7          	jalr	226(ra) # 800016aa <copyout>
    800025d0:	02054f63          	bltz	a0,8000260e <wait+0x9e>
          np->Qtime[0] = np->Qtime[0] + ticks - p->zzstart;
    800025d4:	17c92703          	lw	a4,380(s2)
    800025d8:	00007797          	auipc	a5,0x7
    800025dc:	a487a783          	lw	a5,-1464(a5) # 80009020 <ticks>
    800025e0:	40e7873b          	subw	a4,a5,a4
    800025e4:	16c4a783          	lw	a5,364(s1)
    800025e8:	9fb9                	addw	a5,a5,a4
    800025ea:	16f4a623          	sw	a5,364(s1)
          freeproc(np);
    800025ee:	8526                	mv	a0,s1
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	6fa080e7          	jalr	1786(ra) # 80001cea <freeproc>
          release(&np->lock);
    800025f8:	8526                	mv	a0,s1
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	6b6080e7          	jalr	1718(ra) # 80000cb0 <release>
          release(&p->lock);
    80002602:	854a                	mv	a0,s2
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	6ac080e7          	jalr	1708(ra) # 80000cb0 <release>
          return pid;
    8000260c:	a8a9                	j	80002666 <wait+0xf6>
            release(&np->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	6a0080e7          	jalr	1696(ra) # 80000cb0 <release>
            release(&p->lock);
    80002618:	854a                	mv	a0,s2
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	696080e7          	jalr	1686(ra) # 80000cb0 <release>
            return -1;
    80002622:	59fd                	li	s3,-1
    80002624:	a089                	j	80002666 <wait+0xf6>
    for (np = proc; np < &proc[NPROC]; np++)
    80002626:	18048493          	addi	s1,s1,384
    8000262a:	03348463          	beq	s1,s3,80002652 <wait+0xe2>
      if (np->parent == p)
    8000262e:	709c                	ld	a5,32(s1)
    80002630:	ff279be3          	bne	a5,s2,80002626 <wait+0xb6>
        acquire(&np->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	5c6080e7          	jalr	1478(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    8000263e:	4c9c                	lw	a5,24(s1)
    80002640:	f7478ae3          	beq	a5,s4,800025b4 <wait+0x44>
        release(&np->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	66a080e7          	jalr	1642(ra) # 80000cb0 <release>
        havekids = 1;
    8000264e:	8756                	mv	a4,s5
    80002650:	bfd9                	j	80002626 <wait+0xb6>
    if (!havekids || p->killed)
    80002652:	c701                	beqz	a4,8000265a <wait+0xea>
    80002654:	03092783          	lw	a5,48(s2)
    80002658:	c39d                	beqz	a5,8000267e <wait+0x10e>
      release(&p->lock);
    8000265a:	854a                	mv	a0,s2
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	654080e7          	jalr	1620(ra) # 80000cb0 <release>
      return -1;
    80002664:	59fd                	li	s3,-1
}
    80002666:	854e                	mv	a0,s3
    80002668:	60a6                	ld	ra,72(sp)
    8000266a:	6406                	ld	s0,64(sp)
    8000266c:	74e2                	ld	s1,56(sp)
    8000266e:	7942                	ld	s2,48(sp)
    80002670:	79a2                	ld	s3,40(sp)
    80002672:	7a02                	ld	s4,32(sp)
    80002674:	6ae2                	ld	s5,24(sp)
    80002676:	6b42                	ld	s6,16(sp)
    80002678:	6ba2                	ld	s7,8(sp)
    8000267a:	6161                	addi	sp,sp,80
    8000267c:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    8000267e:	85ca                	mv	a1,s2
    80002680:	854a                	mv	a0,s2
    80002682:	00000097          	auipc	ra,0x0
    80002686:	e4c080e7          	jalr	-436(ra) # 800024ce <sleep>
    havekids = 0;
    8000268a:	bf39                	j	800025a8 <wait+0x38>

000000008000268c <wakeup>:
{
    8000268c:	715d                	addi	sp,sp,-80
    8000268e:	e486                	sd	ra,72(sp)
    80002690:	e0a2                	sd	s0,64(sp)
    80002692:	fc26                	sd	s1,56(sp)
    80002694:	f84a                	sd	s2,48(sp)
    80002696:	f44e                	sd	s3,40(sp)
    80002698:	f052                	sd	s4,32(sp)
    8000269a:	ec56                	sd	s5,24(sp)
    8000269c:	e85a                	sd	s6,16(sp)
    8000269e:	e45e                	sd	s7,8(sp)
    800026a0:	0880                	addi	s0,sp,80
    800026a2:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800026a4:	00010497          	auipc	s1,0x10
    800026a8:	cc448493          	addi	s1,s1,-828 # 80012368 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800026ac:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026ae:	4b89                	li	s7,2
      p->change = 3;
    800026b0:	4b0d                	li	s6,3
      p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
    800026b2:	00007a97          	auipc	s5,0x7
    800026b6:	96ea8a93          	addi	s5,s5,-1682 # 80009020 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ba:	00016917          	auipc	s2,0x16
    800026be:	cae90913          	addi	s2,s2,-850 # 80018368 <tickslock>
    800026c2:	a811                	j	800026d6 <wakeup+0x4a>
    release(&p->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	5ea080e7          	jalr	1514(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ce:	18048493          	addi	s1,s1,384
    800026d2:	03248c63          	beq	s1,s2,8000270a <wakeup+0x7e>
    acquire(&p->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	524080e7          	jalr	1316(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800026e0:	4c9c                	lw	a5,24(s1)
    800026e2:	ff3791e3          	bne	a5,s3,800026c4 <wakeup+0x38>
    800026e6:	749c                	ld	a5,40(s1)
    800026e8:	fd479ee3          	bne	a5,s4,800026c4 <wakeup+0x38>
      p->state = RUNNABLE;
    800026ec:	0174ac23          	sw	s7,24(s1)
      p->change = 3;
    800026f0:	1764a423          	sw	s6,360(s1)
      p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
    800026f4:	16c4a783          	lw	a5,364(s1)
    800026f8:	000aa703          	lw	a4,0(s5)
    800026fc:	9fb9                	addw	a5,a5,a4
    800026fe:	17c4a703          	lw	a4,380(s1)
    80002702:	9f99                	subw	a5,a5,a4
    80002704:	16f4a623          	sw	a5,364(s1)
    80002708:	bf75                	j	800026c4 <wakeup+0x38>
}
    8000270a:	60a6                	ld	ra,72(sp)
    8000270c:	6406                	ld	s0,64(sp)
    8000270e:	74e2                	ld	s1,56(sp)
    80002710:	7942                	ld	s2,48(sp)
    80002712:	79a2                	ld	s3,40(sp)
    80002714:	7a02                	ld	s4,32(sp)
    80002716:	6ae2                	ld	s5,24(sp)
    80002718:	6b42                	ld	s6,16(sp)
    8000271a:	6ba2                	ld	s7,8(sp)
    8000271c:	6161                	addi	sp,sp,80
    8000271e:	8082                	ret

0000000080002720 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002720:	7179                	addi	sp,sp,-48
    80002722:	f406                	sd	ra,40(sp)
    80002724:	f022                	sd	s0,32(sp)
    80002726:	ec26                	sd	s1,24(sp)
    80002728:	e84a                	sd	s2,16(sp)
    8000272a:	e44e                	sd	s3,8(sp)
    8000272c:	1800                	addi	s0,sp,48
    8000272e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002730:	00010497          	auipc	s1,0x10
    80002734:	c3848493          	addi	s1,s1,-968 # 80012368 <proc>
    80002738:	00016997          	auipc	s3,0x16
    8000273c:	c3098993          	addi	s3,s3,-976 # 80018368 <tickslock>
  {
    acquire(&p->lock);
    80002740:	8526                	mv	a0,s1
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	4ba080e7          	jalr	1210(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    8000274a:	5c9c                	lw	a5,56(s1)
    8000274c:	01278d63          	beq	a5,s2,80002766 <kill+0x46>
        p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	55e080e7          	jalr	1374(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000275a:	18048493          	addi	s1,s1,384
    8000275e:	ff3491e3          	bne	s1,s3,80002740 <kill+0x20>
  }
  return -1;
    80002762:	557d                	li	a0,-1
    80002764:	a821                	j	8000277c <kill+0x5c>
      p->killed = 1;
    80002766:	4785                	li	a5,1
    80002768:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    8000276a:	4c98                	lw	a4,24(s1)
    8000276c:	00f70f63          	beq	a4,a5,8000278a <kill+0x6a>
      release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	53e080e7          	jalr	1342(ra) # 80000cb0 <release>
      return 0;
    8000277a:	4501                	li	a0,0
}
    8000277c:	70a2                	ld	ra,40(sp)
    8000277e:	7402                	ld	s0,32(sp)
    80002780:	64e2                	ld	s1,24(sp)
    80002782:	6942                	ld	s2,16(sp)
    80002784:	69a2                	ld	s3,8(sp)
    80002786:	6145                	addi	sp,sp,48
    80002788:	8082                	ret
        p->state = RUNNABLE;
    8000278a:	4789                	li	a5,2
    8000278c:	cc9c                	sw	a5,24(s1)
        p->change = 3;
    8000278e:	478d                	li	a5,3
    80002790:	16f4a423          	sw	a5,360(s1)
        p->Qtime[0] = p->Qtime[0] + ticks - p->zzstart;
    80002794:	16c4a783          	lw	a5,364(s1)
    80002798:	00007717          	auipc	a4,0x7
    8000279c:	88872703          	lw	a4,-1912(a4) # 80009020 <ticks>
    800027a0:	9fb9                	addw	a5,a5,a4
    800027a2:	17c4a703          	lw	a4,380(s1)
    800027a6:	9f99                	subw	a5,a5,a4
    800027a8:	16f4a623          	sw	a5,364(s1)
    800027ac:	b7d1                	j	80002770 <kill+0x50>

00000000800027ae <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ae:	7179                	addi	sp,sp,-48
    800027b0:	f406                	sd	ra,40(sp)
    800027b2:	f022                	sd	s0,32(sp)
    800027b4:	ec26                	sd	s1,24(sp)
    800027b6:	e84a                	sd	s2,16(sp)
    800027b8:	e44e                	sd	s3,8(sp)
    800027ba:	e052                	sd	s4,0(sp)
    800027bc:	1800                	addi	s0,sp,48
    800027be:	84aa                	mv	s1,a0
    800027c0:	892e                	mv	s2,a1
    800027c2:	89b2                	mv	s3,a2
    800027c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	370080e7          	jalr	880(ra) # 80001b36 <myproc>
  if (user_dst)
    800027ce:	c08d                	beqz	s1,800027f0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027d0:	86d2                	mv	a3,s4
    800027d2:	864e                	mv	a2,s3
    800027d4:	85ca                	mv	a1,s2
    800027d6:	6928                	ld	a0,80(a0)
    800027d8:	fffff097          	auipc	ra,0xfffff
    800027dc:	ed2080e7          	jalr	-302(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027e0:	70a2                	ld	ra,40(sp)
    800027e2:	7402                	ld	s0,32(sp)
    800027e4:	64e2                	ld	s1,24(sp)
    800027e6:	6942                	ld	s2,16(sp)
    800027e8:	69a2                	ld	s3,8(sp)
    800027ea:	6a02                	ld	s4,0(sp)
    800027ec:	6145                	addi	sp,sp,48
    800027ee:	8082                	ret
    memmove((char *)dst, src, len);
    800027f0:	000a061b          	sext.w	a2,s4
    800027f4:	85ce                	mv	a1,s3
    800027f6:	854a                	mv	a0,s2
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	55c080e7          	jalr	1372(ra) # 80000d54 <memmove>
    return 0;
    80002800:	8526                	mv	a0,s1
    80002802:	bff9                	j	800027e0 <either_copyout+0x32>

0000000080002804 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002804:	7179                	addi	sp,sp,-48
    80002806:	f406                	sd	ra,40(sp)
    80002808:	f022                	sd	s0,32(sp)
    8000280a:	ec26                	sd	s1,24(sp)
    8000280c:	e84a                	sd	s2,16(sp)
    8000280e:	e44e                	sd	s3,8(sp)
    80002810:	e052                	sd	s4,0(sp)
    80002812:	1800                	addi	s0,sp,48
    80002814:	892a                	mv	s2,a0
    80002816:	84ae                	mv	s1,a1
    80002818:	89b2                	mv	s3,a2
    8000281a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	31a080e7          	jalr	794(ra) # 80001b36 <myproc>
  if (user_src)
    80002824:	c08d                	beqz	s1,80002846 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002826:	86d2                	mv	a3,s4
    80002828:	864e                	mv	a2,s3
    8000282a:	85ca                	mv	a1,s2
    8000282c:	6928                	ld	a0,80(a0)
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	f08080e7          	jalr	-248(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002836:	70a2                	ld	ra,40(sp)
    80002838:	7402                	ld	s0,32(sp)
    8000283a:	64e2                	ld	s1,24(sp)
    8000283c:	6942                	ld	s2,16(sp)
    8000283e:	69a2                	ld	s3,8(sp)
    80002840:	6a02                	ld	s4,0(sp)
    80002842:	6145                	addi	sp,sp,48
    80002844:	8082                	ret
    memmove(dst, (char *)src, len);
    80002846:	000a061b          	sext.w	a2,s4
    8000284a:	85ce                	mv	a1,s3
    8000284c:	854a                	mv	a0,s2
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	506080e7          	jalr	1286(ra) # 80000d54 <memmove>
    return 0;
    80002856:	8526                	mv	a0,s1
    80002858:	bff9                	j	80002836 <either_copyin+0x32>

000000008000285a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000285a:	715d                	addi	sp,sp,-80
    8000285c:	e486                	sd	ra,72(sp)
    8000285e:	e0a2                	sd	s0,64(sp)
    80002860:	fc26                	sd	s1,56(sp)
    80002862:	f84a                	sd	s2,48(sp)
    80002864:	f44e                	sd	s3,40(sp)
    80002866:	f052                	sd	s4,32(sp)
    80002868:	ec56                	sd	s5,24(sp)
    8000286a:	e85a                	sd	s6,16(sp)
    8000286c:	e45e                	sd	s7,8(sp)
    8000286e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002870:	00006517          	auipc	a0,0x6
    80002874:	87850513          	addi	a0,a0,-1928 # 800080e8 <digits+0xa8>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	d12080e7          	jalr	-750(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002880:	00010497          	auipc	s1,0x10
    80002884:	c4048493          	addi	s1,s1,-960 # 800124c0 <proc+0x158>
    80002888:	00016917          	auipc	s2,0x16
    8000288c:	c3890913          	addi	s2,s2,-968 # 800184c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002890:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002892:	00006997          	auipc	s3,0x6
    80002896:	a4e98993          	addi	s3,s3,-1458 # 800082e0 <digits+0x2a0>
    printf("%d %s %s", p->pid, state, p->name);
    8000289a:	00006a97          	auipc	s5,0x6
    8000289e:	a4ea8a93          	addi	s5,s5,-1458 # 800082e8 <digits+0x2a8>
    printf("\n");
    800028a2:	00006a17          	auipc	s4,0x6
    800028a6:	846a0a13          	addi	s4,s4,-1978 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028aa:	00006b97          	auipc	s7,0x6
    800028ae:	a76b8b93          	addi	s7,s7,-1418 # 80008320 <states.0>
    800028b2:	a00d                	j	800028d4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b4:	ee06a583          	lw	a1,-288(a3)
    800028b8:	8556                	mv	a0,s5
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	cd0080e7          	jalr	-816(ra) # 8000058a <printf>
    printf("\n");
    800028c2:	8552                	mv	a0,s4
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cc6080e7          	jalr	-826(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028cc:	18048493          	addi	s1,s1,384
    800028d0:	03248263          	beq	s1,s2,800028f4 <procdump+0x9a>
    if (p->state == UNUSED)
    800028d4:	86a6                	mv	a3,s1
    800028d6:	ec04a783          	lw	a5,-320(s1)
    800028da:	dbed                	beqz	a5,800028cc <procdump+0x72>
      state = "???";
    800028dc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028de:	fcfb6be3          	bltu	s6,a5,800028b4 <procdump+0x5a>
    800028e2:	02079713          	slli	a4,a5,0x20
    800028e6:	01d75793          	srli	a5,a4,0x1d
    800028ea:	97de                	add	a5,a5,s7
    800028ec:	6390                	ld	a2,0(a5)
    800028ee:	f279                	bnez	a2,800028b4 <procdump+0x5a>
      state = "???";
    800028f0:	864e                	mv	a2,s3
    800028f2:	b7c9                	j	800028b4 <procdump+0x5a>
  }
}
    800028f4:	60a6                	ld	ra,72(sp)
    800028f6:	6406                	ld	s0,64(sp)
    800028f8:	74e2                	ld	s1,56(sp)
    800028fa:	7942                	ld	s2,48(sp)
    800028fc:	79a2                	ld	s3,40(sp)
    800028fe:	7a02                	ld	s4,32(sp)
    80002900:	6ae2                	ld	s5,24(sp)
    80002902:	6b42                	ld	s6,16(sp)
    80002904:	6ba2                	ld	s7,8(sp)
    80002906:	6161                	addi	sp,sp,80
    80002908:	8082                	ret

000000008000290a <swtch>:
    8000290a:	00153023          	sd	ra,0(a0)
    8000290e:	00253423          	sd	sp,8(a0)
    80002912:	e900                	sd	s0,16(a0)
    80002914:	ed04                	sd	s1,24(a0)
    80002916:	03253023          	sd	s2,32(a0)
    8000291a:	03353423          	sd	s3,40(a0)
    8000291e:	03453823          	sd	s4,48(a0)
    80002922:	03553c23          	sd	s5,56(a0)
    80002926:	05653023          	sd	s6,64(a0)
    8000292a:	05753423          	sd	s7,72(a0)
    8000292e:	05853823          	sd	s8,80(a0)
    80002932:	05953c23          	sd	s9,88(a0)
    80002936:	07a53023          	sd	s10,96(a0)
    8000293a:	07b53423          	sd	s11,104(a0)
    8000293e:	0005b083          	ld	ra,0(a1)
    80002942:	0085b103          	ld	sp,8(a1)
    80002946:	6980                	ld	s0,16(a1)
    80002948:	6d84                	ld	s1,24(a1)
    8000294a:	0205b903          	ld	s2,32(a1)
    8000294e:	0285b983          	ld	s3,40(a1)
    80002952:	0305ba03          	ld	s4,48(a1)
    80002956:	0385ba83          	ld	s5,56(a1)
    8000295a:	0405bb03          	ld	s6,64(a1)
    8000295e:	0485bb83          	ld	s7,72(a1)
    80002962:	0505bc03          	ld	s8,80(a1)
    80002966:	0585bc83          	ld	s9,88(a1)
    8000296a:	0605bd03          	ld	s10,96(a1)
    8000296e:	0685bd83          	ld	s11,104(a1)
    80002972:	8082                	ret

0000000080002974 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002974:	1141                	addi	sp,sp,-16
    80002976:	e406                	sd	ra,8(sp)
    80002978:	e022                	sd	s0,0(sp)
    8000297a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000297c:	00006597          	auipc	a1,0x6
    80002980:	9cc58593          	addi	a1,a1,-1588 # 80008348 <states.0+0x28>
    80002984:	00016517          	auipc	a0,0x16
    80002988:	9e450513          	addi	a0,a0,-1564 # 80018368 <tickslock>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	1e0080e7          	jalr	480(ra) # 80000b6c <initlock>
}
    80002994:	60a2                	ld	ra,8(sp)
    80002996:	6402                	ld	s0,0(sp)
    80002998:	0141                	addi	sp,sp,16
    8000299a:	8082                	ret

000000008000299c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000299c:	1141                	addi	sp,sp,-16
    8000299e:	e422                	sd	s0,8(sp)
    800029a0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a2:	00003797          	auipc	a5,0x3
    800029a6:	4de78793          	addi	a5,a5,1246 # 80005e80 <kernelvec>
    800029aa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029ae:	6422                	ld	s0,8(sp)
    800029b0:	0141                	addi	sp,sp,16
    800029b2:	8082                	ret

00000000800029b4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b4:	1141                	addi	sp,sp,-16
    800029b6:	e406                	sd	ra,8(sp)
    800029b8:	e022                	sd	s0,0(sp)
    800029ba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	17a080e7          	jalr	378(ra) # 80001b36 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029c8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ca:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ce:	00004617          	auipc	a2,0x4
    800029d2:	63260613          	addi	a2,a2,1586 # 80007000 <_trampoline>
    800029d6:	00004697          	auipc	a3,0x4
    800029da:	62a68693          	addi	a3,a3,1578 # 80007000 <_trampoline>
    800029de:	8e91                	sub	a3,a3,a2
    800029e0:	040007b7          	lui	a5,0x4000
    800029e4:	17fd                	addi	a5,a5,-1
    800029e6:	07b2                	slli	a5,a5,0xc
    800029e8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ea:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f0:	180026f3          	csrr	a3,satp
    800029f4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029f6:	6d38                	ld	a4,88(a0)
    800029f8:	6134                	ld	a3,64(a0)
    800029fa:	6585                	lui	a1,0x1
    800029fc:	96ae                	add	a3,a3,a1
    800029fe:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a00:	6d38                	ld	a4,88(a0)
    80002a02:	00000697          	auipc	a3,0x0
    80002a06:	13868693          	addi	a3,a3,312 # 80002b3a <usertrap>
    80002a0a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a0c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a0e:	8692                	mv	a3,tp
    80002a10:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a12:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a16:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a1a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a22:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a24:	6f18                	ld	a4,24(a4)
    80002a26:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a2a:	692c                	ld	a1,80(a0)
    80002a2c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a2e:	00004717          	auipc	a4,0x4
    80002a32:	66270713          	addi	a4,a4,1634 # 80007090 <userret>
    80002a36:	8f11                	sub	a4,a4,a2
    80002a38:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a3a:	577d                	li	a4,-1
    80002a3c:	177e                	slli	a4,a4,0x3f
    80002a3e:	8dd9                	or	a1,a1,a4
    80002a40:	02000537          	lui	a0,0x2000
    80002a44:	157d                	addi	a0,a0,-1
    80002a46:	0536                	slli	a0,a0,0xd
    80002a48:	9782                	jalr	a5
}
    80002a4a:	60a2                	ld	ra,8(sp)
    80002a4c:	6402                	ld	s0,0(sp)
    80002a4e:	0141                	addi	sp,sp,16
    80002a50:	8082                	ret

0000000080002a52 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a5c:	00016497          	auipc	s1,0x16
    80002a60:	90c48493          	addi	s1,s1,-1780 # 80018368 <tickslock>
    80002a64:	8526                	mv	a0,s1
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	196080e7          	jalr	406(ra) # 80000bfc <acquire>
  ticks++;
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	5b250513          	addi	a0,a0,1458 # 80009020 <ticks>
    80002a76:	411c                	lw	a5,0(a0)
    80002a78:	2785                	addiw	a5,a5,1
    80002a7a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	c10080e7          	jalr	-1008(ra) # 8000268c <wakeup>
  release(&tickslock);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	22a080e7          	jalr	554(ra) # 80000cb0 <release>
}
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	64a2                	ld	s1,8(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret

0000000080002a98 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a98:	1101                	addi	sp,sp,-32
    80002a9a:	ec06                	sd	ra,24(sp)
    80002a9c:	e822                	sd	s0,16(sp)
    80002a9e:	e426                	sd	s1,8(sp)
    80002aa0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aa6:	00074d63          	bltz	a4,80002ac0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aaa:	57fd                	li	a5,-1
    80002aac:	17fe                	slli	a5,a5,0x3f
    80002aae:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ab0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ab2:	06f70363          	beq	a4,a5,80002b18 <devintr+0x80>
  }
}
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	64a2                	ld	s1,8(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret
     (scause & 0xff) == 9){
    80002ac0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ac4:	46a5                	li	a3,9
    80002ac6:	fed792e3          	bne	a5,a3,80002aaa <devintr+0x12>
    int irq = plic_claim();
    80002aca:	00003097          	auipc	ra,0x3
    80002ace:	4be080e7          	jalr	1214(ra) # 80005f88 <plic_claim>
    80002ad2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad4:	47a9                	li	a5,10
    80002ad6:	02f50763          	beq	a0,a5,80002b04 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ada:	4785                	li	a5,1
    80002adc:	02f50963          	beq	a0,a5,80002b0e <devintr+0x76>
    return 1;
    80002ae0:	4505                	li	a0,1
    } else if(irq){
    80002ae2:	d8f1                	beqz	s1,80002ab6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae4:	85a6                	mv	a1,s1
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	86a50513          	addi	a0,a0,-1942 # 80008350 <states.0+0x30>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a9c080e7          	jalr	-1380(ra) # 8000058a <printf>
      plic_complete(irq);
    80002af6:	8526                	mv	a0,s1
    80002af8:	00003097          	auipc	ra,0x3
    80002afc:	4b4080e7          	jalr	1204(ra) # 80005fac <plic_complete>
    return 1;
    80002b00:	4505                	li	a0,1
    80002b02:	bf55                	j	80002ab6 <devintr+0x1e>
      uartintr();
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	ebc080e7          	jalr	-324(ra) # 800009c0 <uartintr>
    80002b0c:	b7ed                	j	80002af6 <devintr+0x5e>
      virtio_disk_intr();
    80002b0e:	00004097          	auipc	ra,0x4
    80002b12:	918080e7          	jalr	-1768(ra) # 80006426 <virtio_disk_intr>
    80002b16:	b7c5                	j	80002af6 <devintr+0x5e>
    if(cpuid() == 0){
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	ff2080e7          	jalr	-14(ra) # 80001b0a <cpuid>
    80002b20:	c901                	beqz	a0,80002b30 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b22:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b28:	14479073          	csrw	sip,a5
    return 2;
    80002b2c:	4509                	li	a0,2
    80002b2e:	b761                	j	80002ab6 <devintr+0x1e>
      clockintr();
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	f22080e7          	jalr	-222(ra) # 80002a52 <clockintr>
    80002b38:	b7ed                	j	80002b22 <devintr+0x8a>

0000000080002b3a <usertrap>:
{
    80002b3a:	1101                	addi	sp,sp,-32
    80002b3c:	ec06                	sd	ra,24(sp)
    80002b3e:	e822                	sd	s0,16(sp)
    80002b40:	e426                	sd	s1,8(sp)
    80002b42:	e04a                	sd	s2,0(sp)
    80002b44:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b46:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b4a:	1007f793          	andi	a5,a5,256
    80002b4e:	e3ad                	bnez	a5,80002bb0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b50:	00003797          	auipc	a5,0x3
    80002b54:	33078793          	addi	a5,a5,816 # 80005e80 <kernelvec>
    80002b58:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	fda080e7          	jalr	-38(ra) # 80001b36 <myproc>
    80002b64:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b66:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b68:	14102773          	csrr	a4,sepc
    80002b6c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b72:	47a1                	li	a5,8
    80002b74:	04f71c63          	bne	a4,a5,80002bcc <usertrap+0x92>
    if(p->killed)
    80002b78:	591c                	lw	a5,48(a0)
    80002b7a:	e3b9                	bnez	a5,80002bc0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b7c:	6cb8                	ld	a4,88(s1)
    80002b7e:	6f1c                	ld	a5,24(a4)
    80002b80:	0791                	addi	a5,a5,4
    80002b82:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b88:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	2f8080e7          	jalr	760(ra) # 80002e88 <syscall>
  if(p->killed)
    80002b98:	589c                	lw	a5,48(s1)
    80002b9a:	ebc1                	bnez	a5,80002c2a <usertrap+0xf0>
  usertrapret();
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	e18080e7          	jalr	-488(ra) # 800029b4 <usertrapret>
}
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6902                	ld	s2,0(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret
    panic("usertrap: not from user mode");
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	7c050513          	addi	a0,a0,1984 # 80008370 <states.0+0x50>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	988080e7          	jalr	-1656(ra) # 80000540 <panic>
      exit(-1);
    80002bc0:	557d                	li	a0,-1
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	788080e7          	jalr	1928(ra) # 8000234a <exit>
    80002bca:	bf4d                	j	80002b7c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	ecc080e7          	jalr	-308(ra) # 80002a98 <devintr>
    80002bd4:	892a                	mv	s2,a0
    80002bd6:	c501                	beqz	a0,80002bde <usertrap+0xa4>
  if(p->killed)
    80002bd8:	589c                	lw	a5,48(s1)
    80002bda:	c3a1                	beqz	a5,80002c1a <usertrap+0xe0>
    80002bdc:	a815                	j	80002c10 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bde:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002be2:	5c90                	lw	a2,56(s1)
    80002be4:	00005517          	auipc	a0,0x5
    80002be8:	7ac50513          	addi	a0,a0,1964 # 80008390 <states.0+0x70>
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	99e080e7          	jalr	-1634(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	7c450513          	addi	a0,a0,1988 # 800083c0 <states.0+0xa0>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	986080e7          	jalr	-1658(ra) # 8000058a <printf>
    p->killed = 1;
    80002c0c:	4785                	li	a5,1
    80002c0e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c10:	557d                	li	a0,-1
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	738080e7          	jalr	1848(ra) # 8000234a <exit>
  if(which_dev == 2)
    80002c1a:	4789                	li	a5,2
    80002c1c:	f8f910e3          	bne	s2,a5,80002b9c <usertrap+0x62>
    yield();
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	846080e7          	jalr	-1978(ra) # 80002466 <yield>
    80002c28:	bf95                	j	80002b9c <usertrap+0x62>
  int which_dev = 0;
    80002c2a:	4901                	li	s2,0
    80002c2c:	b7d5                	j	80002c10 <usertrap+0xd6>

0000000080002c2e <kerneltrap>:
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	e84a                	sd	s2,16(sp)
    80002c38:	e44e                	sd	s3,8(sp)
    80002c3a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c40:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c44:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c48:	1004f793          	andi	a5,s1,256
    80002c4c:	cb85                	beqz	a5,80002c7c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c52:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c54:	ef85                	bnez	a5,80002c8c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	e42080e7          	jalr	-446(ra) # 80002a98 <devintr>
    80002c5e:	cd1d                	beqz	a0,80002c9c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c60:	4789                	li	a5,2
    80002c62:	08f50663          	beq	a0,a5,80002cee <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c66:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6a:	10049073          	csrw	sstatus,s1
}
    80002c6e:	70a2                	ld	ra,40(sp)
    80002c70:	7402                	ld	s0,32(sp)
    80002c72:	64e2                	ld	s1,24(sp)
    80002c74:	6942                	ld	s2,16(sp)
    80002c76:	69a2                	ld	s3,8(sp)
    80002c78:	6145                	addi	sp,sp,48
    80002c7a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	76450513          	addi	a0,a0,1892 # 800083e0 <states.0+0xc0>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	8bc080e7          	jalr	-1860(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	77c50513          	addi	a0,a0,1916 # 80008408 <states.0+0xe8>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c9c:	00006597          	auipc	a1,0x6
    80002ca0:	3845a583          	lw	a1,900(a1) # 80009020 <ticks>
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	7dc50513          	addi	a0,a0,2012 # 80008480 <states.0+0x160>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8de080e7          	jalr	-1826(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002cb4:	85ce                	mv	a1,s3
    80002cb6:	00005517          	auipc	a0,0x5
    80002cba:	77250513          	addi	a0,a0,1906 # 80008428 <states.0+0x108>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	8cc080e7          	jalr	-1844(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	76a50513          	addi	a0,a0,1898 # 80008438 <states.0+0x118>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	8b4080e7          	jalr	-1868(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	77250513          	addi	a0,a0,1906 # 80008450 <states.0+0x130>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	85a080e7          	jalr	-1958(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	e48080e7          	jalr	-440(ra) # 80001b36 <myproc>
    80002cf6:	d925                	beqz	a0,80002c66 <kerneltrap+0x38>
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	e3e080e7          	jalr	-450(ra) # 80001b36 <myproc>
    80002d00:	4d18                	lw	a4,24(a0)
    80002d02:	478d                	li	a5,3
    80002d04:	f6f711e3          	bne	a4,a5,80002c66 <kerneltrap+0x38>
    yield();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	75e080e7          	jalr	1886(ra) # 80002466 <yield>
    80002d10:	bf99                	j	80002c66 <kerneltrap+0x38>

0000000080002d12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
    80002d1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	e18080e7          	jalr	-488(ra) # 80001b36 <myproc>
  switch (n)
    80002d26:	4795                	li	a5,5
    80002d28:	0497e163          	bltu	a5,s1,80002d6a <argraw+0x58>
    80002d2c:	048a                	slli	s1,s1,0x2
    80002d2e:	00005717          	auipc	a4,0x5
    80002d32:	75a70713          	addi	a4,a4,1882 # 80008488 <states.0+0x168>
    80002d36:	94ba                	add	s1,s1,a4
    80002d38:	409c                	lw	a5,0(s1)
    80002d3a:	97ba                	add	a5,a5,a4
    80002d3c:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d3e:	6d3c                	ld	a5,88(a0)
    80002d40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d42:	60e2                	ld	ra,24(sp)
    80002d44:	6442                	ld	s0,16(sp)
    80002d46:	64a2                	ld	s1,8(sp)
    80002d48:	6105                	addi	sp,sp,32
    80002d4a:	8082                	ret
    return p->trapframe->a1;
    80002d4c:	6d3c                	ld	a5,88(a0)
    80002d4e:	7fa8                	ld	a0,120(a5)
    80002d50:	bfcd                	j	80002d42 <argraw+0x30>
    return p->trapframe->a2;
    80002d52:	6d3c                	ld	a5,88(a0)
    80002d54:	63c8                	ld	a0,128(a5)
    80002d56:	b7f5                	j	80002d42 <argraw+0x30>
    return p->trapframe->a3;
    80002d58:	6d3c                	ld	a5,88(a0)
    80002d5a:	67c8                	ld	a0,136(a5)
    80002d5c:	b7dd                	j	80002d42 <argraw+0x30>
    return p->trapframe->a4;
    80002d5e:	6d3c                	ld	a5,88(a0)
    80002d60:	6bc8                	ld	a0,144(a5)
    80002d62:	b7c5                	j	80002d42 <argraw+0x30>
    return p->trapframe->a5;
    80002d64:	6d3c                	ld	a5,88(a0)
    80002d66:	6fc8                	ld	a0,152(a5)
    80002d68:	bfe9                	j	80002d42 <argraw+0x30>
  panic("argraw");
    80002d6a:	00005517          	auipc	a0,0x5
    80002d6e:	6f650513          	addi	a0,a0,1782 # 80008460 <states.0+0x140>
    80002d72:	ffffd097          	auipc	ra,0xffffd
    80002d76:	7ce080e7          	jalr	1998(ra) # 80000540 <panic>

0000000080002d7a <fetchaddr>:
{
    80002d7a:	1101                	addi	sp,sp,-32
    80002d7c:	ec06                	sd	ra,24(sp)
    80002d7e:	e822                	sd	s0,16(sp)
    80002d80:	e426                	sd	s1,8(sp)
    80002d82:	e04a                	sd	s2,0(sp)
    80002d84:	1000                	addi	s0,sp,32
    80002d86:	84aa                	mv	s1,a0
    80002d88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	dac080e7          	jalr	-596(ra) # 80001b36 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d92:	653c                	ld	a5,72(a0)
    80002d94:	02f4f863          	bgeu	s1,a5,80002dc4 <fetchaddr+0x4a>
    80002d98:	00848713          	addi	a4,s1,8
    80002d9c:	02e7e663          	bltu	a5,a4,80002dc8 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002da0:	46a1                	li	a3,8
    80002da2:	8626                	mv	a2,s1
    80002da4:	85ca                	mv	a1,s2
    80002da6:	6928                	ld	a0,80(a0)
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	98e080e7          	jalr	-1650(ra) # 80001736 <copyin>
    80002db0:	00a03533          	snez	a0,a0
    80002db4:	40a00533          	neg	a0,a0
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret
    return -1;
    80002dc4:	557d                	li	a0,-1
    80002dc6:	bfcd                	j	80002db8 <fetchaddr+0x3e>
    80002dc8:	557d                	li	a0,-1
    80002dca:	b7fd                	j	80002db8 <fetchaddr+0x3e>

0000000080002dcc <fetchstr>:
{
    80002dcc:	7179                	addi	sp,sp,-48
    80002dce:	f406                	sd	ra,40(sp)
    80002dd0:	f022                	sd	s0,32(sp)
    80002dd2:	ec26                	sd	s1,24(sp)
    80002dd4:	e84a                	sd	s2,16(sp)
    80002dd6:	e44e                	sd	s3,8(sp)
    80002dd8:	1800                	addi	s0,sp,48
    80002dda:	892a                	mv	s2,a0
    80002ddc:	84ae                	mv	s1,a1
    80002dde:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	d56080e7          	jalr	-682(ra) # 80001b36 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002de8:	86ce                	mv	a3,s3
    80002dea:	864a                	mv	a2,s2
    80002dec:	85a6                	mv	a1,s1
    80002dee:	6928                	ld	a0,80(a0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	9d4080e7          	jalr	-1580(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002df8:	00054763          	bltz	a0,80002e06 <fetchstr+0x3a>
  return strlen(buf);
    80002dfc:	8526                	mv	a0,s1
    80002dfe:	ffffe097          	auipc	ra,0xffffe
    80002e02:	07e080e7          	jalr	126(ra) # 80000e7c <strlen>
}
    80002e06:	70a2                	ld	ra,40(sp)
    80002e08:	7402                	ld	s0,32(sp)
    80002e0a:	64e2                	ld	s1,24(sp)
    80002e0c:	6942                	ld	s2,16(sp)
    80002e0e:	69a2                	ld	s3,8(sp)
    80002e10:	6145                	addi	sp,sp,48
    80002e12:	8082                	ret

0000000080002e14 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	e426                	sd	s1,8(sp)
    80002e1c:	1000                	addi	s0,sp,32
    80002e1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	ef2080e7          	jalr	-270(ra) # 80002d12 <argraw>
    80002e28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e2a:	4501                	li	a0,0
    80002e2c:	60e2                	ld	ra,24(sp)
    80002e2e:	6442                	ld	s0,16(sp)
    80002e30:	64a2                	ld	s1,8(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e36:	1101                	addi	sp,sp,-32
    80002e38:	ec06                	sd	ra,24(sp)
    80002e3a:	e822                	sd	s0,16(sp)
    80002e3c:	e426                	sd	s1,8(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	ed0080e7          	jalr	-304(ra) # 80002d12 <argraw>
    80002e4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e4c:	4501                	li	a0,0
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	64a2                	ld	s1,8(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	e04a                	sd	s2,0(sp)
    80002e62:	1000                	addi	s0,sp,32
    80002e64:	84ae                	mv	s1,a1
    80002e66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	eaa080e7          	jalr	-342(ra) # 80002d12 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e70:	864a                	mv	a2,s2
    80002e72:	85a6                	mv	a1,s1
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	f58080e7          	jalr	-168(ra) # 80002dcc <fetchstr>
}
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6902                	ld	s2,0(sp)
    80002e84:	6105                	addi	sp,sp,32
    80002e86:	8082                	ret

0000000080002e88 <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e88:	1101                	addi	sp,sp,-32
    80002e8a:	ec06                	sd	ra,24(sp)
    80002e8c:	e822                	sd	s0,16(sp)
    80002e8e:	e426                	sd	s1,8(sp)
    80002e90:	e04a                	sd	s2,0(sp)
    80002e92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	ca2080e7          	jalr	-862(ra) # 80001b36 <myproc>
    80002e9c:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked, 
  // move to Q2 process
  p->change = 3;
    80002e9e:	478d                	li	a5,3
    80002ea0:	16f52423          	sw	a5,360(a0)

  num = p->trapframe->a7;
    80002ea4:	05853903          	ld	s2,88(a0)
    80002ea8:	0a893783          	ld	a5,168(s2)
    80002eac:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002eb0:	37fd                	addiw	a5,a5,-1
    80002eb2:	4751                	li	a4,20
    80002eb4:	00f76f63          	bltu	a4,a5,80002ed2 <syscall+0x4a>
    80002eb8:	00369713          	slli	a4,a3,0x3
    80002ebc:	00005797          	auipc	a5,0x5
    80002ec0:	5e478793          	addi	a5,a5,1508 # 800084a0 <syscalls>
    80002ec4:	97ba                	add	a5,a5,a4
    80002ec6:	639c                	ld	a5,0(a5)
    80002ec8:	c789                	beqz	a5,80002ed2 <syscall+0x4a>
  {
    p->trapframe->a0 = syscalls[num]();
    80002eca:	9782                	jalr	a5
    80002ecc:	06a93823          	sd	a0,112(s2)
    80002ed0:	a839                	j	80002eee <syscall+0x66>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002ed2:	15848613          	addi	a2,s1,344
    80002ed6:	5c8c                	lw	a1,56(s1)
    80002ed8:	00005517          	auipc	a0,0x5
    80002edc:	59050513          	addi	a0,a0,1424 # 80008468 <states.0+0x148>
    80002ee0:	ffffd097          	auipc	ra,0xffffd
    80002ee4:	6aa080e7          	jalr	1706(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee8:	6cbc                	ld	a5,88(s1)
    80002eea:	577d                	li	a4,-1
    80002eec:	fbb8                	sd	a4,112(a5)
  }
}
    80002eee:	60e2                	ld	ra,24(sp)
    80002ef0:	6442                	ld	s0,16(sp)
    80002ef2:	64a2                	ld	s1,8(sp)
    80002ef4:	6902                	ld	s2,0(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f02:	fec40593          	addi	a1,s0,-20
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	f0c080e7          	jalr	-244(ra) # 80002e14 <argint>
    return -1;
    80002f10:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f12:	00054963          	bltz	a0,80002f24 <sys_exit+0x2a>
  exit(n);
    80002f16:	fec42503          	lw	a0,-20(s0)
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	430080e7          	jalr	1072(ra) # 8000234a <exit>
  return 0;  // not reached
    80002f22:	4781                	li	a5,0
}
    80002f24:	853e                	mv	a0,a5
    80002f26:	60e2                	ld	ra,24(sp)
    80002f28:	6442                	ld	s0,16(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f2e:	1141                	addi	sp,sp,-16
    80002f30:	e406                	sd	ra,8(sp)
    80002f32:	e022                	sd	s0,0(sp)
    80002f34:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	c00080e7          	jalr	-1024(ra) # 80001b36 <myproc>
}
    80002f3e:	5d08                	lw	a0,56(a0)
    80002f40:	60a2                	ld	ra,8(sp)
    80002f42:	6402                	ld	s0,0(sp)
    80002f44:	0141                	addi	sp,sp,16
    80002f46:	8082                	ret

0000000080002f48 <sys_fork>:

uint64
sys_fork(void)
{
    80002f48:	1141                	addi	sp,sp,-16
    80002f4a:	e406                	sd	ra,8(sp)
    80002f4c:	e022                	sd	s0,0(sp)
    80002f4e:	0800                	addi	s0,sp,16
  return fork();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	00e080e7          	jalr	14(ra) # 80001f5e <fork>
}
    80002f58:	60a2                	ld	ra,8(sp)
    80002f5a:	6402                	ld	s0,0(sp)
    80002f5c:	0141                	addi	sp,sp,16
    80002f5e:	8082                	ret

0000000080002f60 <sys_wait>:

uint64
sys_wait(void)
{
    80002f60:	1101                	addi	sp,sp,-32
    80002f62:	ec06                	sd	ra,24(sp)
    80002f64:	e822                	sd	s0,16(sp)
    80002f66:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f68:	fe840593          	addi	a1,s0,-24
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	ec8080e7          	jalr	-312(ra) # 80002e36 <argaddr>
    80002f76:	87aa                	mv	a5,a0
    return -1;
    80002f78:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f7a:	0007c863          	bltz	a5,80002f8a <sys_wait+0x2a>
  return wait(p);
    80002f7e:	fe843503          	ld	a0,-24(s0)
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	5ee080e7          	jalr	1518(ra) # 80002570 <wait>
}
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	6105                	addi	sp,sp,32
    80002f90:	8082                	ret

0000000080002f92 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f9c:	fdc40593          	addi	a1,s0,-36
    80002fa0:	4501                	li	a0,0
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	e72080e7          	jalr	-398(ra) # 80002e14 <argint>
    return -1;
    80002faa:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fac:	00054f63          	bltz	a0,80002fca <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	b86080e7          	jalr	-1146(ra) # 80001b36 <myproc>
    80002fb8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fba:	fdc42503          	lw	a0,-36(s0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	f2c080e7          	jalr	-212(ra) # 80001eea <growproc>
    80002fc6:	00054863          	bltz	a0,80002fd6 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fca:	8526                	mv	a0,s1
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret
    return -1;
    80002fd6:	54fd                	li	s1,-1
    80002fd8:	bfcd                	j	80002fca <sys_sbrk+0x38>

0000000080002fda <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fda:	7139                	addi	sp,sp,-64
    80002fdc:	fc06                	sd	ra,56(sp)
    80002fde:	f822                	sd	s0,48(sp)
    80002fe0:	f426                	sd	s1,40(sp)
    80002fe2:	f04a                	sd	s2,32(sp)
    80002fe4:	ec4e                	sd	s3,24(sp)
    80002fe6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe8:	fcc40593          	addi	a1,s0,-52
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	e26080e7          	jalr	-474(ra) # 80002e14 <argint>
    return -1;
    80002ff6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff8:	06054563          	bltz	a0,80003062 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ffc:	00015517          	auipc	a0,0x15
    80003000:	36c50513          	addi	a0,a0,876 # 80018368 <tickslock>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	bf8080e7          	jalr	-1032(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    8000300c:	00006917          	auipc	s2,0x6
    80003010:	01492903          	lw	s2,20(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003014:	fcc42783          	lw	a5,-52(s0)
    80003018:	cf85                	beqz	a5,80003050 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000301a:	00015997          	auipc	s3,0x15
    8000301e:	34e98993          	addi	s3,s3,846 # 80018368 <tickslock>
    80003022:	00006497          	auipc	s1,0x6
    80003026:	ffe48493          	addi	s1,s1,-2 # 80009020 <ticks>
    if(myproc()->killed){
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	b0c080e7          	jalr	-1268(ra) # 80001b36 <myproc>
    80003032:	591c                	lw	a5,48(a0)
    80003034:	ef9d                	bnez	a5,80003072 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003036:	85ce                	mv	a1,s3
    80003038:	8526                	mv	a0,s1
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	494080e7          	jalr	1172(ra) # 800024ce <sleep>
  while(ticks - ticks0 < n){
    80003042:	409c                	lw	a5,0(s1)
    80003044:	412787bb          	subw	a5,a5,s2
    80003048:	fcc42703          	lw	a4,-52(s0)
    8000304c:	fce7efe3          	bltu	a5,a4,8000302a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003050:	00015517          	auipc	a0,0x15
    80003054:	31850513          	addi	a0,a0,792 # 80018368 <tickslock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c58080e7          	jalr	-936(ra) # 80000cb0 <release>
  return 0;
    80003060:	4781                	li	a5,0
}
    80003062:	853e                	mv	a0,a5
    80003064:	70e2                	ld	ra,56(sp)
    80003066:	7442                	ld	s0,48(sp)
    80003068:	74a2                	ld	s1,40(sp)
    8000306a:	7902                	ld	s2,32(sp)
    8000306c:	69e2                	ld	s3,24(sp)
    8000306e:	6121                	addi	sp,sp,64
    80003070:	8082                	ret
      release(&tickslock);
    80003072:	00015517          	auipc	a0,0x15
    80003076:	2f650513          	addi	a0,a0,758 # 80018368 <tickslock>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	c36080e7          	jalr	-970(ra) # 80000cb0 <release>
      return -1;
    80003082:	57fd                	li	a5,-1
    80003084:	bff9                	j	80003062 <sys_sleep+0x88>

0000000080003086 <sys_kill>:

uint64
sys_kill(void)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000308e:	fec40593          	addi	a1,s0,-20
    80003092:	4501                	li	a0,0
    80003094:	00000097          	auipc	ra,0x0
    80003098:	d80080e7          	jalr	-640(ra) # 80002e14 <argint>
    8000309c:	87aa                	mv	a5,a0
    return -1;
    8000309e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030a0:	0007c863          	bltz	a5,800030b0 <sys_kill+0x2a>
  return kill(pid);
    800030a4:	fec42503          	lw	a0,-20(s0)
    800030a8:	fffff097          	auipc	ra,0xfffff
    800030ac:	678080e7          	jalr	1656(ra) # 80002720 <kill>
}
    800030b0:	60e2                	ld	ra,24(sp)
    800030b2:	6442                	ld	s0,16(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret

00000000800030b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b8:	1101                	addi	sp,sp,-32
    800030ba:	ec06                	sd	ra,24(sp)
    800030bc:	e822                	sd	s0,16(sp)
    800030be:	e426                	sd	s1,8(sp)
    800030c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030c2:	00015517          	auipc	a0,0x15
    800030c6:	2a650513          	addi	a0,a0,678 # 80018368 <tickslock>
    800030ca:	ffffe097          	auipc	ra,0xffffe
    800030ce:	b32080e7          	jalr	-1230(ra) # 80000bfc <acquire>
  xticks = ticks;
    800030d2:	00006497          	auipc	s1,0x6
    800030d6:	f4e4a483          	lw	s1,-178(s1) # 80009020 <ticks>
  release(&tickslock);
    800030da:	00015517          	auipc	a0,0x15
    800030de:	28e50513          	addi	a0,a0,654 # 80018368 <tickslock>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	bce080e7          	jalr	-1074(ra) # 80000cb0 <release>
  return xticks;
}
    800030ea:	02049513          	slli	a0,s1,0x20
    800030ee:	9101                	srli	a0,a0,0x20
    800030f0:	60e2                	ld	ra,24(sp)
    800030f2:	6442                	ld	s0,16(sp)
    800030f4:	64a2                	ld	s1,8(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret

00000000800030fa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030fa:	7179                	addi	sp,sp,-48
    800030fc:	f406                	sd	ra,40(sp)
    800030fe:	f022                	sd	s0,32(sp)
    80003100:	ec26                	sd	s1,24(sp)
    80003102:	e84a                	sd	s2,16(sp)
    80003104:	e44e                	sd	s3,8(sp)
    80003106:	e052                	sd	s4,0(sp)
    80003108:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000310a:	00005597          	auipc	a1,0x5
    8000310e:	44658593          	addi	a1,a1,1094 # 80008550 <syscalls+0xb0>
    80003112:	00015517          	auipc	a0,0x15
    80003116:	26e50513          	addi	a0,a0,622 # 80018380 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	a52080e7          	jalr	-1454(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003122:	0001d797          	auipc	a5,0x1d
    80003126:	25e78793          	addi	a5,a5,606 # 80020380 <bcache+0x8000>
    8000312a:	0001d717          	auipc	a4,0x1d
    8000312e:	4be70713          	addi	a4,a4,1214 # 800205e8 <bcache+0x8268>
    80003132:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003136:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000313a:	00015497          	auipc	s1,0x15
    8000313e:	25e48493          	addi	s1,s1,606 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    80003142:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003144:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003146:	00005a17          	auipc	s4,0x5
    8000314a:	412a0a13          	addi	s4,s4,1042 # 80008558 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000314e:	2b893783          	ld	a5,696(s2)
    80003152:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003154:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003158:	85d2                	mv	a1,s4
    8000315a:	01048513          	addi	a0,s1,16
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	4b2080e7          	jalr	1202(ra) # 80004610 <initsleeplock>
    bcache.head.next->prev = b;
    80003166:	2b893783          	ld	a5,696(s2)
    8000316a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000316c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003170:	45848493          	addi	s1,s1,1112
    80003174:	fd349de3          	bne	s1,s3,8000314e <binit+0x54>
  }
}
    80003178:	70a2                	ld	ra,40(sp)
    8000317a:	7402                	ld	s0,32(sp)
    8000317c:	64e2                	ld	s1,24(sp)
    8000317e:	6942                	ld	s2,16(sp)
    80003180:	69a2                	ld	s3,8(sp)
    80003182:	6a02                	ld	s4,0(sp)
    80003184:	6145                	addi	sp,sp,48
    80003186:	8082                	ret

0000000080003188 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003188:	7179                	addi	sp,sp,-48
    8000318a:	f406                	sd	ra,40(sp)
    8000318c:	f022                	sd	s0,32(sp)
    8000318e:	ec26                	sd	s1,24(sp)
    80003190:	e84a                	sd	s2,16(sp)
    80003192:	e44e                	sd	s3,8(sp)
    80003194:	1800                	addi	s0,sp,48
    80003196:	892a                	mv	s2,a0
    80003198:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000319a:	00015517          	auipc	a0,0x15
    8000319e:	1e650513          	addi	a0,a0,486 # 80018380 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	a5a080e7          	jalr	-1446(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031aa:	0001d497          	auipc	s1,0x1d
    800031ae:	48e4b483          	ld	s1,1166(s1) # 80020638 <bcache+0x82b8>
    800031b2:	0001d797          	auipc	a5,0x1d
    800031b6:	43678793          	addi	a5,a5,1078 # 800205e8 <bcache+0x8268>
    800031ba:	02f48f63          	beq	s1,a5,800031f8 <bread+0x70>
    800031be:	873e                	mv	a4,a5
    800031c0:	a021                	j	800031c8 <bread+0x40>
    800031c2:	68a4                	ld	s1,80(s1)
    800031c4:	02e48a63          	beq	s1,a4,800031f8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031c8:	449c                	lw	a5,8(s1)
    800031ca:	ff279ce3          	bne	a5,s2,800031c2 <bread+0x3a>
    800031ce:	44dc                	lw	a5,12(s1)
    800031d0:	ff3799e3          	bne	a5,s3,800031c2 <bread+0x3a>
      b->refcnt++;
    800031d4:	40bc                	lw	a5,64(s1)
    800031d6:	2785                	addiw	a5,a5,1
    800031d8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031da:	00015517          	auipc	a0,0x15
    800031de:	1a650513          	addi	a0,a0,422 # 80018380 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	ace080e7          	jalr	-1330(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031ea:	01048513          	addi	a0,s1,16
    800031ee:	00001097          	auipc	ra,0x1
    800031f2:	45c080e7          	jalr	1116(ra) # 8000464a <acquiresleep>
      return b;
    800031f6:	a8b9                	j	80003254 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f8:	0001d497          	auipc	s1,0x1d
    800031fc:	4384b483          	ld	s1,1080(s1) # 80020630 <bcache+0x82b0>
    80003200:	0001d797          	auipc	a5,0x1d
    80003204:	3e878793          	addi	a5,a5,1000 # 800205e8 <bcache+0x8268>
    80003208:	00f48863          	beq	s1,a5,80003218 <bread+0x90>
    8000320c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000320e:	40bc                	lw	a5,64(s1)
    80003210:	cf81                	beqz	a5,80003228 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003212:	64a4                	ld	s1,72(s1)
    80003214:	fee49de3          	bne	s1,a4,8000320e <bread+0x86>
  panic("bget: no buffers");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	34850513          	addi	a0,a0,840 # 80008560 <syscalls+0xc0>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	320080e7          	jalr	800(ra) # 80000540 <panic>
      b->dev = dev;
    80003228:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000322c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003230:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003234:	4785                	li	a5,1
    80003236:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003238:	00015517          	auipc	a0,0x15
    8000323c:	14850513          	addi	a0,a0,328 # 80018380 <bcache>
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	a70080e7          	jalr	-1424(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003248:	01048513          	addi	a0,s1,16
    8000324c:	00001097          	auipc	ra,0x1
    80003250:	3fe080e7          	jalr	1022(ra) # 8000464a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003254:	409c                	lw	a5,0(s1)
    80003256:	cb89                	beqz	a5,80003268 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003258:	8526                	mv	a0,s1
    8000325a:	70a2                	ld	ra,40(sp)
    8000325c:	7402                	ld	s0,32(sp)
    8000325e:	64e2                	ld	s1,24(sp)
    80003260:	6942                	ld	s2,16(sp)
    80003262:	69a2                	ld	s3,8(sp)
    80003264:	6145                	addi	sp,sp,48
    80003266:	8082                	ret
    virtio_disk_rw(b, 0);
    80003268:	4581                	li	a1,0
    8000326a:	8526                	mv	a0,s1
    8000326c:	00003097          	auipc	ra,0x3
    80003270:	f30080e7          	jalr	-208(ra) # 8000619c <virtio_disk_rw>
    b->valid = 1;
    80003274:	4785                	li	a5,1
    80003276:	c09c                	sw	a5,0(s1)
  return b;
    80003278:	b7c5                	j	80003258 <bread+0xd0>

000000008000327a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	1000                	addi	s0,sp,32
    80003284:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003286:	0541                	addi	a0,a0,16
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	45c080e7          	jalr	1116(ra) # 800046e4 <holdingsleep>
    80003290:	cd01                	beqz	a0,800032a8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003292:	4585                	li	a1,1
    80003294:	8526                	mv	a0,s1
    80003296:	00003097          	auipc	ra,0x3
    8000329a:	f06080e7          	jalr	-250(ra) # 8000619c <virtio_disk_rw>
}
    8000329e:	60e2                	ld	ra,24(sp)
    800032a0:	6442                	ld	s0,16(sp)
    800032a2:	64a2                	ld	s1,8(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret
    panic("bwrite");
    800032a8:	00005517          	auipc	a0,0x5
    800032ac:	2d050513          	addi	a0,a0,720 # 80008578 <syscalls+0xd8>
    800032b0:	ffffd097          	auipc	ra,0xffffd
    800032b4:	290080e7          	jalr	656(ra) # 80000540 <panic>

00000000800032b8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	e04a                	sd	s2,0(sp)
    800032c2:	1000                	addi	s0,sp,32
    800032c4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c6:	01050913          	addi	s2,a0,16
    800032ca:	854a                	mv	a0,s2
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	418080e7          	jalr	1048(ra) # 800046e4 <holdingsleep>
    800032d4:	c92d                	beqz	a0,80003346 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00001097          	auipc	ra,0x1
    800032dc:	3c8080e7          	jalr	968(ra) # 800046a0 <releasesleep>

  acquire(&bcache.lock);
    800032e0:	00015517          	auipc	a0,0x15
    800032e4:	0a050513          	addi	a0,a0,160 # 80018380 <bcache>
    800032e8:	ffffe097          	auipc	ra,0xffffe
    800032ec:	914080e7          	jalr	-1772(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032f0:	40bc                	lw	a5,64(s1)
    800032f2:	37fd                	addiw	a5,a5,-1
    800032f4:	0007871b          	sext.w	a4,a5
    800032f8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032fa:	eb05                	bnez	a4,8000332a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032fc:	68bc                	ld	a5,80(s1)
    800032fe:	64b8                	ld	a4,72(s1)
    80003300:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003302:	64bc                	ld	a5,72(s1)
    80003304:	68b8                	ld	a4,80(s1)
    80003306:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003308:	0001d797          	auipc	a5,0x1d
    8000330c:	07878793          	addi	a5,a5,120 # 80020380 <bcache+0x8000>
    80003310:	2b87b703          	ld	a4,696(a5)
    80003314:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003316:	0001d717          	auipc	a4,0x1d
    8000331a:	2d270713          	addi	a4,a4,722 # 800205e8 <bcache+0x8268>
    8000331e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003320:	2b87b703          	ld	a4,696(a5)
    80003324:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003326:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000332a:	00015517          	auipc	a0,0x15
    8000332e:	05650513          	addi	a0,a0,86 # 80018380 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	97e080e7          	jalr	-1666(ra) # 80000cb0 <release>
}
    8000333a:	60e2                	ld	ra,24(sp)
    8000333c:	6442                	ld	s0,16(sp)
    8000333e:	64a2                	ld	s1,8(sp)
    80003340:	6902                	ld	s2,0(sp)
    80003342:	6105                	addi	sp,sp,32
    80003344:	8082                	ret
    panic("brelse");
    80003346:	00005517          	auipc	a0,0x5
    8000334a:	23a50513          	addi	a0,a0,570 # 80008580 <syscalls+0xe0>
    8000334e:	ffffd097          	auipc	ra,0xffffd
    80003352:	1f2080e7          	jalr	498(ra) # 80000540 <panic>

0000000080003356 <bpin>:

void
bpin(struct buf *b) {
    80003356:	1101                	addi	sp,sp,-32
    80003358:	ec06                	sd	ra,24(sp)
    8000335a:	e822                	sd	s0,16(sp)
    8000335c:	e426                	sd	s1,8(sp)
    8000335e:	1000                	addi	s0,sp,32
    80003360:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003362:	00015517          	auipc	a0,0x15
    80003366:	01e50513          	addi	a0,a0,30 # 80018380 <bcache>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	892080e7          	jalr	-1902(ra) # 80000bfc <acquire>
  b->refcnt++;
    80003372:	40bc                	lw	a5,64(s1)
    80003374:	2785                	addiw	a5,a5,1
    80003376:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003378:	00015517          	auipc	a0,0x15
    8000337c:	00850513          	addi	a0,a0,8 # 80018380 <bcache>
    80003380:	ffffe097          	auipc	ra,0xffffe
    80003384:	930080e7          	jalr	-1744(ra) # 80000cb0 <release>
}
    80003388:	60e2                	ld	ra,24(sp)
    8000338a:	6442                	ld	s0,16(sp)
    8000338c:	64a2                	ld	s1,8(sp)
    8000338e:	6105                	addi	sp,sp,32
    80003390:	8082                	ret

0000000080003392 <bunpin>:

void
bunpin(struct buf *b) {
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	e426                	sd	s1,8(sp)
    8000339a:	1000                	addi	s0,sp,32
    8000339c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000339e:	00015517          	auipc	a0,0x15
    800033a2:	fe250513          	addi	a0,a0,-30 # 80018380 <bcache>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	856080e7          	jalr	-1962(ra) # 80000bfc <acquire>
  b->refcnt--;
    800033ae:	40bc                	lw	a5,64(s1)
    800033b0:	37fd                	addiw	a5,a5,-1
    800033b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b4:	00015517          	auipc	a0,0x15
    800033b8:	fcc50513          	addi	a0,a0,-52 # 80018380 <bcache>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	8f4080e7          	jalr	-1804(ra) # 80000cb0 <release>
}
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	64a2                	ld	s1,8(sp)
    800033ca:	6105                	addi	sp,sp,32
    800033cc:	8082                	ret

00000000800033ce <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ce:	1101                	addi	sp,sp,-32
    800033d0:	ec06                	sd	ra,24(sp)
    800033d2:	e822                	sd	s0,16(sp)
    800033d4:	e426                	sd	s1,8(sp)
    800033d6:	e04a                	sd	s2,0(sp)
    800033d8:	1000                	addi	s0,sp,32
    800033da:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033dc:	00d5d59b          	srliw	a1,a1,0xd
    800033e0:	0001d797          	auipc	a5,0x1d
    800033e4:	67c7a783          	lw	a5,1660(a5) # 80020a5c <sb+0x1c>
    800033e8:	9dbd                	addw	a1,a1,a5
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	d9e080e7          	jalr	-610(ra) # 80003188 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033f2:	0074f713          	andi	a4,s1,7
    800033f6:	4785                	li	a5,1
    800033f8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033fc:	14ce                	slli	s1,s1,0x33
    800033fe:	90d9                	srli	s1,s1,0x36
    80003400:	00950733          	add	a4,a0,s1
    80003404:	05874703          	lbu	a4,88(a4)
    80003408:	00e7f6b3          	and	a3,a5,a4
    8000340c:	c69d                	beqz	a3,8000343a <bfree+0x6c>
    8000340e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003410:	94aa                	add	s1,s1,a0
    80003412:	fff7c793          	not	a5,a5
    80003416:	8ff9                	and	a5,a5,a4
    80003418:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000341c:	00001097          	auipc	ra,0x1
    80003420:	106080e7          	jalr	262(ra) # 80004522 <log_write>
  brelse(bp);
    80003424:	854a                	mv	a0,s2
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	e92080e7          	jalr	-366(ra) # 800032b8 <brelse>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	64a2                	ld	s1,8(sp)
    80003434:	6902                	ld	s2,0(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret
    panic("freeing free block");
    8000343a:	00005517          	auipc	a0,0x5
    8000343e:	14e50513          	addi	a0,a0,334 # 80008588 <syscalls+0xe8>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	0fe080e7          	jalr	254(ra) # 80000540 <panic>

000000008000344a <balloc>:
{
    8000344a:	711d                	addi	sp,sp,-96
    8000344c:	ec86                	sd	ra,88(sp)
    8000344e:	e8a2                	sd	s0,80(sp)
    80003450:	e4a6                	sd	s1,72(sp)
    80003452:	e0ca                	sd	s2,64(sp)
    80003454:	fc4e                	sd	s3,56(sp)
    80003456:	f852                	sd	s4,48(sp)
    80003458:	f456                	sd	s5,40(sp)
    8000345a:	f05a                	sd	s6,32(sp)
    8000345c:	ec5e                	sd	s7,24(sp)
    8000345e:	e862                	sd	s8,16(sp)
    80003460:	e466                	sd	s9,8(sp)
    80003462:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003464:	0001d797          	auipc	a5,0x1d
    80003468:	5e07a783          	lw	a5,1504(a5) # 80020a44 <sb+0x4>
    8000346c:	cbd1                	beqz	a5,80003500 <balloc+0xb6>
    8000346e:	8baa                	mv	s7,a0
    80003470:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003472:	0001db17          	auipc	s6,0x1d
    80003476:	5ceb0b13          	addi	s6,s6,1486 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000347c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003480:	6c89                	lui	s9,0x2
    80003482:	a831                	j	8000349e <balloc+0x54>
    brelse(bp);
    80003484:	854a                	mv	a0,s2
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	e32080e7          	jalr	-462(ra) # 800032b8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000348e:	015c87bb          	addw	a5,s9,s5
    80003492:	00078a9b          	sext.w	s5,a5
    80003496:	004b2703          	lw	a4,4(s6)
    8000349a:	06eaf363          	bgeu	s5,a4,80003500 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000349e:	41fad79b          	sraiw	a5,s5,0x1f
    800034a2:	0137d79b          	srliw	a5,a5,0x13
    800034a6:	015787bb          	addw	a5,a5,s5
    800034aa:	40d7d79b          	sraiw	a5,a5,0xd
    800034ae:	01cb2583          	lw	a1,28(s6)
    800034b2:	9dbd                	addw	a1,a1,a5
    800034b4:	855e                	mv	a0,s7
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	cd2080e7          	jalr	-814(ra) # 80003188 <bread>
    800034be:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c0:	004b2503          	lw	a0,4(s6)
    800034c4:	000a849b          	sext.w	s1,s5
    800034c8:	8662                	mv	a2,s8
    800034ca:	faa4fde3          	bgeu	s1,a0,80003484 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ce:	41f6579b          	sraiw	a5,a2,0x1f
    800034d2:	01d7d69b          	srliw	a3,a5,0x1d
    800034d6:	00c6873b          	addw	a4,a3,a2
    800034da:	00777793          	andi	a5,a4,7
    800034de:	9f95                	subw	a5,a5,a3
    800034e0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034e4:	4037571b          	sraiw	a4,a4,0x3
    800034e8:	00e906b3          	add	a3,s2,a4
    800034ec:	0586c683          	lbu	a3,88(a3)
    800034f0:	00d7f5b3          	and	a1,a5,a3
    800034f4:	cd91                	beqz	a1,80003510 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f6:	2605                	addiw	a2,a2,1
    800034f8:	2485                	addiw	s1,s1,1
    800034fa:	fd4618e3          	bne	a2,s4,800034ca <balloc+0x80>
    800034fe:	b759                	j	80003484 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003500:	00005517          	auipc	a0,0x5
    80003504:	0a050513          	addi	a0,a0,160 # 800085a0 <syscalls+0x100>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	038080e7          	jalr	56(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003510:	974a                	add	a4,a4,s2
    80003512:	8fd5                	or	a5,a5,a3
    80003514:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	008080e7          	jalr	8(ra) # 80004522 <log_write>
        brelse(bp);
    80003522:	854a                	mv	a0,s2
    80003524:	00000097          	auipc	ra,0x0
    80003528:	d94080e7          	jalr	-620(ra) # 800032b8 <brelse>
  bp = bread(dev, bno);
    8000352c:	85a6                	mv	a1,s1
    8000352e:	855e                	mv	a0,s7
    80003530:	00000097          	auipc	ra,0x0
    80003534:	c58080e7          	jalr	-936(ra) # 80003188 <bread>
    80003538:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000353a:	40000613          	li	a2,1024
    8000353e:	4581                	li	a1,0
    80003540:	05850513          	addi	a0,a0,88
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	7b4080e7          	jalr	1972(ra) # 80000cf8 <memset>
  log_write(bp);
    8000354c:	854a                	mv	a0,s2
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	fd4080e7          	jalr	-44(ra) # 80004522 <log_write>
  brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	d60080e7          	jalr	-672(ra) # 800032b8 <brelse>
}
    80003560:	8526                	mv	a0,s1
    80003562:	60e6                	ld	ra,88(sp)
    80003564:	6446                	ld	s0,80(sp)
    80003566:	64a6                	ld	s1,72(sp)
    80003568:	6906                	ld	s2,64(sp)
    8000356a:	79e2                	ld	s3,56(sp)
    8000356c:	7a42                	ld	s4,48(sp)
    8000356e:	7aa2                	ld	s5,40(sp)
    80003570:	7b02                	ld	s6,32(sp)
    80003572:	6be2                	ld	s7,24(sp)
    80003574:	6c42                	ld	s8,16(sp)
    80003576:	6ca2                	ld	s9,8(sp)
    80003578:	6125                	addi	sp,sp,96
    8000357a:	8082                	ret

000000008000357c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000357c:	7179                	addi	sp,sp,-48
    8000357e:	f406                	sd	ra,40(sp)
    80003580:	f022                	sd	s0,32(sp)
    80003582:	ec26                	sd	s1,24(sp)
    80003584:	e84a                	sd	s2,16(sp)
    80003586:	e44e                	sd	s3,8(sp)
    80003588:	e052                	sd	s4,0(sp)
    8000358a:	1800                	addi	s0,sp,48
    8000358c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000358e:	47ad                	li	a5,11
    80003590:	04b7fe63          	bgeu	a5,a1,800035ec <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003594:	ff45849b          	addiw	s1,a1,-12
    80003598:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000359c:	0ff00793          	li	a5,255
    800035a0:	0ae7e463          	bltu	a5,a4,80003648 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a4:	08052583          	lw	a1,128(a0)
    800035a8:	c5b5                	beqz	a1,80003614 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035aa:	00092503          	lw	a0,0(s2)
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	bda080e7          	jalr	-1062(ra) # 80003188 <bread>
    800035b6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035bc:	02049713          	slli	a4,s1,0x20
    800035c0:	01e75593          	srli	a1,a4,0x1e
    800035c4:	00b784b3          	add	s1,a5,a1
    800035c8:	0004a983          	lw	s3,0(s1)
    800035cc:	04098e63          	beqz	s3,80003628 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035d0:	8552                	mv	a0,s4
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	ce6080e7          	jalr	-794(ra) # 800032b8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035da:	854e                	mv	a0,s3
    800035dc:	70a2                	ld	ra,40(sp)
    800035de:	7402                	ld	s0,32(sp)
    800035e0:	64e2                	ld	s1,24(sp)
    800035e2:	6942                	ld	s2,16(sp)
    800035e4:	69a2                	ld	s3,8(sp)
    800035e6:	6a02                	ld	s4,0(sp)
    800035e8:	6145                	addi	sp,sp,48
    800035ea:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035ec:	02059793          	slli	a5,a1,0x20
    800035f0:	01e7d593          	srli	a1,a5,0x1e
    800035f4:	00b504b3          	add	s1,a0,a1
    800035f8:	0504a983          	lw	s3,80(s1)
    800035fc:	fc099fe3          	bnez	s3,800035da <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003600:	4108                	lw	a0,0(a0)
    80003602:	00000097          	auipc	ra,0x0
    80003606:	e48080e7          	jalr	-440(ra) # 8000344a <balloc>
    8000360a:	0005099b          	sext.w	s3,a0
    8000360e:	0534a823          	sw	s3,80(s1)
    80003612:	b7e1                	j	800035da <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003614:	4108                	lw	a0,0(a0)
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	e34080e7          	jalr	-460(ra) # 8000344a <balloc>
    8000361e:	0005059b          	sext.w	a1,a0
    80003622:	08b92023          	sw	a1,128(s2)
    80003626:	b751                	j	800035aa <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003628:	00092503          	lw	a0,0(s2)
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	e1e080e7          	jalr	-482(ra) # 8000344a <balloc>
    80003634:	0005099b          	sext.w	s3,a0
    80003638:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000363c:	8552                	mv	a0,s4
    8000363e:	00001097          	auipc	ra,0x1
    80003642:	ee4080e7          	jalr	-284(ra) # 80004522 <log_write>
    80003646:	b769                	j	800035d0 <bmap+0x54>
  panic("bmap: out of range");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	f7050513          	addi	a0,a0,-144 # 800085b8 <syscalls+0x118>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	ef0080e7          	jalr	-272(ra) # 80000540 <panic>

0000000080003658 <iget>:
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	e052                	sd	s4,0(sp)
    80003666:	1800                	addi	s0,sp,48
    80003668:	89aa                	mv	s3,a0
    8000366a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000366c:	0001d517          	auipc	a0,0x1d
    80003670:	3f450513          	addi	a0,a0,1012 # 80020a60 <icache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	588080e7          	jalr	1416(ra) # 80000bfc <acquire>
  empty = 0;
    8000367c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000367e:	0001d497          	auipc	s1,0x1d
    80003682:	3fa48493          	addi	s1,s1,1018 # 80020a78 <icache+0x18>
    80003686:	0001f697          	auipc	a3,0x1f
    8000368a:	e8268693          	addi	a3,a3,-382 # 80022508 <log>
    8000368e:	a039                	j	8000369c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003690:	02090b63          	beqz	s2,800036c6 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003694:	08848493          	addi	s1,s1,136
    80003698:	02d48a63          	beq	s1,a3,800036cc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000369c:	449c                	lw	a5,8(s1)
    8000369e:	fef059e3          	blez	a5,80003690 <iget+0x38>
    800036a2:	4098                	lw	a4,0(s1)
    800036a4:	ff3716e3          	bne	a4,s3,80003690 <iget+0x38>
    800036a8:	40d8                	lw	a4,4(s1)
    800036aa:	ff4713e3          	bne	a4,s4,80003690 <iget+0x38>
      ip->ref++;
    800036ae:	2785                	addiw	a5,a5,1
    800036b0:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036b2:	0001d517          	auipc	a0,0x1d
    800036b6:	3ae50513          	addi	a0,a0,942 # 80020a60 <icache>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5f6080e7          	jalr	1526(ra) # 80000cb0 <release>
      return ip;
    800036c2:	8926                	mv	s2,s1
    800036c4:	a03d                	j	800036f2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c6:	f7f9                	bnez	a5,80003694 <iget+0x3c>
    800036c8:	8926                	mv	s2,s1
    800036ca:	b7e9                	j	80003694 <iget+0x3c>
  if(empty == 0)
    800036cc:	02090c63          	beqz	s2,80003704 <iget+0xac>
  ip->dev = dev;
    800036d0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d8:	4785                	li	a5,1
    800036da:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036de:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036e2:	0001d517          	auipc	a0,0x1d
    800036e6:	37e50513          	addi	a0,a0,894 # 80020a60 <icache>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	5c6080e7          	jalr	1478(ra) # 80000cb0 <release>
}
    800036f2:	854a                	mv	a0,s2
    800036f4:	70a2                	ld	ra,40(sp)
    800036f6:	7402                	ld	s0,32(sp)
    800036f8:	64e2                	ld	s1,24(sp)
    800036fa:	6942                	ld	s2,16(sp)
    800036fc:	69a2                	ld	s3,8(sp)
    800036fe:	6a02                	ld	s4,0(sp)
    80003700:	6145                	addi	sp,sp,48
    80003702:	8082                	ret
    panic("iget: no inodes");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	ecc50513          	addi	a0,a0,-308 # 800085d0 <syscalls+0x130>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e34080e7          	jalr	-460(ra) # 80000540 <panic>

0000000080003714 <fsinit>:
fsinit(int dev) {
    80003714:	7179                	addi	sp,sp,-48
    80003716:	f406                	sd	ra,40(sp)
    80003718:	f022                	sd	s0,32(sp)
    8000371a:	ec26                	sd	s1,24(sp)
    8000371c:	e84a                	sd	s2,16(sp)
    8000371e:	e44e                	sd	s3,8(sp)
    80003720:	1800                	addi	s0,sp,48
    80003722:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003724:	4585                	li	a1,1
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	a62080e7          	jalr	-1438(ra) # 80003188 <bread>
    8000372e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003730:	0001d997          	auipc	s3,0x1d
    80003734:	31098993          	addi	s3,s3,784 # 80020a40 <sb>
    80003738:	02000613          	li	a2,32
    8000373c:	05850593          	addi	a1,a0,88
    80003740:	854e                	mv	a0,s3
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	612080e7          	jalr	1554(ra) # 80000d54 <memmove>
  brelse(bp);
    8000374a:	8526                	mv	a0,s1
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	b6c080e7          	jalr	-1172(ra) # 800032b8 <brelse>
  if(sb.magic != FSMAGIC)
    80003754:	0009a703          	lw	a4,0(s3)
    80003758:	102037b7          	lui	a5,0x10203
    8000375c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003760:	02f71263          	bne	a4,a5,80003784 <fsinit+0x70>
  initlog(dev, &sb);
    80003764:	0001d597          	auipc	a1,0x1d
    80003768:	2dc58593          	addi	a1,a1,732 # 80020a40 <sb>
    8000376c:	854a                	mv	a0,s2
    8000376e:	00001097          	auipc	ra,0x1
    80003772:	b3a080e7          	jalr	-1222(ra) # 800042a8 <initlog>
}
    80003776:	70a2                	ld	ra,40(sp)
    80003778:	7402                	ld	s0,32(sp)
    8000377a:	64e2                	ld	s1,24(sp)
    8000377c:	6942                	ld	s2,16(sp)
    8000377e:	69a2                	ld	s3,8(sp)
    80003780:	6145                	addi	sp,sp,48
    80003782:	8082                	ret
    panic("invalid file system");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	e5c50513          	addi	a0,a0,-420 # 800085e0 <syscalls+0x140>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	db4080e7          	jalr	-588(ra) # 80000540 <panic>

0000000080003794 <iinit>:
{
    80003794:	7179                	addi	sp,sp,-48
    80003796:	f406                	sd	ra,40(sp)
    80003798:	f022                	sd	s0,32(sp)
    8000379a:	ec26                	sd	s1,24(sp)
    8000379c:	e84a                	sd	s2,16(sp)
    8000379e:	e44e                	sd	s3,8(sp)
    800037a0:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800037a2:	00005597          	auipc	a1,0x5
    800037a6:	e5658593          	addi	a1,a1,-426 # 800085f8 <syscalls+0x158>
    800037aa:	0001d517          	auipc	a0,0x1d
    800037ae:	2b650513          	addi	a0,a0,694 # 80020a60 <icache>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	3ba080e7          	jalr	954(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037ba:	0001d497          	auipc	s1,0x1d
    800037be:	2ce48493          	addi	s1,s1,718 # 80020a88 <icache+0x28>
    800037c2:	0001f997          	auipc	s3,0x1f
    800037c6:	d5698993          	addi	s3,s3,-682 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037ca:	00005917          	auipc	s2,0x5
    800037ce:	e3690913          	addi	s2,s2,-458 # 80008600 <syscalls+0x160>
    800037d2:	85ca                	mv	a1,s2
    800037d4:	8526                	mv	a0,s1
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	e3a080e7          	jalr	-454(ra) # 80004610 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037de:	08848493          	addi	s1,s1,136
    800037e2:	ff3498e3          	bne	s1,s3,800037d2 <iinit+0x3e>
}
    800037e6:	70a2                	ld	ra,40(sp)
    800037e8:	7402                	ld	s0,32(sp)
    800037ea:	64e2                	ld	s1,24(sp)
    800037ec:	6942                	ld	s2,16(sp)
    800037ee:	69a2                	ld	s3,8(sp)
    800037f0:	6145                	addi	sp,sp,48
    800037f2:	8082                	ret

00000000800037f4 <ialloc>:
{
    800037f4:	715d                	addi	sp,sp,-80
    800037f6:	e486                	sd	ra,72(sp)
    800037f8:	e0a2                	sd	s0,64(sp)
    800037fa:	fc26                	sd	s1,56(sp)
    800037fc:	f84a                	sd	s2,48(sp)
    800037fe:	f44e                	sd	s3,40(sp)
    80003800:	f052                	sd	s4,32(sp)
    80003802:	ec56                	sd	s5,24(sp)
    80003804:	e85a                	sd	s6,16(sp)
    80003806:	e45e                	sd	s7,8(sp)
    80003808:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000380a:	0001d717          	auipc	a4,0x1d
    8000380e:	24272703          	lw	a4,578(a4) # 80020a4c <sb+0xc>
    80003812:	4785                	li	a5,1
    80003814:	04e7fa63          	bgeu	a5,a4,80003868 <ialloc+0x74>
    80003818:	8aaa                	mv	s5,a0
    8000381a:	8bae                	mv	s7,a1
    8000381c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000381e:	0001da17          	auipc	s4,0x1d
    80003822:	222a0a13          	addi	s4,s4,546 # 80020a40 <sb>
    80003826:	00048b1b          	sext.w	s6,s1
    8000382a:	0044d793          	srli	a5,s1,0x4
    8000382e:	018a2583          	lw	a1,24(s4)
    80003832:	9dbd                	addw	a1,a1,a5
    80003834:	8556                	mv	a0,s5
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	952080e7          	jalr	-1710(ra) # 80003188 <bread>
    8000383e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003840:	05850993          	addi	s3,a0,88
    80003844:	00f4f793          	andi	a5,s1,15
    80003848:	079a                	slli	a5,a5,0x6
    8000384a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000384c:	00099783          	lh	a5,0(s3)
    80003850:	c785                	beqz	a5,80003878 <ialloc+0x84>
    brelse(bp);
    80003852:	00000097          	auipc	ra,0x0
    80003856:	a66080e7          	jalr	-1434(ra) # 800032b8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000385a:	0485                	addi	s1,s1,1
    8000385c:	00ca2703          	lw	a4,12(s4)
    80003860:	0004879b          	sext.w	a5,s1
    80003864:	fce7e1e3          	bltu	a5,a4,80003826 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	da050513          	addi	a0,a0,-608 # 80008608 <syscalls+0x168>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cd0080e7          	jalr	-816(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003878:	04000613          	li	a2,64
    8000387c:	4581                	li	a1,0
    8000387e:	854e                	mv	a0,s3
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	478080e7          	jalr	1144(ra) # 80000cf8 <memset>
      dip->type = type;
    80003888:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c94080e7          	jalr	-876(ra) # 80004522 <log_write>
      brelse(bp);
    80003896:	854a                	mv	a0,s2
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	a20080e7          	jalr	-1504(ra) # 800032b8 <brelse>
      return iget(dev, inum);
    800038a0:	85da                	mv	a1,s6
    800038a2:	8556                	mv	a0,s5
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	db4080e7          	jalr	-588(ra) # 80003658 <iget>
}
    800038ac:	60a6                	ld	ra,72(sp)
    800038ae:	6406                	ld	s0,64(sp)
    800038b0:	74e2                	ld	s1,56(sp)
    800038b2:	7942                	ld	s2,48(sp)
    800038b4:	79a2                	ld	s3,40(sp)
    800038b6:	7a02                	ld	s4,32(sp)
    800038b8:	6ae2                	ld	s5,24(sp)
    800038ba:	6b42                	ld	s6,16(sp)
    800038bc:	6ba2                	ld	s7,8(sp)
    800038be:	6161                	addi	sp,sp,80
    800038c0:	8082                	ret

00000000800038c2 <iupdate>:
{
    800038c2:	1101                	addi	sp,sp,-32
    800038c4:	ec06                	sd	ra,24(sp)
    800038c6:	e822                	sd	s0,16(sp)
    800038c8:	e426                	sd	s1,8(sp)
    800038ca:	e04a                	sd	s2,0(sp)
    800038cc:	1000                	addi	s0,sp,32
    800038ce:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d0:	415c                	lw	a5,4(a0)
    800038d2:	0047d79b          	srliw	a5,a5,0x4
    800038d6:	0001d597          	auipc	a1,0x1d
    800038da:	1825a583          	lw	a1,386(a1) # 80020a58 <sb+0x18>
    800038de:	9dbd                	addw	a1,a1,a5
    800038e0:	4108                	lw	a0,0(a0)
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	8a6080e7          	jalr	-1882(ra) # 80003188 <bread>
    800038ea:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ec:	05850793          	addi	a5,a0,88
    800038f0:	40c8                	lw	a0,4(s1)
    800038f2:	893d                	andi	a0,a0,15
    800038f4:	051a                	slli	a0,a0,0x6
    800038f6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f8:	04449703          	lh	a4,68(s1)
    800038fc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003900:	04649703          	lh	a4,70(s1)
    80003904:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003908:	04849703          	lh	a4,72(s1)
    8000390c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003910:	04a49703          	lh	a4,74(s1)
    80003914:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003918:	44f8                	lw	a4,76(s1)
    8000391a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000391c:	03400613          	li	a2,52
    80003920:	05048593          	addi	a1,s1,80
    80003924:	0531                	addi	a0,a0,12
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	42e080e7          	jalr	1070(ra) # 80000d54 <memmove>
  log_write(bp);
    8000392e:	854a                	mv	a0,s2
    80003930:	00001097          	auipc	ra,0x1
    80003934:	bf2080e7          	jalr	-1038(ra) # 80004522 <log_write>
  brelse(bp);
    80003938:	854a                	mv	a0,s2
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	97e080e7          	jalr	-1666(ra) # 800032b8 <brelse>
}
    80003942:	60e2                	ld	ra,24(sp)
    80003944:	6442                	ld	s0,16(sp)
    80003946:	64a2                	ld	s1,8(sp)
    80003948:	6902                	ld	s2,0(sp)
    8000394a:	6105                	addi	sp,sp,32
    8000394c:	8082                	ret

000000008000394e <idup>:
{
    8000394e:	1101                	addi	sp,sp,-32
    80003950:	ec06                	sd	ra,24(sp)
    80003952:	e822                	sd	s0,16(sp)
    80003954:	e426                	sd	s1,8(sp)
    80003956:	1000                	addi	s0,sp,32
    80003958:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000395a:	0001d517          	auipc	a0,0x1d
    8000395e:	10650513          	addi	a0,a0,262 # 80020a60 <icache>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	29a080e7          	jalr	666(ra) # 80000bfc <acquire>
  ip->ref++;
    8000396a:	449c                	lw	a5,8(s1)
    8000396c:	2785                	addiw	a5,a5,1
    8000396e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003970:	0001d517          	auipc	a0,0x1d
    80003974:	0f050513          	addi	a0,a0,240 # 80020a60 <icache>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	338080e7          	jalr	824(ra) # 80000cb0 <release>
}
    80003980:	8526                	mv	a0,s1
    80003982:	60e2                	ld	ra,24(sp)
    80003984:	6442                	ld	s0,16(sp)
    80003986:	64a2                	ld	s1,8(sp)
    80003988:	6105                	addi	sp,sp,32
    8000398a:	8082                	ret

000000008000398c <ilock>:
{
    8000398c:	1101                	addi	sp,sp,-32
    8000398e:	ec06                	sd	ra,24(sp)
    80003990:	e822                	sd	s0,16(sp)
    80003992:	e426                	sd	s1,8(sp)
    80003994:	e04a                	sd	s2,0(sp)
    80003996:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003998:	c115                	beqz	a0,800039bc <ilock+0x30>
    8000399a:	84aa                	mv	s1,a0
    8000399c:	451c                	lw	a5,8(a0)
    8000399e:	00f05f63          	blez	a5,800039bc <ilock+0x30>
  acquiresleep(&ip->lock);
    800039a2:	0541                	addi	a0,a0,16
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	ca6080e7          	jalr	-858(ra) # 8000464a <acquiresleep>
  if(ip->valid == 0){
    800039ac:	40bc                	lw	a5,64(s1)
    800039ae:	cf99                	beqz	a5,800039cc <ilock+0x40>
}
    800039b0:	60e2                	ld	ra,24(sp)
    800039b2:	6442                	ld	s0,16(sp)
    800039b4:	64a2                	ld	s1,8(sp)
    800039b6:	6902                	ld	s2,0(sp)
    800039b8:	6105                	addi	sp,sp,32
    800039ba:	8082                	ret
    panic("ilock");
    800039bc:	00005517          	auipc	a0,0x5
    800039c0:	c6450513          	addi	a0,a0,-924 # 80008620 <syscalls+0x180>
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	b7c080e7          	jalr	-1156(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039cc:	40dc                	lw	a5,4(s1)
    800039ce:	0047d79b          	srliw	a5,a5,0x4
    800039d2:	0001d597          	auipc	a1,0x1d
    800039d6:	0865a583          	lw	a1,134(a1) # 80020a58 <sb+0x18>
    800039da:	9dbd                	addw	a1,a1,a5
    800039dc:	4088                	lw	a0,0(s1)
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	7aa080e7          	jalr	1962(ra) # 80003188 <bread>
    800039e6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e8:	05850593          	addi	a1,a0,88
    800039ec:	40dc                	lw	a5,4(s1)
    800039ee:	8bbd                	andi	a5,a5,15
    800039f0:	079a                	slli	a5,a5,0x6
    800039f2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f4:	00059783          	lh	a5,0(a1)
    800039f8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039fc:	00259783          	lh	a5,2(a1)
    80003a00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a04:	00459783          	lh	a5,4(a1)
    80003a08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a0c:	00659783          	lh	a5,6(a1)
    80003a10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a14:	459c                	lw	a5,8(a1)
    80003a16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a18:	03400613          	li	a2,52
    80003a1c:	05b1                	addi	a1,a1,12
    80003a1e:	05048513          	addi	a0,s1,80
    80003a22:	ffffd097          	auipc	ra,0xffffd
    80003a26:	332080e7          	jalr	818(ra) # 80000d54 <memmove>
    brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	88c080e7          	jalr	-1908(ra) # 800032b8 <brelse>
    ip->valid = 1;
    80003a34:	4785                	li	a5,1
    80003a36:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a38:	04449783          	lh	a5,68(s1)
    80003a3c:	fbb5                	bnez	a5,800039b0 <ilock+0x24>
      panic("ilock: no type");
    80003a3e:	00005517          	auipc	a0,0x5
    80003a42:	bea50513          	addi	a0,a0,-1046 # 80008628 <syscalls+0x188>
    80003a46:	ffffd097          	auipc	ra,0xffffd
    80003a4a:	afa080e7          	jalr	-1286(ra) # 80000540 <panic>

0000000080003a4e <iunlock>:
{
    80003a4e:	1101                	addi	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	e04a                	sd	s2,0(sp)
    80003a58:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a5a:	c905                	beqz	a0,80003a8a <iunlock+0x3c>
    80003a5c:	84aa                	mv	s1,a0
    80003a5e:	01050913          	addi	s2,a0,16
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	c80080e7          	jalr	-896(ra) # 800046e4 <holdingsleep>
    80003a6c:	cd19                	beqz	a0,80003a8a <iunlock+0x3c>
    80003a6e:	449c                	lw	a5,8(s1)
    80003a70:	00f05d63          	blez	a5,80003a8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a74:	854a                	mv	a0,s2
    80003a76:	00001097          	auipc	ra,0x1
    80003a7a:	c2a080e7          	jalr	-982(ra) # 800046a0 <releasesleep>
}
    80003a7e:	60e2                	ld	ra,24(sp)
    80003a80:	6442                	ld	s0,16(sp)
    80003a82:	64a2                	ld	s1,8(sp)
    80003a84:	6902                	ld	s2,0(sp)
    80003a86:	6105                	addi	sp,sp,32
    80003a88:	8082                	ret
    panic("iunlock");
    80003a8a:	00005517          	auipc	a0,0x5
    80003a8e:	bae50513          	addi	a0,a0,-1106 # 80008638 <syscalls+0x198>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	aae080e7          	jalr	-1362(ra) # 80000540 <panic>

0000000080003a9a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a9a:	7179                	addi	sp,sp,-48
    80003a9c:	f406                	sd	ra,40(sp)
    80003a9e:	f022                	sd	s0,32(sp)
    80003aa0:	ec26                	sd	s1,24(sp)
    80003aa2:	e84a                	sd	s2,16(sp)
    80003aa4:	e44e                	sd	s3,8(sp)
    80003aa6:	e052                	sd	s4,0(sp)
    80003aa8:	1800                	addi	s0,sp,48
    80003aaa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aac:	05050493          	addi	s1,a0,80
    80003ab0:	08050913          	addi	s2,a0,128
    80003ab4:	a021                	j	80003abc <itrunc+0x22>
    80003ab6:	0491                	addi	s1,s1,4
    80003ab8:	01248d63          	beq	s1,s2,80003ad2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003abc:	408c                	lw	a1,0(s1)
    80003abe:	dde5                	beqz	a1,80003ab6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ac0:	0009a503          	lw	a0,0(s3)
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	90a080e7          	jalr	-1782(ra) # 800033ce <bfree>
      ip->addrs[i] = 0;
    80003acc:	0004a023          	sw	zero,0(s1)
    80003ad0:	b7dd                	j	80003ab6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ad2:	0809a583          	lw	a1,128(s3)
    80003ad6:	e185                	bnez	a1,80003af6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003adc:	854e                	mv	a0,s3
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	de4080e7          	jalr	-540(ra) # 800038c2 <iupdate>
}
    80003ae6:	70a2                	ld	ra,40(sp)
    80003ae8:	7402                	ld	s0,32(sp)
    80003aea:	64e2                	ld	s1,24(sp)
    80003aec:	6942                	ld	s2,16(sp)
    80003aee:	69a2                	ld	s3,8(sp)
    80003af0:	6a02                	ld	s4,0(sp)
    80003af2:	6145                	addi	sp,sp,48
    80003af4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af6:	0009a503          	lw	a0,0(s3)
    80003afa:	fffff097          	auipc	ra,0xfffff
    80003afe:	68e080e7          	jalr	1678(ra) # 80003188 <bread>
    80003b02:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b04:	05850493          	addi	s1,a0,88
    80003b08:	45850913          	addi	s2,a0,1112
    80003b0c:	a021                	j	80003b14 <itrunc+0x7a>
    80003b0e:	0491                	addi	s1,s1,4
    80003b10:	01248b63          	beq	s1,s2,80003b26 <itrunc+0x8c>
      if(a[j])
    80003b14:	408c                	lw	a1,0(s1)
    80003b16:	dde5                	beqz	a1,80003b0e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b18:	0009a503          	lw	a0,0(s3)
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	8b2080e7          	jalr	-1870(ra) # 800033ce <bfree>
    80003b24:	b7ed                	j	80003b0e <itrunc+0x74>
    brelse(bp);
    80003b26:	8552                	mv	a0,s4
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	790080e7          	jalr	1936(ra) # 800032b8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b30:	0809a583          	lw	a1,128(s3)
    80003b34:	0009a503          	lw	a0,0(s3)
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	896080e7          	jalr	-1898(ra) # 800033ce <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b40:	0809a023          	sw	zero,128(s3)
    80003b44:	bf51                	j	80003ad8 <itrunc+0x3e>

0000000080003b46 <iput>:
{
    80003b46:	1101                	addi	sp,sp,-32
    80003b48:	ec06                	sd	ra,24(sp)
    80003b4a:	e822                	sd	s0,16(sp)
    80003b4c:	e426                	sd	s1,8(sp)
    80003b4e:	e04a                	sd	s2,0(sp)
    80003b50:	1000                	addi	s0,sp,32
    80003b52:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b54:	0001d517          	auipc	a0,0x1d
    80003b58:	f0c50513          	addi	a0,a0,-244 # 80020a60 <icache>
    80003b5c:	ffffd097          	auipc	ra,0xffffd
    80003b60:	0a0080e7          	jalr	160(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b64:	4498                	lw	a4,8(s1)
    80003b66:	4785                	li	a5,1
    80003b68:	02f70363          	beq	a4,a5,80003b8e <iput+0x48>
  ip->ref--;
    80003b6c:	449c                	lw	a5,8(s1)
    80003b6e:	37fd                	addiw	a5,a5,-1
    80003b70:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b72:	0001d517          	auipc	a0,0x1d
    80003b76:	eee50513          	addi	a0,a0,-274 # 80020a60 <icache>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	136080e7          	jalr	310(ra) # 80000cb0 <release>
}
    80003b82:	60e2                	ld	ra,24(sp)
    80003b84:	6442                	ld	s0,16(sp)
    80003b86:	64a2                	ld	s1,8(sp)
    80003b88:	6902                	ld	s2,0(sp)
    80003b8a:	6105                	addi	sp,sp,32
    80003b8c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b8e:	40bc                	lw	a5,64(s1)
    80003b90:	dff1                	beqz	a5,80003b6c <iput+0x26>
    80003b92:	04a49783          	lh	a5,74(s1)
    80003b96:	fbf9                	bnez	a5,80003b6c <iput+0x26>
    acquiresleep(&ip->lock);
    80003b98:	01048913          	addi	s2,s1,16
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	00001097          	auipc	ra,0x1
    80003ba2:	aac080e7          	jalr	-1364(ra) # 8000464a <acquiresleep>
    release(&icache.lock);
    80003ba6:	0001d517          	auipc	a0,0x1d
    80003baa:	eba50513          	addi	a0,a0,-326 # 80020a60 <icache>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	102080e7          	jalr	258(ra) # 80000cb0 <release>
    itrunc(ip);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	ee2080e7          	jalr	-286(ra) # 80003a9a <itrunc>
    ip->type = 0;
    80003bc0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	cfc080e7          	jalr	-772(ra) # 800038c2 <iupdate>
    ip->valid = 0;
    80003bce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bd2:	854a                	mv	a0,s2
    80003bd4:	00001097          	auipc	ra,0x1
    80003bd8:	acc080e7          	jalr	-1332(ra) # 800046a0 <releasesleep>
    acquire(&icache.lock);
    80003bdc:	0001d517          	auipc	a0,0x1d
    80003be0:	e8450513          	addi	a0,a0,-380 # 80020a60 <icache>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	018080e7          	jalr	24(ra) # 80000bfc <acquire>
    80003bec:	b741                	j	80003b6c <iput+0x26>

0000000080003bee <iunlockput>:
{
    80003bee:	1101                	addi	sp,sp,-32
    80003bf0:	ec06                	sd	ra,24(sp)
    80003bf2:	e822                	sd	s0,16(sp)
    80003bf4:	e426                	sd	s1,8(sp)
    80003bf6:	1000                	addi	s0,sp,32
    80003bf8:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	e54080e7          	jalr	-428(ra) # 80003a4e <iunlock>
  iput(ip);
    80003c02:	8526                	mv	a0,s1
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	f42080e7          	jalr	-190(ra) # 80003b46 <iput>
}
    80003c0c:	60e2                	ld	ra,24(sp)
    80003c0e:	6442                	ld	s0,16(sp)
    80003c10:	64a2                	ld	s1,8(sp)
    80003c12:	6105                	addi	sp,sp,32
    80003c14:	8082                	ret

0000000080003c16 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c16:	1141                	addi	sp,sp,-16
    80003c18:	e422                	sd	s0,8(sp)
    80003c1a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c1c:	411c                	lw	a5,0(a0)
    80003c1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c20:	415c                	lw	a5,4(a0)
    80003c22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c24:	04451783          	lh	a5,68(a0)
    80003c28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c2c:	04a51783          	lh	a5,74(a0)
    80003c30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c34:	04c56783          	lwu	a5,76(a0)
    80003c38:	e99c                	sd	a5,16(a1)
}
    80003c3a:	6422                	ld	s0,8(sp)
    80003c3c:	0141                	addi	sp,sp,16
    80003c3e:	8082                	ret

0000000080003c40 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c40:	457c                	lw	a5,76(a0)
    80003c42:	0ed7e863          	bltu	a5,a3,80003d32 <readi+0xf2>
{
    80003c46:	7159                	addi	sp,sp,-112
    80003c48:	f486                	sd	ra,104(sp)
    80003c4a:	f0a2                	sd	s0,96(sp)
    80003c4c:	eca6                	sd	s1,88(sp)
    80003c4e:	e8ca                	sd	s2,80(sp)
    80003c50:	e4ce                	sd	s3,72(sp)
    80003c52:	e0d2                	sd	s4,64(sp)
    80003c54:	fc56                	sd	s5,56(sp)
    80003c56:	f85a                	sd	s6,48(sp)
    80003c58:	f45e                	sd	s7,40(sp)
    80003c5a:	f062                	sd	s8,32(sp)
    80003c5c:	ec66                	sd	s9,24(sp)
    80003c5e:	e86a                	sd	s10,16(sp)
    80003c60:	e46e                	sd	s11,8(sp)
    80003c62:	1880                	addi	s0,sp,112
    80003c64:	8baa                	mv	s7,a0
    80003c66:	8c2e                	mv	s8,a1
    80003c68:	8ab2                	mv	s5,a2
    80003c6a:	84b6                	mv	s1,a3
    80003c6c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c6e:	9f35                	addw	a4,a4,a3
    return 0;
    80003c70:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c72:	08d76f63          	bltu	a4,a3,80003d10 <readi+0xd0>
  if(off + n > ip->size)
    80003c76:	00e7f463          	bgeu	a5,a4,80003c7e <readi+0x3e>
    n = ip->size - off;
    80003c7a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7e:	0a0b0863          	beqz	s6,80003d2e <readi+0xee>
    80003c82:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c84:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c88:	5cfd                	li	s9,-1
    80003c8a:	a82d                	j	80003cc4 <readi+0x84>
    80003c8c:	020a1d93          	slli	s11,s4,0x20
    80003c90:	020ddd93          	srli	s11,s11,0x20
    80003c94:	05890793          	addi	a5,s2,88
    80003c98:	86ee                	mv	a3,s11
    80003c9a:	963e                	add	a2,a2,a5
    80003c9c:	85d6                	mv	a1,s5
    80003c9e:	8562                	mv	a0,s8
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	b0e080e7          	jalr	-1266(ra) # 800027ae <either_copyout>
    80003ca8:	05950d63          	beq	a0,s9,80003d02 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003cac:	854a                	mv	a0,s2
    80003cae:	fffff097          	auipc	ra,0xfffff
    80003cb2:	60a080e7          	jalr	1546(ra) # 800032b8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb6:	013a09bb          	addw	s3,s4,s3
    80003cba:	009a04bb          	addw	s1,s4,s1
    80003cbe:	9aee                	add	s5,s5,s11
    80003cc0:	0569f663          	bgeu	s3,s6,80003d0c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc4:	000ba903          	lw	s2,0(s7)
    80003cc8:	00a4d59b          	srliw	a1,s1,0xa
    80003ccc:	855e                	mv	a0,s7
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	8ae080e7          	jalr	-1874(ra) # 8000357c <bmap>
    80003cd6:	0005059b          	sext.w	a1,a0
    80003cda:	854a                	mv	a0,s2
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	4ac080e7          	jalr	1196(ra) # 80003188 <bread>
    80003ce4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce6:	3ff4f613          	andi	a2,s1,1023
    80003cea:	40cd07bb          	subw	a5,s10,a2
    80003cee:	413b073b          	subw	a4,s6,s3
    80003cf2:	8a3e                	mv	s4,a5
    80003cf4:	2781                	sext.w	a5,a5
    80003cf6:	0007069b          	sext.w	a3,a4
    80003cfa:	f8f6f9e3          	bgeu	a3,a5,80003c8c <readi+0x4c>
    80003cfe:	8a3a                	mv	s4,a4
    80003d00:	b771                	j	80003c8c <readi+0x4c>
      brelse(bp);
    80003d02:	854a                	mv	a0,s2
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	5b4080e7          	jalr	1460(ra) # 800032b8 <brelse>
  }
  return tot;
    80003d0c:	0009851b          	sext.w	a0,s3
}
    80003d10:	70a6                	ld	ra,104(sp)
    80003d12:	7406                	ld	s0,96(sp)
    80003d14:	64e6                	ld	s1,88(sp)
    80003d16:	6946                	ld	s2,80(sp)
    80003d18:	69a6                	ld	s3,72(sp)
    80003d1a:	6a06                	ld	s4,64(sp)
    80003d1c:	7ae2                	ld	s5,56(sp)
    80003d1e:	7b42                	ld	s6,48(sp)
    80003d20:	7ba2                	ld	s7,40(sp)
    80003d22:	7c02                	ld	s8,32(sp)
    80003d24:	6ce2                	ld	s9,24(sp)
    80003d26:	6d42                	ld	s10,16(sp)
    80003d28:	6da2                	ld	s11,8(sp)
    80003d2a:	6165                	addi	sp,sp,112
    80003d2c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2e:	89da                	mv	s3,s6
    80003d30:	bff1                	j	80003d0c <readi+0xcc>
    return 0;
    80003d32:	4501                	li	a0,0
}
    80003d34:	8082                	ret

0000000080003d36 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d36:	457c                	lw	a5,76(a0)
    80003d38:	10d7e663          	bltu	a5,a3,80003e44 <writei+0x10e>
{
    80003d3c:	7159                	addi	sp,sp,-112
    80003d3e:	f486                	sd	ra,104(sp)
    80003d40:	f0a2                	sd	s0,96(sp)
    80003d42:	eca6                	sd	s1,88(sp)
    80003d44:	e8ca                	sd	s2,80(sp)
    80003d46:	e4ce                	sd	s3,72(sp)
    80003d48:	e0d2                	sd	s4,64(sp)
    80003d4a:	fc56                	sd	s5,56(sp)
    80003d4c:	f85a                	sd	s6,48(sp)
    80003d4e:	f45e                	sd	s7,40(sp)
    80003d50:	f062                	sd	s8,32(sp)
    80003d52:	ec66                	sd	s9,24(sp)
    80003d54:	e86a                	sd	s10,16(sp)
    80003d56:	e46e                	sd	s11,8(sp)
    80003d58:	1880                	addi	s0,sp,112
    80003d5a:	8baa                	mv	s7,a0
    80003d5c:	8c2e                	mv	s8,a1
    80003d5e:	8ab2                	mv	s5,a2
    80003d60:	8936                	mv	s2,a3
    80003d62:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d64:	00e687bb          	addw	a5,a3,a4
    80003d68:	0ed7e063          	bltu	a5,a3,80003e48 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d6c:	00043737          	lui	a4,0x43
    80003d70:	0cf76e63          	bltu	a4,a5,80003e4c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d74:	0a0b0763          	beqz	s6,80003e22 <writei+0xec>
    80003d78:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d7a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d7e:	5cfd                	li	s9,-1
    80003d80:	a091                	j	80003dc4 <writei+0x8e>
    80003d82:	02099d93          	slli	s11,s3,0x20
    80003d86:	020ddd93          	srli	s11,s11,0x20
    80003d8a:	05848793          	addi	a5,s1,88
    80003d8e:	86ee                	mv	a3,s11
    80003d90:	8656                	mv	a2,s5
    80003d92:	85e2                	mv	a1,s8
    80003d94:	953e                	add	a0,a0,a5
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	a6e080e7          	jalr	-1426(ra) # 80002804 <either_copyin>
    80003d9e:	07950263          	beq	a0,s9,80003e02 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003da2:	8526                	mv	a0,s1
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	77e080e7          	jalr	1918(ra) # 80004522 <log_write>
    brelse(bp);
    80003dac:	8526                	mv	a0,s1
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	50a080e7          	jalr	1290(ra) # 800032b8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db6:	01498a3b          	addw	s4,s3,s4
    80003dba:	0129893b          	addw	s2,s3,s2
    80003dbe:	9aee                	add	s5,s5,s11
    80003dc0:	056a7663          	bgeu	s4,s6,80003e0c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dc4:	000ba483          	lw	s1,0(s7)
    80003dc8:	00a9559b          	srliw	a1,s2,0xa
    80003dcc:	855e                	mv	a0,s7
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	7ae080e7          	jalr	1966(ra) # 8000357c <bmap>
    80003dd6:	0005059b          	sext.w	a1,a0
    80003dda:	8526                	mv	a0,s1
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	3ac080e7          	jalr	940(ra) # 80003188 <bread>
    80003de4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de6:	3ff97513          	andi	a0,s2,1023
    80003dea:	40ad07bb          	subw	a5,s10,a0
    80003dee:	414b073b          	subw	a4,s6,s4
    80003df2:	89be                	mv	s3,a5
    80003df4:	2781                	sext.w	a5,a5
    80003df6:	0007069b          	sext.w	a3,a4
    80003dfa:	f8f6f4e3          	bgeu	a3,a5,80003d82 <writei+0x4c>
    80003dfe:	89ba                	mv	s3,a4
    80003e00:	b749                	j	80003d82 <writei+0x4c>
      brelse(bp);
    80003e02:	8526                	mv	a0,s1
    80003e04:	fffff097          	auipc	ra,0xfffff
    80003e08:	4b4080e7          	jalr	1204(ra) # 800032b8 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e0c:	04cba783          	lw	a5,76(s7)
    80003e10:	0127f463          	bgeu	a5,s2,80003e18 <writei+0xe2>
      ip->size = off;
    80003e14:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e18:	855e                	mv	a0,s7
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	aa8080e7          	jalr	-1368(ra) # 800038c2 <iupdate>
  }

  return n;
    80003e22:	000b051b          	sext.w	a0,s6
}
    80003e26:	70a6                	ld	ra,104(sp)
    80003e28:	7406                	ld	s0,96(sp)
    80003e2a:	64e6                	ld	s1,88(sp)
    80003e2c:	6946                	ld	s2,80(sp)
    80003e2e:	69a6                	ld	s3,72(sp)
    80003e30:	6a06                	ld	s4,64(sp)
    80003e32:	7ae2                	ld	s5,56(sp)
    80003e34:	7b42                	ld	s6,48(sp)
    80003e36:	7ba2                	ld	s7,40(sp)
    80003e38:	7c02                	ld	s8,32(sp)
    80003e3a:	6ce2                	ld	s9,24(sp)
    80003e3c:	6d42                	ld	s10,16(sp)
    80003e3e:	6da2                	ld	s11,8(sp)
    80003e40:	6165                	addi	sp,sp,112
    80003e42:	8082                	ret
    return -1;
    80003e44:	557d                	li	a0,-1
}
    80003e46:	8082                	ret
    return -1;
    80003e48:	557d                	li	a0,-1
    80003e4a:	bff1                	j	80003e26 <writei+0xf0>
    return -1;
    80003e4c:	557d                	li	a0,-1
    80003e4e:	bfe1                	j	80003e26 <writei+0xf0>

0000000080003e50 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e50:	1141                	addi	sp,sp,-16
    80003e52:	e406                	sd	ra,8(sp)
    80003e54:	e022                	sd	s0,0(sp)
    80003e56:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e58:	4639                	li	a2,14
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	f76080e7          	jalr	-138(ra) # 80000dd0 <strncmp>
}
    80003e62:	60a2                	ld	ra,8(sp)
    80003e64:	6402                	ld	s0,0(sp)
    80003e66:	0141                	addi	sp,sp,16
    80003e68:	8082                	ret

0000000080003e6a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e6a:	7139                	addi	sp,sp,-64
    80003e6c:	fc06                	sd	ra,56(sp)
    80003e6e:	f822                	sd	s0,48(sp)
    80003e70:	f426                	sd	s1,40(sp)
    80003e72:	f04a                	sd	s2,32(sp)
    80003e74:	ec4e                	sd	s3,24(sp)
    80003e76:	e852                	sd	s4,16(sp)
    80003e78:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e7a:	04451703          	lh	a4,68(a0)
    80003e7e:	4785                	li	a5,1
    80003e80:	00f71a63          	bne	a4,a5,80003e94 <dirlookup+0x2a>
    80003e84:	892a                	mv	s2,a0
    80003e86:	89ae                	mv	s3,a1
    80003e88:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8a:	457c                	lw	a5,76(a0)
    80003e8c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e8e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e90:	e79d                	bnez	a5,80003ebe <dirlookup+0x54>
    80003e92:	a8a5                	j	80003f0a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e94:	00004517          	auipc	a0,0x4
    80003e98:	7ac50513          	addi	a0,a0,1964 # 80008640 <syscalls+0x1a0>
    80003e9c:	ffffc097          	auipc	ra,0xffffc
    80003ea0:	6a4080e7          	jalr	1700(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ea4:	00004517          	auipc	a0,0x4
    80003ea8:	7b450513          	addi	a0,a0,1972 # 80008658 <syscalls+0x1b8>
    80003eac:	ffffc097          	auipc	ra,0xffffc
    80003eb0:	694080e7          	jalr	1684(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb4:	24c1                	addiw	s1,s1,16
    80003eb6:	04c92783          	lw	a5,76(s2)
    80003eba:	04f4f763          	bgeu	s1,a5,80003f08 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebe:	4741                	li	a4,16
    80003ec0:	86a6                	mv	a3,s1
    80003ec2:	fc040613          	addi	a2,s0,-64
    80003ec6:	4581                	li	a1,0
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	d76080e7          	jalr	-650(ra) # 80003c40 <readi>
    80003ed2:	47c1                	li	a5,16
    80003ed4:	fcf518e3          	bne	a0,a5,80003ea4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed8:	fc045783          	lhu	a5,-64(s0)
    80003edc:	dfe1                	beqz	a5,80003eb4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ede:	fc240593          	addi	a1,s0,-62
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	f6c080e7          	jalr	-148(ra) # 80003e50 <namecmp>
    80003eec:	f561                	bnez	a0,80003eb4 <dirlookup+0x4a>
      if(poff)
    80003eee:	000a0463          	beqz	s4,80003ef6 <dirlookup+0x8c>
        *poff = off;
    80003ef2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef6:	fc045583          	lhu	a1,-64(s0)
    80003efa:	00092503          	lw	a0,0(s2)
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	75a080e7          	jalr	1882(ra) # 80003658 <iget>
    80003f06:	a011                	j	80003f0a <dirlookup+0xa0>
  return 0;
    80003f08:	4501                	li	a0,0
}
    80003f0a:	70e2                	ld	ra,56(sp)
    80003f0c:	7442                	ld	s0,48(sp)
    80003f0e:	74a2                	ld	s1,40(sp)
    80003f10:	7902                	ld	s2,32(sp)
    80003f12:	69e2                	ld	s3,24(sp)
    80003f14:	6a42                	ld	s4,16(sp)
    80003f16:	6121                	addi	sp,sp,64
    80003f18:	8082                	ret

0000000080003f1a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f1a:	711d                	addi	sp,sp,-96
    80003f1c:	ec86                	sd	ra,88(sp)
    80003f1e:	e8a2                	sd	s0,80(sp)
    80003f20:	e4a6                	sd	s1,72(sp)
    80003f22:	e0ca                	sd	s2,64(sp)
    80003f24:	fc4e                	sd	s3,56(sp)
    80003f26:	f852                	sd	s4,48(sp)
    80003f28:	f456                	sd	s5,40(sp)
    80003f2a:	f05a                	sd	s6,32(sp)
    80003f2c:	ec5e                	sd	s7,24(sp)
    80003f2e:	e862                	sd	s8,16(sp)
    80003f30:	e466                	sd	s9,8(sp)
    80003f32:	1080                	addi	s0,sp,96
    80003f34:	84aa                	mv	s1,a0
    80003f36:	8aae                	mv	s5,a1
    80003f38:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f3a:	00054703          	lbu	a4,0(a0)
    80003f3e:	02f00793          	li	a5,47
    80003f42:	02f70363          	beq	a4,a5,80003f68 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f46:	ffffe097          	auipc	ra,0xffffe
    80003f4a:	bf0080e7          	jalr	-1040(ra) # 80001b36 <myproc>
    80003f4e:	15053503          	ld	a0,336(a0)
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	9fc080e7          	jalr	-1540(ra) # 8000394e <idup>
    80003f5a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f5c:	02f00913          	li	s2,47
  len = path - s;
    80003f60:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f62:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f64:	4b85                	li	s7,1
    80003f66:	a865                	j	8000401e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f68:	4585                	li	a1,1
    80003f6a:	4505                	li	a0,1
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	6ec080e7          	jalr	1772(ra) # 80003658 <iget>
    80003f74:	89aa                	mv	s3,a0
    80003f76:	b7dd                	j	80003f5c <namex+0x42>
      iunlockput(ip);
    80003f78:	854e                	mv	a0,s3
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	c74080e7          	jalr	-908(ra) # 80003bee <iunlockput>
      return 0;
    80003f82:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f84:	854e                	mv	a0,s3
    80003f86:	60e6                	ld	ra,88(sp)
    80003f88:	6446                	ld	s0,80(sp)
    80003f8a:	64a6                	ld	s1,72(sp)
    80003f8c:	6906                	ld	s2,64(sp)
    80003f8e:	79e2                	ld	s3,56(sp)
    80003f90:	7a42                	ld	s4,48(sp)
    80003f92:	7aa2                	ld	s5,40(sp)
    80003f94:	7b02                	ld	s6,32(sp)
    80003f96:	6be2                	ld	s7,24(sp)
    80003f98:	6c42                	ld	s8,16(sp)
    80003f9a:	6ca2                	ld	s9,8(sp)
    80003f9c:	6125                	addi	sp,sp,96
    80003f9e:	8082                	ret
      iunlock(ip);
    80003fa0:	854e                	mv	a0,s3
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	aac080e7          	jalr	-1364(ra) # 80003a4e <iunlock>
      return ip;
    80003faa:	bfe9                	j	80003f84 <namex+0x6a>
      iunlockput(ip);
    80003fac:	854e                	mv	a0,s3
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	c40080e7          	jalr	-960(ra) # 80003bee <iunlockput>
      return 0;
    80003fb6:	89e6                	mv	s3,s9
    80003fb8:	b7f1                	j	80003f84 <namex+0x6a>
  len = path - s;
    80003fba:	40b48633          	sub	a2,s1,a1
    80003fbe:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fc2:	099c5463          	bge	s8,s9,8000404a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc6:	4639                	li	a2,14
    80003fc8:	8552                	mv	a0,s4
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	d8a080e7          	jalr	-630(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003fd2:	0004c783          	lbu	a5,0(s1)
    80003fd6:	01279763          	bne	a5,s2,80003fe4 <namex+0xca>
    path++;
    80003fda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fdc:	0004c783          	lbu	a5,0(s1)
    80003fe0:	ff278de3          	beq	a5,s2,80003fda <namex+0xc0>
    ilock(ip);
    80003fe4:	854e                	mv	a0,s3
    80003fe6:	00000097          	auipc	ra,0x0
    80003fea:	9a6080e7          	jalr	-1626(ra) # 8000398c <ilock>
    if(ip->type != T_DIR){
    80003fee:	04499783          	lh	a5,68(s3)
    80003ff2:	f97793e3          	bne	a5,s7,80003f78 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff6:	000a8563          	beqz	s5,80004000 <namex+0xe6>
    80003ffa:	0004c783          	lbu	a5,0(s1)
    80003ffe:	d3cd                	beqz	a5,80003fa0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004000:	865a                	mv	a2,s6
    80004002:	85d2                	mv	a1,s4
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	e64080e7          	jalr	-412(ra) # 80003e6a <dirlookup>
    8000400e:	8caa                	mv	s9,a0
    80004010:	dd51                	beqz	a0,80003fac <namex+0x92>
    iunlockput(ip);
    80004012:	854e                	mv	a0,s3
    80004014:	00000097          	auipc	ra,0x0
    80004018:	bda080e7          	jalr	-1062(ra) # 80003bee <iunlockput>
    ip = next;
    8000401c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000401e:	0004c783          	lbu	a5,0(s1)
    80004022:	05279763          	bne	a5,s2,80004070 <namex+0x156>
    path++;
    80004026:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004028:	0004c783          	lbu	a5,0(s1)
    8000402c:	ff278de3          	beq	a5,s2,80004026 <namex+0x10c>
  if(*path == 0)
    80004030:	c79d                	beqz	a5,8000405e <namex+0x144>
    path++;
    80004032:	85a6                	mv	a1,s1
  len = path - s;
    80004034:	8cda                	mv	s9,s6
    80004036:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004038:	01278963          	beq	a5,s2,8000404a <namex+0x130>
    8000403c:	dfbd                	beqz	a5,80003fba <namex+0xa0>
    path++;
    8000403e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004040:	0004c783          	lbu	a5,0(s1)
    80004044:	ff279ce3          	bne	a5,s2,8000403c <namex+0x122>
    80004048:	bf8d                	j	80003fba <namex+0xa0>
    memmove(name, s, len);
    8000404a:	2601                	sext.w	a2,a2
    8000404c:	8552                	mv	a0,s4
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	d06080e7          	jalr	-762(ra) # 80000d54 <memmove>
    name[len] = 0;
    80004056:	9cd2                	add	s9,s9,s4
    80004058:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000405c:	bf9d                	j	80003fd2 <namex+0xb8>
  if(nameiparent){
    8000405e:	f20a83e3          	beqz	s5,80003f84 <namex+0x6a>
    iput(ip);
    80004062:	854e                	mv	a0,s3
    80004064:	00000097          	auipc	ra,0x0
    80004068:	ae2080e7          	jalr	-1310(ra) # 80003b46 <iput>
    return 0;
    8000406c:	4981                	li	s3,0
    8000406e:	bf19                	j	80003f84 <namex+0x6a>
  if(*path == 0)
    80004070:	d7fd                	beqz	a5,8000405e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004072:	0004c783          	lbu	a5,0(s1)
    80004076:	85a6                	mv	a1,s1
    80004078:	b7d1                	j	8000403c <namex+0x122>

000000008000407a <dirlink>:
{
    8000407a:	7139                	addi	sp,sp,-64
    8000407c:	fc06                	sd	ra,56(sp)
    8000407e:	f822                	sd	s0,48(sp)
    80004080:	f426                	sd	s1,40(sp)
    80004082:	f04a                	sd	s2,32(sp)
    80004084:	ec4e                	sd	s3,24(sp)
    80004086:	e852                	sd	s4,16(sp)
    80004088:	0080                	addi	s0,sp,64
    8000408a:	892a                	mv	s2,a0
    8000408c:	8a2e                	mv	s4,a1
    8000408e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004090:	4601                	li	a2,0
    80004092:	00000097          	auipc	ra,0x0
    80004096:	dd8080e7          	jalr	-552(ra) # 80003e6a <dirlookup>
    8000409a:	e93d                	bnez	a0,80004110 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409c:	04c92483          	lw	s1,76(s2)
    800040a0:	c49d                	beqz	s1,800040ce <dirlink+0x54>
    800040a2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a4:	4741                	li	a4,16
    800040a6:	86a6                	mv	a3,s1
    800040a8:	fc040613          	addi	a2,s0,-64
    800040ac:	4581                	li	a1,0
    800040ae:	854a                	mv	a0,s2
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	b90080e7          	jalr	-1136(ra) # 80003c40 <readi>
    800040b8:	47c1                	li	a5,16
    800040ba:	06f51163          	bne	a0,a5,8000411c <dirlink+0xa2>
    if(de.inum == 0)
    800040be:	fc045783          	lhu	a5,-64(s0)
    800040c2:	c791                	beqz	a5,800040ce <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c4:	24c1                	addiw	s1,s1,16
    800040c6:	04c92783          	lw	a5,76(s2)
    800040ca:	fcf4ede3          	bltu	s1,a5,800040a4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ce:	4639                	li	a2,14
    800040d0:	85d2                	mv	a1,s4
    800040d2:	fc240513          	addi	a0,s0,-62
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	d36080e7          	jalr	-714(ra) # 80000e0c <strncpy>
  de.inum = inum;
    800040de:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e2:	4741                	li	a4,16
    800040e4:	86a6                	mv	a3,s1
    800040e6:	fc040613          	addi	a2,s0,-64
    800040ea:	4581                	li	a1,0
    800040ec:	854a                	mv	a0,s2
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	c48080e7          	jalr	-952(ra) # 80003d36 <writei>
    800040f6:	872a                	mv	a4,a0
    800040f8:	47c1                	li	a5,16
  return 0;
    800040fa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040fc:	02f71863          	bne	a4,a5,8000412c <dirlink+0xb2>
}
    80004100:	70e2                	ld	ra,56(sp)
    80004102:	7442                	ld	s0,48(sp)
    80004104:	74a2                	ld	s1,40(sp)
    80004106:	7902                	ld	s2,32(sp)
    80004108:	69e2                	ld	s3,24(sp)
    8000410a:	6a42                	ld	s4,16(sp)
    8000410c:	6121                	addi	sp,sp,64
    8000410e:	8082                	ret
    iput(ip);
    80004110:	00000097          	auipc	ra,0x0
    80004114:	a36080e7          	jalr	-1482(ra) # 80003b46 <iput>
    return -1;
    80004118:	557d                	li	a0,-1
    8000411a:	b7dd                	j	80004100 <dirlink+0x86>
      panic("dirlink read");
    8000411c:	00004517          	auipc	a0,0x4
    80004120:	54c50513          	addi	a0,a0,1356 # 80008668 <syscalls+0x1c8>
    80004124:	ffffc097          	auipc	ra,0xffffc
    80004128:	41c080e7          	jalr	1052(ra) # 80000540 <panic>
    panic("dirlink");
    8000412c:	00004517          	auipc	a0,0x4
    80004130:	65c50513          	addi	a0,a0,1628 # 80008788 <syscalls+0x2e8>
    80004134:	ffffc097          	auipc	ra,0xffffc
    80004138:	40c080e7          	jalr	1036(ra) # 80000540 <panic>

000000008000413c <namei>:

struct inode*
namei(char *path)
{
    8000413c:	1101                	addi	sp,sp,-32
    8000413e:	ec06                	sd	ra,24(sp)
    80004140:	e822                	sd	s0,16(sp)
    80004142:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004144:	fe040613          	addi	a2,s0,-32
    80004148:	4581                	li	a1,0
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	dd0080e7          	jalr	-560(ra) # 80003f1a <namex>
}
    80004152:	60e2                	ld	ra,24(sp)
    80004154:	6442                	ld	s0,16(sp)
    80004156:	6105                	addi	sp,sp,32
    80004158:	8082                	ret

000000008000415a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000415a:	1141                	addi	sp,sp,-16
    8000415c:	e406                	sd	ra,8(sp)
    8000415e:	e022                	sd	s0,0(sp)
    80004160:	0800                	addi	s0,sp,16
    80004162:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004164:	4585                	li	a1,1
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	db4080e7          	jalr	-588(ra) # 80003f1a <namex>
}
    8000416e:	60a2                	ld	ra,8(sp)
    80004170:	6402                	ld	s0,0(sp)
    80004172:	0141                	addi	sp,sp,16
    80004174:	8082                	ret

0000000080004176 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004176:	1101                	addi	sp,sp,-32
    80004178:	ec06                	sd	ra,24(sp)
    8000417a:	e822                	sd	s0,16(sp)
    8000417c:	e426                	sd	s1,8(sp)
    8000417e:	e04a                	sd	s2,0(sp)
    80004180:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004182:	0001e917          	auipc	s2,0x1e
    80004186:	38690913          	addi	s2,s2,902 # 80022508 <log>
    8000418a:	01892583          	lw	a1,24(s2)
    8000418e:	02892503          	lw	a0,40(s2)
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	ff6080e7          	jalr	-10(ra) # 80003188 <bread>
    8000419a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000419c:	02c92683          	lw	a3,44(s2)
    800041a0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041a2:	02d05863          	blez	a3,800041d2 <write_head+0x5c>
    800041a6:	0001e797          	auipc	a5,0x1e
    800041aa:	39278793          	addi	a5,a5,914 # 80022538 <log+0x30>
    800041ae:	05c50713          	addi	a4,a0,92
    800041b2:	36fd                	addiw	a3,a3,-1
    800041b4:	02069613          	slli	a2,a3,0x20
    800041b8:	01e65693          	srli	a3,a2,0x1e
    800041bc:	0001e617          	auipc	a2,0x1e
    800041c0:	38060613          	addi	a2,a2,896 # 8002253c <log+0x34>
    800041c4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041c6:	4390                	lw	a2,0(a5)
    800041c8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ca:	0791                	addi	a5,a5,4
    800041cc:	0711                	addi	a4,a4,4
    800041ce:	fed79ce3          	bne	a5,a3,800041c6 <write_head+0x50>
  }
  bwrite(buf);
    800041d2:	8526                	mv	a0,s1
    800041d4:	fffff097          	auipc	ra,0xfffff
    800041d8:	0a6080e7          	jalr	166(ra) # 8000327a <bwrite>
  brelse(buf);
    800041dc:	8526                	mv	a0,s1
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	0da080e7          	jalr	218(ra) # 800032b8 <brelse>
}
    800041e6:	60e2                	ld	ra,24(sp)
    800041e8:	6442                	ld	s0,16(sp)
    800041ea:	64a2                	ld	s1,8(sp)
    800041ec:	6902                	ld	s2,0(sp)
    800041ee:	6105                	addi	sp,sp,32
    800041f0:	8082                	ret

00000000800041f2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041f2:	0001e797          	auipc	a5,0x1e
    800041f6:	3427a783          	lw	a5,834(a5) # 80022534 <log+0x2c>
    800041fa:	0af05663          	blez	a5,800042a6 <install_trans+0xb4>
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	e456                	sd	s5,8(sp)
    8000420e:	0080                	addi	s0,sp,64
    80004210:	0001ea97          	auipc	s5,0x1e
    80004214:	328a8a93          	addi	s5,s5,808 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004218:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000421a:	0001e997          	auipc	s3,0x1e
    8000421e:	2ee98993          	addi	s3,s3,750 # 80022508 <log>
    80004222:	0189a583          	lw	a1,24(s3)
    80004226:	014585bb          	addw	a1,a1,s4
    8000422a:	2585                	addiw	a1,a1,1
    8000422c:	0289a503          	lw	a0,40(s3)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	f58080e7          	jalr	-168(ra) # 80003188 <bread>
    80004238:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000423a:	000aa583          	lw	a1,0(s5)
    8000423e:	0289a503          	lw	a0,40(s3)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	f46080e7          	jalr	-186(ra) # 80003188 <bread>
    8000424a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000424c:	40000613          	li	a2,1024
    80004250:	05890593          	addi	a1,s2,88
    80004254:	05850513          	addi	a0,a0,88
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	afc080e7          	jalr	-1284(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004260:	8526                	mv	a0,s1
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	018080e7          	jalr	24(ra) # 8000327a <bwrite>
    bunpin(dbuf);
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	126080e7          	jalr	294(ra) # 80003392 <bunpin>
    brelse(lbuf);
    80004274:	854a                	mv	a0,s2
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	042080e7          	jalr	66(ra) # 800032b8 <brelse>
    brelse(dbuf);
    8000427e:	8526                	mv	a0,s1
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	038080e7          	jalr	56(ra) # 800032b8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004288:	2a05                	addiw	s4,s4,1
    8000428a:	0a91                	addi	s5,s5,4
    8000428c:	02c9a783          	lw	a5,44(s3)
    80004290:	f8fa49e3          	blt	s4,a5,80004222 <install_trans+0x30>
}
    80004294:	70e2                	ld	ra,56(sp)
    80004296:	7442                	ld	s0,48(sp)
    80004298:	74a2                	ld	s1,40(sp)
    8000429a:	7902                	ld	s2,32(sp)
    8000429c:	69e2                	ld	s3,24(sp)
    8000429e:	6a42                	ld	s4,16(sp)
    800042a0:	6aa2                	ld	s5,8(sp)
    800042a2:	6121                	addi	sp,sp,64
    800042a4:	8082                	ret
    800042a6:	8082                	ret

00000000800042a8 <initlog>:
{
    800042a8:	7179                	addi	sp,sp,-48
    800042aa:	f406                	sd	ra,40(sp)
    800042ac:	f022                	sd	s0,32(sp)
    800042ae:	ec26                	sd	s1,24(sp)
    800042b0:	e84a                	sd	s2,16(sp)
    800042b2:	e44e                	sd	s3,8(sp)
    800042b4:	1800                	addi	s0,sp,48
    800042b6:	892a                	mv	s2,a0
    800042b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ba:	0001e497          	auipc	s1,0x1e
    800042be:	24e48493          	addi	s1,s1,590 # 80022508 <log>
    800042c2:	00004597          	auipc	a1,0x4
    800042c6:	3b658593          	addi	a1,a1,950 # 80008678 <syscalls+0x1d8>
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	8a0080e7          	jalr	-1888(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800042d4:	0149a583          	lw	a1,20(s3)
    800042d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042da:	0109a783          	lw	a5,16(s3)
    800042de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042e4:	854a                	mv	a0,s2
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	ea2080e7          	jalr	-350(ra) # 80003188 <bread>
  log.lh.n = lh->n;
    800042ee:	4d34                	lw	a3,88(a0)
    800042f0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042f2:	02d05663          	blez	a3,8000431e <initlog+0x76>
    800042f6:	05c50793          	addi	a5,a0,92
    800042fa:	0001e717          	auipc	a4,0x1e
    800042fe:	23e70713          	addi	a4,a4,574 # 80022538 <log+0x30>
    80004302:	36fd                	addiw	a3,a3,-1
    80004304:	02069613          	slli	a2,a3,0x20
    80004308:	01e65693          	srli	a3,a2,0x1e
    8000430c:	06050613          	addi	a2,a0,96
    80004310:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004312:	4390                	lw	a2,0(a5)
    80004314:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004316:	0791                	addi	a5,a5,4
    80004318:	0711                	addi	a4,a4,4
    8000431a:	fed79ce3          	bne	a5,a3,80004312 <initlog+0x6a>
  brelse(buf);
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	f9a080e7          	jalr	-102(ra) # 800032b8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	ecc080e7          	jalr	-308(ra) # 800041f2 <install_trans>
  log.lh.n = 0;
    8000432e:	0001e797          	auipc	a5,0x1e
    80004332:	2007a323          	sw	zero,518(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	e40080e7          	jalr	-448(ra) # 80004176 <write_head>
}
    8000433e:	70a2                	ld	ra,40(sp)
    80004340:	7402                	ld	s0,32(sp)
    80004342:	64e2                	ld	s1,24(sp)
    80004344:	6942                	ld	s2,16(sp)
    80004346:	69a2                	ld	s3,8(sp)
    80004348:	6145                	addi	sp,sp,48
    8000434a:	8082                	ret

000000008000434c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004358:	0001e517          	auipc	a0,0x1e
    8000435c:	1b050513          	addi	a0,a0,432 # 80022508 <log>
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	89c080e7          	jalr	-1892(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004368:	0001e497          	auipc	s1,0x1e
    8000436c:	1a048493          	addi	s1,s1,416 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004370:	4979                	li	s2,30
    80004372:	a039                	j	80004380 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004374:	85a6                	mv	a1,s1
    80004376:	8526                	mv	a0,s1
    80004378:	ffffe097          	auipc	ra,0xffffe
    8000437c:	156080e7          	jalr	342(ra) # 800024ce <sleep>
    if(log.committing){
    80004380:	50dc                	lw	a5,36(s1)
    80004382:	fbed                	bnez	a5,80004374 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004384:	509c                	lw	a5,32(s1)
    80004386:	0017871b          	addiw	a4,a5,1
    8000438a:	0007069b          	sext.w	a3,a4
    8000438e:	0027179b          	slliw	a5,a4,0x2
    80004392:	9fb9                	addw	a5,a5,a4
    80004394:	0017979b          	slliw	a5,a5,0x1
    80004398:	54d8                	lw	a4,44(s1)
    8000439a:	9fb9                	addw	a5,a5,a4
    8000439c:	00f95963          	bge	s2,a5,800043ae <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a0:	85a6                	mv	a1,s1
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffe097          	auipc	ra,0xffffe
    800043a8:	12a080e7          	jalr	298(ra) # 800024ce <sleep>
    800043ac:	bfd1                	j	80004380 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043ae:	0001e517          	auipc	a0,0x1e
    800043b2:	15a50513          	addi	a0,a0,346 # 80022508 <log>
    800043b6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8f8080e7          	jalr	-1800(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6902                	ld	s2,0(sp)
    800043c8:	6105                	addi	sp,sp,32
    800043ca:	8082                	ret

00000000800043cc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043cc:	7139                	addi	sp,sp,-64
    800043ce:	fc06                	sd	ra,56(sp)
    800043d0:	f822                	sd	s0,48(sp)
    800043d2:	f426                	sd	s1,40(sp)
    800043d4:	f04a                	sd	s2,32(sp)
    800043d6:	ec4e                	sd	s3,24(sp)
    800043d8:	e852                	sd	s4,16(sp)
    800043da:	e456                	sd	s5,8(sp)
    800043dc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043de:	0001e497          	auipc	s1,0x1e
    800043e2:	12a48493          	addi	s1,s1,298 # 80022508 <log>
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	814080e7          	jalr	-2028(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800043f0:	509c                	lw	a5,32(s1)
    800043f2:	37fd                	addiw	a5,a5,-1
    800043f4:	0007891b          	sext.w	s2,a5
    800043f8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043fa:	50dc                	lw	a5,36(s1)
    800043fc:	e7b9                	bnez	a5,8000444a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043fe:	04091e63          	bnez	s2,8000445a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004402:	0001e497          	auipc	s1,0x1e
    80004406:	10648493          	addi	s1,s1,262 # 80022508 <log>
    8000440a:	4785                	li	a5,1
    8000440c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	8a0080e7          	jalr	-1888(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004418:	54dc                	lw	a5,44(s1)
    8000441a:	06f04763          	bgtz	a5,80004488 <end_op+0xbc>
    acquire(&log.lock);
    8000441e:	0001e497          	auipc	s1,0x1e
    80004422:	0ea48493          	addi	s1,s1,234 # 80022508 <log>
    80004426:	8526                	mv	a0,s1
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	7d4080e7          	jalr	2004(ra) # 80000bfc <acquire>
    log.committing = 0;
    80004430:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	256080e7          	jalr	598(ra) # 8000268c <wakeup>
    release(&log.lock);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	870080e7          	jalr	-1936(ra) # 80000cb0 <release>
}
    80004448:	a03d                	j	80004476 <end_op+0xaa>
    panic("log.committing");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	23650513          	addi	a0,a0,566 # 80008680 <syscalls+0x1e0>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0ee080e7          	jalr	238(ra) # 80000540 <panic>
    wakeup(&log);
    8000445a:	0001e497          	auipc	s1,0x1e
    8000445e:	0ae48493          	addi	s1,s1,174 # 80022508 <log>
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	228080e7          	jalr	552(ra) # 8000268c <wakeup>
  release(&log.lock);
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	842080e7          	jalr	-1982(ra) # 80000cb0 <release>
}
    80004476:	70e2                	ld	ra,56(sp)
    80004478:	7442                	ld	s0,48(sp)
    8000447a:	74a2                	ld	s1,40(sp)
    8000447c:	7902                	ld	s2,32(sp)
    8000447e:	69e2                	ld	s3,24(sp)
    80004480:	6a42                	ld	s4,16(sp)
    80004482:	6aa2                	ld	s5,8(sp)
    80004484:	6121                	addi	sp,sp,64
    80004486:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004488:	0001ea97          	auipc	s5,0x1e
    8000448c:	0b0a8a93          	addi	s5,s5,176 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004490:	0001ea17          	auipc	s4,0x1e
    80004494:	078a0a13          	addi	s4,s4,120 # 80022508 <log>
    80004498:	018a2583          	lw	a1,24(s4)
    8000449c:	012585bb          	addw	a1,a1,s2
    800044a0:	2585                	addiw	a1,a1,1
    800044a2:	028a2503          	lw	a0,40(s4)
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	ce2080e7          	jalr	-798(ra) # 80003188 <bread>
    800044ae:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044b0:	000aa583          	lw	a1,0(s5)
    800044b4:	028a2503          	lw	a0,40(s4)
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	cd0080e7          	jalr	-816(ra) # 80003188 <bread>
    800044c0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044c2:	40000613          	li	a2,1024
    800044c6:	05850593          	addi	a1,a0,88
    800044ca:	05848513          	addi	a0,s1,88
    800044ce:	ffffd097          	auipc	ra,0xffffd
    800044d2:	886080e7          	jalr	-1914(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800044d6:	8526                	mv	a0,s1
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	da2080e7          	jalr	-606(ra) # 8000327a <bwrite>
    brelse(from);
    800044e0:	854e                	mv	a0,s3
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	dd6080e7          	jalr	-554(ra) # 800032b8 <brelse>
    brelse(to);
    800044ea:	8526                	mv	a0,s1
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	dcc080e7          	jalr	-564(ra) # 800032b8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f4:	2905                	addiw	s2,s2,1
    800044f6:	0a91                	addi	s5,s5,4
    800044f8:	02ca2783          	lw	a5,44(s4)
    800044fc:	f8f94ee3          	blt	s2,a5,80004498 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004500:	00000097          	auipc	ra,0x0
    80004504:	c76080e7          	jalr	-906(ra) # 80004176 <write_head>
    install_trans(); // Now install writes to home locations
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	cea080e7          	jalr	-790(ra) # 800041f2 <install_trans>
    log.lh.n = 0;
    80004510:	0001e797          	auipc	a5,0x1e
    80004514:	0207a223          	sw	zero,36(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004518:	00000097          	auipc	ra,0x0
    8000451c:	c5e080e7          	jalr	-930(ra) # 80004176 <write_head>
    80004520:	bdfd                	j	8000441e <end_op+0x52>

0000000080004522 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	e04a                	sd	s2,0(sp)
    8000452c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000452e:	0001e717          	auipc	a4,0x1e
    80004532:	00672703          	lw	a4,6(a4) # 80022534 <log+0x2c>
    80004536:	47f5                	li	a5,29
    80004538:	08e7c063          	blt	a5,a4,800045b8 <log_write+0x96>
    8000453c:	84aa                	mv	s1,a0
    8000453e:	0001e797          	auipc	a5,0x1e
    80004542:	fe67a783          	lw	a5,-26(a5) # 80022524 <log+0x1c>
    80004546:	37fd                	addiw	a5,a5,-1
    80004548:	06f75863          	bge	a4,a5,800045b8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000454c:	0001e797          	auipc	a5,0x1e
    80004550:	fdc7a783          	lw	a5,-36(a5) # 80022528 <log+0x20>
    80004554:	06f05a63          	blez	a5,800045c8 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004558:	0001e917          	auipc	s2,0x1e
    8000455c:	fb090913          	addi	s2,s2,-80 # 80022508 <log>
    80004560:	854a                	mv	a0,s2
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	69a080e7          	jalr	1690(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	02c92603          	lw	a2,44(s2)
    8000456e:	06c05563          	blez	a2,800045d8 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004572:	44cc                	lw	a1,12(s1)
    80004574:	0001e717          	auipc	a4,0x1e
    80004578:	fc470713          	addi	a4,a4,-60 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000457c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000457e:	4314                	lw	a3,0(a4)
    80004580:	04b68d63          	beq	a3,a1,800045da <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004584:	2785                	addiw	a5,a5,1
    80004586:	0711                	addi	a4,a4,4
    80004588:	fec79be3          	bne	a5,a2,8000457e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000458c:	0621                	addi	a2,a2,8
    8000458e:	060a                	slli	a2,a2,0x2
    80004590:	0001e797          	auipc	a5,0x1e
    80004594:	f7878793          	addi	a5,a5,-136 # 80022508 <log>
    80004598:	963e                	add	a2,a2,a5
    8000459a:	44dc                	lw	a5,12(s1)
    8000459c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000459e:	8526                	mv	a0,s1
    800045a0:	fffff097          	auipc	ra,0xfffff
    800045a4:	db6080e7          	jalr	-586(ra) # 80003356 <bpin>
    log.lh.n++;
    800045a8:	0001e717          	auipc	a4,0x1e
    800045ac:	f6070713          	addi	a4,a4,-160 # 80022508 <log>
    800045b0:	575c                	lw	a5,44(a4)
    800045b2:	2785                	addiw	a5,a5,1
    800045b4:	d75c                	sw	a5,44(a4)
    800045b6:	a83d                	j	800045f4 <log_write+0xd2>
    panic("too big a transaction");
    800045b8:	00004517          	auipc	a0,0x4
    800045bc:	0d850513          	addi	a0,a0,216 # 80008690 <syscalls+0x1f0>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	f80080e7          	jalr	-128(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	0e050513          	addi	a0,a0,224 # 800086a8 <syscalls+0x208>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f70080e7          	jalr	-144(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d8:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045da:	00878713          	addi	a4,a5,8
    800045de:	00271693          	slli	a3,a4,0x2
    800045e2:	0001e717          	auipc	a4,0x1e
    800045e6:	f2670713          	addi	a4,a4,-218 # 80022508 <log>
    800045ea:	9736                	add	a4,a4,a3
    800045ec:	44d4                	lw	a3,12(s1)
    800045ee:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045f0:	faf607e3          	beq	a2,a5,8000459e <log_write+0x7c>
  }
  release(&log.lock);
    800045f4:	0001e517          	auipc	a0,0x1e
    800045f8:	f1450513          	addi	a0,a0,-236 # 80022508 <log>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	6b4080e7          	jalr	1716(ra) # 80000cb0 <release>
}
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6902                	ld	s2,0(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret

0000000080004610 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004610:	1101                	addi	sp,sp,-32
    80004612:	ec06                	sd	ra,24(sp)
    80004614:	e822                	sd	s0,16(sp)
    80004616:	e426                	sd	s1,8(sp)
    80004618:	e04a                	sd	s2,0(sp)
    8000461a:	1000                	addi	s0,sp,32
    8000461c:	84aa                	mv	s1,a0
    8000461e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004620:	00004597          	auipc	a1,0x4
    80004624:	0a858593          	addi	a1,a1,168 # 800086c8 <syscalls+0x228>
    80004628:	0521                	addi	a0,a0,8
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	542080e7          	jalr	1346(ra) # 80000b6c <initlock>
  lk->name = name;
    80004632:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004636:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463a:	0204a423          	sw	zero,40(s1)
}
    8000463e:	60e2                	ld	ra,24(sp)
    80004640:	6442                	ld	s0,16(sp)
    80004642:	64a2                	ld	s1,8(sp)
    80004644:	6902                	ld	s2,0(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret

000000008000464a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000464a:	1101                	addi	sp,sp,-32
    8000464c:	ec06                	sd	ra,24(sp)
    8000464e:	e822                	sd	s0,16(sp)
    80004650:	e426                	sd	s1,8(sp)
    80004652:	e04a                	sd	s2,0(sp)
    80004654:	1000                	addi	s0,sp,32
    80004656:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004658:	00850913          	addi	s2,a0,8
    8000465c:	854a                	mv	a0,s2
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	59e080e7          	jalr	1438(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004666:	409c                	lw	a5,0(s1)
    80004668:	cb89                	beqz	a5,8000467a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000466a:	85ca                	mv	a1,s2
    8000466c:	8526                	mv	a0,s1
    8000466e:	ffffe097          	auipc	ra,0xffffe
    80004672:	e60080e7          	jalr	-416(ra) # 800024ce <sleep>
  while (lk->locked) {
    80004676:	409c                	lw	a5,0(s1)
    80004678:	fbed                	bnez	a5,8000466a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000467a:	4785                	li	a5,1
    8000467c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000467e:	ffffd097          	auipc	ra,0xffffd
    80004682:	4b8080e7          	jalr	1208(ra) # 80001b36 <myproc>
    80004686:	5d1c                	lw	a5,56(a0)
    80004688:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	624080e7          	jalr	1572(ra) # 80000cb0 <release>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
    800046ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046ae:	00850913          	addi	s2,a0,8
    800046b2:	854a                	mv	a0,s2
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	548080e7          	jalr	1352(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800046bc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046c0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046c4:	8526                	mv	a0,s1
    800046c6:	ffffe097          	auipc	ra,0xffffe
    800046ca:	fc6080e7          	jalr	-58(ra) # 8000268c <wakeup>
  release(&lk->lk);
    800046ce:	854a                	mv	a0,s2
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5e0080e7          	jalr	1504(ra) # 80000cb0 <release>
}
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6902                	ld	s2,0(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e4:	7179                	addi	sp,sp,-48
    800046e6:	f406                	sd	ra,40(sp)
    800046e8:	f022                	sd	s0,32(sp)
    800046ea:	ec26                	sd	s1,24(sp)
    800046ec:	e84a                	sd	s2,16(sp)
    800046ee:	e44e                	sd	s3,8(sp)
    800046f0:	1800                	addi	s0,sp,48
    800046f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f4:	00850913          	addi	s2,a0,8
    800046f8:	854a                	mv	a0,s2
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	502080e7          	jalr	1282(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004702:	409c                	lw	a5,0(s1)
    80004704:	ef99                	bnez	a5,80004722 <holdingsleep+0x3e>
    80004706:	4481                	li	s1,0
  release(&lk->lk);
    80004708:	854a                	mv	a0,s2
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	5a6080e7          	jalr	1446(ra) # 80000cb0 <release>
  return r;
}
    80004712:	8526                	mv	a0,s1
    80004714:	70a2                	ld	ra,40(sp)
    80004716:	7402                	ld	s0,32(sp)
    80004718:	64e2                	ld	s1,24(sp)
    8000471a:	6942                	ld	s2,16(sp)
    8000471c:	69a2                	ld	s3,8(sp)
    8000471e:	6145                	addi	sp,sp,48
    80004720:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004722:	0284a983          	lw	s3,40(s1)
    80004726:	ffffd097          	auipc	ra,0xffffd
    8000472a:	410080e7          	jalr	1040(ra) # 80001b36 <myproc>
    8000472e:	5d04                	lw	s1,56(a0)
    80004730:	413484b3          	sub	s1,s1,s3
    80004734:	0014b493          	seqz	s1,s1
    80004738:	bfc1                	j	80004708 <holdingsleep+0x24>

000000008000473a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000473a:	1141                	addi	sp,sp,-16
    8000473c:	e406                	sd	ra,8(sp)
    8000473e:	e022                	sd	s0,0(sp)
    80004740:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004742:	00004597          	auipc	a1,0x4
    80004746:	f9658593          	addi	a1,a1,-106 # 800086d8 <syscalls+0x238>
    8000474a:	0001e517          	auipc	a0,0x1e
    8000474e:	f0650513          	addi	a0,a0,-250 # 80022650 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	41a080e7          	jalr	1050(ra) # 80000b6c <initlock>
}
    8000475a:	60a2                	ld	ra,8(sp)
    8000475c:	6402                	ld	s0,0(sp)
    8000475e:	0141                	addi	sp,sp,16
    80004760:	8082                	ret

0000000080004762 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004762:	1101                	addi	sp,sp,-32
    80004764:	ec06                	sd	ra,24(sp)
    80004766:	e822                	sd	s0,16(sp)
    80004768:	e426                	sd	s1,8(sp)
    8000476a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000476c:	0001e517          	auipc	a0,0x1e
    80004770:	ee450513          	addi	a0,a0,-284 # 80022650 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	488080e7          	jalr	1160(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477c:	0001e497          	auipc	s1,0x1e
    80004780:	eec48493          	addi	s1,s1,-276 # 80022668 <ftable+0x18>
    80004784:	0001f717          	auipc	a4,0x1f
    80004788:	e8470713          	addi	a4,a4,-380 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    8000478c:	40dc                	lw	a5,4(s1)
    8000478e:	cf99                	beqz	a5,800047ac <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004790:	02848493          	addi	s1,s1,40
    80004794:	fee49ce3          	bne	s1,a4,8000478c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004798:	0001e517          	auipc	a0,0x1e
    8000479c:	eb850513          	addi	a0,a0,-328 # 80022650 <ftable>
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	510080e7          	jalr	1296(ra) # 80000cb0 <release>
  return 0;
    800047a8:	4481                	li	s1,0
    800047aa:	a819                	j	800047c0 <filealloc+0x5e>
      f->ref = 1;
    800047ac:	4785                	li	a5,1
    800047ae:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047b0:	0001e517          	auipc	a0,0x1e
    800047b4:	ea050513          	addi	a0,a0,-352 # 80022650 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4f8080e7          	jalr	1272(ra) # 80000cb0 <release>
}
    800047c0:	8526                	mv	a0,s1
    800047c2:	60e2                	ld	ra,24(sp)
    800047c4:	6442                	ld	s0,16(sp)
    800047c6:	64a2                	ld	s1,8(sp)
    800047c8:	6105                	addi	sp,sp,32
    800047ca:	8082                	ret

00000000800047cc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	1000                	addi	s0,sp,32
    800047d6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d8:	0001e517          	auipc	a0,0x1e
    800047dc:	e7850513          	addi	a0,a0,-392 # 80022650 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	41c080e7          	jalr	1052(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047e8:	40dc                	lw	a5,4(s1)
    800047ea:	02f05263          	blez	a5,8000480e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ee:	2785                	addiw	a5,a5,1
    800047f0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047f2:	0001e517          	auipc	a0,0x1e
    800047f6:	e5e50513          	addi	a0,a0,-418 # 80022650 <ftable>
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	4b6080e7          	jalr	1206(ra) # 80000cb0 <release>
  return f;
}
    80004802:	8526                	mv	a0,s1
    80004804:	60e2                	ld	ra,24(sp)
    80004806:	6442                	ld	s0,16(sp)
    80004808:	64a2                	ld	s1,8(sp)
    8000480a:	6105                	addi	sp,sp,32
    8000480c:	8082                	ret
    panic("filedup");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	ed250513          	addi	a0,a0,-302 # 800086e0 <syscalls+0x240>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	d2a080e7          	jalr	-726(ra) # 80000540 <panic>

000000008000481e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000481e:	7139                	addi	sp,sp,-64
    80004820:	fc06                	sd	ra,56(sp)
    80004822:	f822                	sd	s0,48(sp)
    80004824:	f426                	sd	s1,40(sp)
    80004826:	f04a                	sd	s2,32(sp)
    80004828:	ec4e                	sd	s3,24(sp)
    8000482a:	e852                	sd	s4,16(sp)
    8000482c:	e456                	sd	s5,8(sp)
    8000482e:	0080                	addi	s0,sp,64
    80004830:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004832:	0001e517          	auipc	a0,0x1e
    80004836:	e1e50513          	addi	a0,a0,-482 # 80022650 <ftable>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	3c2080e7          	jalr	962(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    80004842:	40dc                	lw	a5,4(s1)
    80004844:	06f05163          	blez	a5,800048a6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004848:	37fd                	addiw	a5,a5,-1
    8000484a:	0007871b          	sext.w	a4,a5
    8000484e:	c0dc                	sw	a5,4(s1)
    80004850:	06e04363          	bgtz	a4,800048b6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004854:	0004a903          	lw	s2,0(s1)
    80004858:	0094ca83          	lbu	s5,9(s1)
    8000485c:	0104ba03          	ld	s4,16(s1)
    80004860:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004864:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004868:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000486c:	0001e517          	auipc	a0,0x1e
    80004870:	de450513          	addi	a0,a0,-540 # 80022650 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	43c080e7          	jalr	1084(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    8000487c:	4785                	li	a5,1
    8000487e:	04f90d63          	beq	s2,a5,800048d8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004882:	3979                	addiw	s2,s2,-2
    80004884:	4785                	li	a5,1
    80004886:	0527e063          	bltu	a5,s2,800048c6 <fileclose+0xa8>
    begin_op();
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	ac2080e7          	jalr	-1342(ra) # 8000434c <begin_op>
    iput(ff.ip);
    80004892:	854e                	mv	a0,s3
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	2b2080e7          	jalr	690(ra) # 80003b46 <iput>
    end_op();
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	b30080e7          	jalr	-1232(ra) # 800043cc <end_op>
    800048a4:	a00d                	j	800048c6 <fileclose+0xa8>
    panic("fileclose");
    800048a6:	00004517          	auipc	a0,0x4
    800048aa:	e4250513          	addi	a0,a0,-446 # 800086e8 <syscalls+0x248>
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	c92080e7          	jalr	-878(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048b6:	0001e517          	auipc	a0,0x1e
    800048ba:	d9a50513          	addi	a0,a0,-614 # 80022650 <ftable>
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	3f2080e7          	jalr	1010(ra) # 80000cb0 <release>
  }
}
    800048c6:	70e2                	ld	ra,56(sp)
    800048c8:	7442                	ld	s0,48(sp)
    800048ca:	74a2                	ld	s1,40(sp)
    800048cc:	7902                	ld	s2,32(sp)
    800048ce:	69e2                	ld	s3,24(sp)
    800048d0:	6a42                	ld	s4,16(sp)
    800048d2:	6aa2                	ld	s5,8(sp)
    800048d4:	6121                	addi	sp,sp,64
    800048d6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d8:	85d6                	mv	a1,s5
    800048da:	8552                	mv	a0,s4
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	372080e7          	jalr	882(ra) # 80004c4e <pipeclose>
    800048e4:	b7cd                	j	800048c6 <fileclose+0xa8>

00000000800048e6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e6:	715d                	addi	sp,sp,-80
    800048e8:	e486                	sd	ra,72(sp)
    800048ea:	e0a2                	sd	s0,64(sp)
    800048ec:	fc26                	sd	s1,56(sp)
    800048ee:	f84a                	sd	s2,48(sp)
    800048f0:	f44e                	sd	s3,40(sp)
    800048f2:	0880                	addi	s0,sp,80
    800048f4:	84aa                	mv	s1,a0
    800048f6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f8:	ffffd097          	auipc	ra,0xffffd
    800048fc:	23e080e7          	jalr	574(ra) # 80001b36 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004900:	409c                	lw	a5,0(s1)
    80004902:	37f9                	addiw	a5,a5,-2
    80004904:	4705                	li	a4,1
    80004906:	04f76763          	bltu	a4,a5,80004954 <filestat+0x6e>
    8000490a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000490c:	6c88                	ld	a0,24(s1)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	07e080e7          	jalr	126(ra) # 8000398c <ilock>
    stati(f->ip, &st);
    80004916:	fb840593          	addi	a1,s0,-72
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	2fa080e7          	jalr	762(ra) # 80003c16 <stati>
    iunlock(f->ip);
    80004924:	6c88                	ld	a0,24(s1)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	128080e7          	jalr	296(ra) # 80003a4e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000492e:	46e1                	li	a3,24
    80004930:	fb840613          	addi	a2,s0,-72
    80004934:	85ce                	mv	a1,s3
    80004936:	05093503          	ld	a0,80(s2)
    8000493a:	ffffd097          	auipc	ra,0xffffd
    8000493e:	d70080e7          	jalr	-656(ra) # 800016aa <copyout>
    80004942:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004946:	60a6                	ld	ra,72(sp)
    80004948:	6406                	ld	s0,64(sp)
    8000494a:	74e2                	ld	s1,56(sp)
    8000494c:	7942                	ld	s2,48(sp)
    8000494e:	79a2                	ld	s3,40(sp)
    80004950:	6161                	addi	sp,sp,80
    80004952:	8082                	ret
  return -1;
    80004954:	557d                	li	a0,-1
    80004956:	bfc5                	j	80004946 <filestat+0x60>

0000000080004958 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004958:	7179                	addi	sp,sp,-48
    8000495a:	f406                	sd	ra,40(sp)
    8000495c:	f022                	sd	s0,32(sp)
    8000495e:	ec26                	sd	s1,24(sp)
    80004960:	e84a                	sd	s2,16(sp)
    80004962:	e44e                	sd	s3,8(sp)
    80004964:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004966:	00854783          	lbu	a5,8(a0)
    8000496a:	c3d5                	beqz	a5,80004a0e <fileread+0xb6>
    8000496c:	84aa                	mv	s1,a0
    8000496e:	89ae                	mv	s3,a1
    80004970:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004972:	411c                	lw	a5,0(a0)
    80004974:	4705                	li	a4,1
    80004976:	04e78963          	beq	a5,a4,800049c8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000497a:	470d                	li	a4,3
    8000497c:	04e78d63          	beq	a5,a4,800049d6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004980:	4709                	li	a4,2
    80004982:	06e79e63          	bne	a5,a4,800049fe <fileread+0xa6>
    ilock(f->ip);
    80004986:	6d08                	ld	a0,24(a0)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	004080e7          	jalr	4(ra) # 8000398c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004990:	874a                	mv	a4,s2
    80004992:	5094                	lw	a3,32(s1)
    80004994:	864e                	mv	a2,s3
    80004996:	4585                	li	a1,1
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	2a6080e7          	jalr	678(ra) # 80003c40 <readi>
    800049a2:	892a                	mv	s2,a0
    800049a4:	00a05563          	blez	a0,800049ae <fileread+0x56>
      f->off += r;
    800049a8:	509c                	lw	a5,32(s1)
    800049aa:	9fa9                	addw	a5,a5,a0
    800049ac:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049ae:	6c88                	ld	a0,24(s1)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	09e080e7          	jalr	158(ra) # 80003a4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b8:	854a                	mv	a0,s2
    800049ba:	70a2                	ld	ra,40(sp)
    800049bc:	7402                	ld	s0,32(sp)
    800049be:	64e2                	ld	s1,24(sp)
    800049c0:	6942                	ld	s2,16(sp)
    800049c2:	69a2                	ld	s3,8(sp)
    800049c4:	6145                	addi	sp,sp,48
    800049c6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c8:	6908                	ld	a0,16(a0)
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	3f4080e7          	jalr	1012(ra) # 80004dbe <piperead>
    800049d2:	892a                	mv	s2,a0
    800049d4:	b7d5                	j	800049b8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d6:	02451783          	lh	a5,36(a0)
    800049da:	03079693          	slli	a3,a5,0x30
    800049de:	92c1                	srli	a3,a3,0x30
    800049e0:	4725                	li	a4,9
    800049e2:	02d76863          	bltu	a4,a3,80004a12 <fileread+0xba>
    800049e6:	0792                	slli	a5,a5,0x4
    800049e8:	0001e717          	auipc	a4,0x1e
    800049ec:	bc870713          	addi	a4,a4,-1080 # 800225b0 <devsw>
    800049f0:	97ba                	add	a5,a5,a4
    800049f2:	639c                	ld	a5,0(a5)
    800049f4:	c38d                	beqz	a5,80004a16 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f6:	4505                	li	a0,1
    800049f8:	9782                	jalr	a5
    800049fa:	892a                	mv	s2,a0
    800049fc:	bf75                	j	800049b8 <fileread+0x60>
    panic("fileread");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	cfa50513          	addi	a0,a0,-774 # 800086f8 <syscalls+0x258>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	b3a080e7          	jalr	-1222(ra) # 80000540 <panic>
    return -1;
    80004a0e:	597d                	li	s2,-1
    80004a10:	b765                	j	800049b8 <fileread+0x60>
      return -1;
    80004a12:	597d                	li	s2,-1
    80004a14:	b755                	j	800049b8 <fileread+0x60>
    80004a16:	597d                	li	s2,-1
    80004a18:	b745                	j	800049b8 <fileread+0x60>

0000000080004a1a <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a1a:	00954783          	lbu	a5,9(a0)
    80004a1e:	14078563          	beqz	a5,80004b68 <filewrite+0x14e>
{
    80004a22:	715d                	addi	sp,sp,-80
    80004a24:	e486                	sd	ra,72(sp)
    80004a26:	e0a2                	sd	s0,64(sp)
    80004a28:	fc26                	sd	s1,56(sp)
    80004a2a:	f84a                	sd	s2,48(sp)
    80004a2c:	f44e                	sd	s3,40(sp)
    80004a2e:	f052                	sd	s4,32(sp)
    80004a30:	ec56                	sd	s5,24(sp)
    80004a32:	e85a                	sd	s6,16(sp)
    80004a34:	e45e                	sd	s7,8(sp)
    80004a36:	e062                	sd	s8,0(sp)
    80004a38:	0880                	addi	s0,sp,80
    80004a3a:	892a                	mv	s2,a0
    80004a3c:	8aae                	mv	s5,a1
    80004a3e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a40:	411c                	lw	a5,0(a0)
    80004a42:	4705                	li	a4,1
    80004a44:	02e78263          	beq	a5,a4,80004a68 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a48:	470d                	li	a4,3
    80004a4a:	02e78563          	beq	a5,a4,80004a74 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4e:	4709                	li	a4,2
    80004a50:	10e79463          	bne	a5,a4,80004b58 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a54:	0ec05e63          	blez	a2,80004b50 <filewrite+0x136>
    int i = 0;
    80004a58:	4981                	li	s3,0
    80004a5a:	6b05                	lui	s6,0x1
    80004a5c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a60:	6b85                	lui	s7,0x1
    80004a62:	c00b8b9b          	addiw	s7,s7,-1024
    80004a66:	a851                	j	80004afa <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a68:	6908                	ld	a0,16(a0)
    80004a6a:	00000097          	auipc	ra,0x0
    80004a6e:	254080e7          	jalr	596(ra) # 80004cbe <pipewrite>
    80004a72:	a85d                	j	80004b28 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a74:	02451783          	lh	a5,36(a0)
    80004a78:	03079693          	slli	a3,a5,0x30
    80004a7c:	92c1                	srli	a3,a3,0x30
    80004a7e:	4725                	li	a4,9
    80004a80:	0ed76663          	bltu	a4,a3,80004b6c <filewrite+0x152>
    80004a84:	0792                	slli	a5,a5,0x4
    80004a86:	0001e717          	auipc	a4,0x1e
    80004a8a:	b2a70713          	addi	a4,a4,-1238 # 800225b0 <devsw>
    80004a8e:	97ba                	add	a5,a5,a4
    80004a90:	679c                	ld	a5,8(a5)
    80004a92:	cff9                	beqz	a5,80004b70 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a94:	4505                	li	a0,1
    80004a96:	9782                	jalr	a5
    80004a98:	a841                	j	80004b28 <filewrite+0x10e>
    80004a9a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	8ae080e7          	jalr	-1874(ra) # 8000434c <begin_op>
      ilock(f->ip);
    80004aa6:	01893503          	ld	a0,24(s2)
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	ee2080e7          	jalr	-286(ra) # 8000398c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ab2:	8762                	mv	a4,s8
    80004ab4:	02092683          	lw	a3,32(s2)
    80004ab8:	01598633          	add	a2,s3,s5
    80004abc:	4585                	li	a1,1
    80004abe:	01893503          	ld	a0,24(s2)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	274080e7          	jalr	628(ra) # 80003d36 <writei>
    80004aca:	84aa                	mv	s1,a0
    80004acc:	02a05f63          	blez	a0,80004b0a <filewrite+0xf0>
        f->off += r;
    80004ad0:	02092783          	lw	a5,32(s2)
    80004ad4:	9fa9                	addw	a5,a5,a0
    80004ad6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ada:	01893503          	ld	a0,24(s2)
    80004ade:	fffff097          	auipc	ra,0xfffff
    80004ae2:	f70080e7          	jalr	-144(ra) # 80003a4e <iunlock>
      end_op();
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	8e6080e7          	jalr	-1818(ra) # 800043cc <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aee:	049c1963          	bne	s8,s1,80004b40 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004af2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af6:	0349d663          	bge	s3,s4,80004b22 <filewrite+0x108>
      int n1 = n - i;
    80004afa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004afe:	84be                	mv	s1,a5
    80004b00:	2781                	sext.w	a5,a5
    80004b02:	f8fb5ce3          	bge	s6,a5,80004a9a <filewrite+0x80>
    80004b06:	84de                	mv	s1,s7
    80004b08:	bf49                	j	80004a9a <filewrite+0x80>
      iunlock(f->ip);
    80004b0a:	01893503          	ld	a0,24(s2)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	f40080e7          	jalr	-192(ra) # 80003a4e <iunlock>
      end_op();
    80004b16:	00000097          	auipc	ra,0x0
    80004b1a:	8b6080e7          	jalr	-1866(ra) # 800043cc <end_op>
      if(r < 0)
    80004b1e:	fc04d8e3          	bgez	s1,80004aee <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b22:	8552                	mv	a0,s4
    80004b24:	033a1863          	bne	s4,s3,80004b54 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b28:	60a6                	ld	ra,72(sp)
    80004b2a:	6406                	ld	s0,64(sp)
    80004b2c:	74e2                	ld	s1,56(sp)
    80004b2e:	7942                	ld	s2,48(sp)
    80004b30:	79a2                	ld	s3,40(sp)
    80004b32:	7a02                	ld	s4,32(sp)
    80004b34:	6ae2                	ld	s5,24(sp)
    80004b36:	6b42                	ld	s6,16(sp)
    80004b38:	6ba2                	ld	s7,8(sp)
    80004b3a:	6c02                	ld	s8,0(sp)
    80004b3c:	6161                	addi	sp,sp,80
    80004b3e:	8082                	ret
        panic("short filewrite");
    80004b40:	00004517          	auipc	a0,0x4
    80004b44:	bc850513          	addi	a0,a0,-1080 # 80008708 <syscalls+0x268>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	9f8080e7          	jalr	-1544(ra) # 80000540 <panic>
    int i = 0;
    80004b50:	4981                	li	s3,0
    80004b52:	bfc1                	j	80004b22 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b54:	557d                	li	a0,-1
    80004b56:	bfc9                	j	80004b28 <filewrite+0x10e>
    panic("filewrite");
    80004b58:	00004517          	auipc	a0,0x4
    80004b5c:	bc050513          	addi	a0,a0,-1088 # 80008718 <syscalls+0x278>
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	9e0080e7          	jalr	-1568(ra) # 80000540 <panic>
    return -1;
    80004b68:	557d                	li	a0,-1
}
    80004b6a:	8082                	ret
      return -1;
    80004b6c:	557d                	li	a0,-1
    80004b6e:	bf6d                	j	80004b28 <filewrite+0x10e>
    80004b70:	557d                	li	a0,-1
    80004b72:	bf5d                	j	80004b28 <filewrite+0x10e>

0000000080004b74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b74:	7179                	addi	sp,sp,-48
    80004b76:	f406                	sd	ra,40(sp)
    80004b78:	f022                	sd	s0,32(sp)
    80004b7a:	ec26                	sd	s1,24(sp)
    80004b7c:	e84a                	sd	s2,16(sp)
    80004b7e:	e44e                	sd	s3,8(sp)
    80004b80:	e052                	sd	s4,0(sp)
    80004b82:	1800                	addi	s0,sp,48
    80004b84:	84aa                	mv	s1,a0
    80004b86:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b88:	0005b023          	sd	zero,0(a1)
    80004b8c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b90:	00000097          	auipc	ra,0x0
    80004b94:	bd2080e7          	jalr	-1070(ra) # 80004762 <filealloc>
    80004b98:	e088                	sd	a0,0(s1)
    80004b9a:	c551                	beqz	a0,80004c26 <pipealloc+0xb2>
    80004b9c:	00000097          	auipc	ra,0x0
    80004ba0:	bc6080e7          	jalr	-1082(ra) # 80004762 <filealloc>
    80004ba4:	00aa3023          	sd	a0,0(s4)
    80004ba8:	c92d                	beqz	a0,80004c1a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	f62080e7          	jalr	-158(ra) # 80000b0c <kalloc>
    80004bb2:	892a                	mv	s2,a0
    80004bb4:	c125                	beqz	a0,80004c14 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bb6:	4985                	li	s3,1
    80004bb8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bbc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bc0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bc4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bc8:	00004597          	auipc	a1,0x4
    80004bcc:	b6058593          	addi	a1,a1,-1184 # 80008728 <syscalls+0x288>
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	f9c080e7          	jalr	-100(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004bd8:	609c                	ld	a5,0(s1)
    80004bda:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bde:	609c                	ld	a5,0(s1)
    80004be0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004be4:	609c                	ld	a5,0(s1)
    80004be6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bea:	609c                	ld	a5,0(s1)
    80004bec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bf0:	000a3783          	ld	a5,0(s4)
    80004bf4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bf8:	000a3783          	ld	a5,0(s4)
    80004bfc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c00:	000a3783          	ld	a5,0(s4)
    80004c04:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c08:	000a3783          	ld	a5,0(s4)
    80004c0c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c10:	4501                	li	a0,0
    80004c12:	a025                	j	80004c3a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c14:	6088                	ld	a0,0(s1)
    80004c16:	e501                	bnez	a0,80004c1e <pipealloc+0xaa>
    80004c18:	a039                	j	80004c26 <pipealloc+0xb2>
    80004c1a:	6088                	ld	a0,0(s1)
    80004c1c:	c51d                	beqz	a0,80004c4a <pipealloc+0xd6>
    fileclose(*f0);
    80004c1e:	00000097          	auipc	ra,0x0
    80004c22:	c00080e7          	jalr	-1024(ra) # 8000481e <fileclose>
  if(*f1)
    80004c26:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c2a:	557d                	li	a0,-1
  if(*f1)
    80004c2c:	c799                	beqz	a5,80004c3a <pipealloc+0xc6>
    fileclose(*f1);
    80004c2e:	853e                	mv	a0,a5
    80004c30:	00000097          	auipc	ra,0x0
    80004c34:	bee080e7          	jalr	-1042(ra) # 8000481e <fileclose>
  return -1;
    80004c38:	557d                	li	a0,-1
}
    80004c3a:	70a2                	ld	ra,40(sp)
    80004c3c:	7402                	ld	s0,32(sp)
    80004c3e:	64e2                	ld	s1,24(sp)
    80004c40:	6942                	ld	s2,16(sp)
    80004c42:	69a2                	ld	s3,8(sp)
    80004c44:	6a02                	ld	s4,0(sp)
    80004c46:	6145                	addi	sp,sp,48
    80004c48:	8082                	ret
  return -1;
    80004c4a:	557d                	li	a0,-1
    80004c4c:	b7fd                	j	80004c3a <pipealloc+0xc6>

0000000080004c4e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c4e:	1101                	addi	sp,sp,-32
    80004c50:	ec06                	sd	ra,24(sp)
    80004c52:	e822                	sd	s0,16(sp)
    80004c54:	e426                	sd	s1,8(sp)
    80004c56:	e04a                	sd	s2,0(sp)
    80004c58:	1000                	addi	s0,sp,32
    80004c5a:	84aa                	mv	s1,a0
    80004c5c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	f9e080e7          	jalr	-98(ra) # 80000bfc <acquire>
  if(writable){
    80004c66:	02090d63          	beqz	s2,80004ca0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c6a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c6e:	21848513          	addi	a0,s1,536
    80004c72:	ffffe097          	auipc	ra,0xffffe
    80004c76:	a1a080e7          	jalr	-1510(ra) # 8000268c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c7a:	2204b783          	ld	a5,544(s1)
    80004c7e:	eb95                	bnez	a5,80004cb2 <pipeclose+0x64>
    release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	02e080e7          	jalr	46(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	d84080e7          	jalr	-636(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6902                	ld	s2,0(sp)
    80004c9c:	6105                	addi	sp,sp,32
    80004c9e:	8082                	ret
    pi->readopen = 0;
    80004ca0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ca4:	21c48513          	addi	a0,s1,540
    80004ca8:	ffffe097          	auipc	ra,0xffffe
    80004cac:	9e4080e7          	jalr	-1564(ra) # 8000268c <wakeup>
    80004cb0:	b7e9                	j	80004c7a <pipeclose+0x2c>
    release(&pi->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	ffc080e7          	jalr	-4(ra) # 80000cb0 <release>
}
    80004cbc:	bfe1                	j	80004c94 <pipeclose+0x46>

0000000080004cbe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	711d                	addi	sp,sp,-96
    80004cc0:	ec86                	sd	ra,88(sp)
    80004cc2:	e8a2                	sd	s0,80(sp)
    80004cc4:	e4a6                	sd	s1,72(sp)
    80004cc6:	e0ca                	sd	s2,64(sp)
    80004cc8:	fc4e                	sd	s3,56(sp)
    80004cca:	f852                	sd	s4,48(sp)
    80004ccc:	f456                	sd	s5,40(sp)
    80004cce:	f05a                	sd	s6,32(sp)
    80004cd0:	ec5e                	sd	s7,24(sp)
    80004cd2:	e862                	sd	s8,16(sp)
    80004cd4:	1080                	addi	s0,sp,96
    80004cd6:	84aa                	mv	s1,a0
    80004cd8:	8b2e                	mv	s6,a1
    80004cda:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	e5a080e7          	jalr	-422(ra) # 80001b36 <myproc>
    80004ce4:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	f14080e7          	jalr	-236(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004cf0:	09505763          	blez	s5,80004d7e <pipewrite+0xc0>
    80004cf4:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cf6:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cfa:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cfe:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d00:	2184a783          	lw	a5,536(s1)
    80004d04:	21c4a703          	lw	a4,540(s1)
    80004d08:	2007879b          	addiw	a5,a5,512
    80004d0c:	02f71b63          	bne	a4,a5,80004d42 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d10:	2204a783          	lw	a5,544(s1)
    80004d14:	c3d1                	beqz	a5,80004d98 <pipewrite+0xda>
    80004d16:	03092783          	lw	a5,48(s2)
    80004d1a:	efbd                	bnez	a5,80004d98 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d1c:	8552                	mv	a0,s4
    80004d1e:	ffffe097          	auipc	ra,0xffffe
    80004d22:	96e080e7          	jalr	-1682(ra) # 8000268c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d26:	85a6                	mv	a1,s1
    80004d28:	854e                	mv	a0,s3
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	7a4080e7          	jalr	1956(ra) # 800024ce <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d32:	2184a783          	lw	a5,536(s1)
    80004d36:	21c4a703          	lw	a4,540(s1)
    80004d3a:	2007879b          	addiw	a5,a5,512
    80004d3e:	fcf709e3          	beq	a4,a5,80004d10 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d42:	4685                	li	a3,1
    80004d44:	865a                	mv	a2,s6
    80004d46:	faf40593          	addi	a1,s0,-81
    80004d4a:	05093503          	ld	a0,80(s2)
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	9e8080e7          	jalr	-1560(ra) # 80001736 <copyin>
    80004d56:	03850563          	beq	a0,s8,80004d80 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d5a:	21c4a783          	lw	a5,540(s1)
    80004d5e:	0017871b          	addiw	a4,a5,1
    80004d62:	20e4ae23          	sw	a4,540(s1)
    80004d66:	1ff7f793          	andi	a5,a5,511
    80004d6a:	97a6                	add	a5,a5,s1
    80004d6c:	faf44703          	lbu	a4,-81(s0)
    80004d70:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d74:	2b85                	addiw	s7,s7,1
    80004d76:	0b05                	addi	s6,s6,1
    80004d78:	f97a94e3          	bne	s5,s7,80004d00 <pipewrite+0x42>
    80004d7c:	a011                	j	80004d80 <pipewrite+0xc2>
    80004d7e:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d80:	21848513          	addi	a0,s1,536
    80004d84:	ffffe097          	auipc	ra,0xffffe
    80004d88:	908080e7          	jalr	-1784(ra) # 8000268c <wakeup>
  release(&pi->lock);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	f22080e7          	jalr	-222(ra) # 80000cb0 <release>
  return i;
    80004d96:	a039                	j	80004da4 <pipewrite+0xe6>
        release(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	f16080e7          	jalr	-234(ra) # 80000cb0 <release>
        return -1;
    80004da2:	5bfd                	li	s7,-1
}
    80004da4:	855e                	mv	a0,s7
    80004da6:	60e6                	ld	ra,88(sp)
    80004da8:	6446                	ld	s0,80(sp)
    80004daa:	64a6                	ld	s1,72(sp)
    80004dac:	6906                	ld	s2,64(sp)
    80004dae:	79e2                	ld	s3,56(sp)
    80004db0:	7a42                	ld	s4,48(sp)
    80004db2:	7aa2                	ld	s5,40(sp)
    80004db4:	7b02                	ld	s6,32(sp)
    80004db6:	6be2                	ld	s7,24(sp)
    80004db8:	6c42                	ld	s8,16(sp)
    80004dba:	6125                	addi	sp,sp,96
    80004dbc:	8082                	ret

0000000080004dbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dbe:	715d                	addi	sp,sp,-80
    80004dc0:	e486                	sd	ra,72(sp)
    80004dc2:	e0a2                	sd	s0,64(sp)
    80004dc4:	fc26                	sd	s1,56(sp)
    80004dc6:	f84a                	sd	s2,48(sp)
    80004dc8:	f44e                	sd	s3,40(sp)
    80004dca:	f052                	sd	s4,32(sp)
    80004dcc:	ec56                	sd	s5,24(sp)
    80004dce:	e85a                	sd	s6,16(sp)
    80004dd0:	0880                	addi	s0,sp,80
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	892e                	mv	s2,a1
    80004dd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	d5e080e7          	jalr	-674(ra) # 80001b36 <myproc>
    80004de0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	e18080e7          	jalr	-488(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dec:	2184a703          	lw	a4,536(s1)
    80004df0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df8:	02f71463          	bne	a4,a5,80004e20 <piperead+0x62>
    80004dfc:	2244a783          	lw	a5,548(s1)
    80004e00:	c385                	beqz	a5,80004e20 <piperead+0x62>
    if(pr->killed){
    80004e02:	030a2783          	lw	a5,48(s4)
    80004e06:	ebc1                	bnez	a5,80004e96 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e08:	85a6                	mv	a1,s1
    80004e0a:	854e                	mv	a0,s3
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	6c2080e7          	jalr	1730(ra) # 800024ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e14:	2184a703          	lw	a4,536(s1)
    80004e18:	21c4a783          	lw	a5,540(s1)
    80004e1c:	fef700e3          	beq	a4,a5,80004dfc <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e20:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e22:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e24:	05505363          	blez	s5,80004e6a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e28:	2184a783          	lw	a5,536(s1)
    80004e2c:	21c4a703          	lw	a4,540(s1)
    80004e30:	02f70d63          	beq	a4,a5,80004e6a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e34:	0017871b          	addiw	a4,a5,1
    80004e38:	20e4ac23          	sw	a4,536(s1)
    80004e3c:	1ff7f793          	andi	a5,a5,511
    80004e40:	97a6                	add	a5,a5,s1
    80004e42:	0187c783          	lbu	a5,24(a5)
    80004e46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4a:	4685                	li	a3,1
    80004e4c:	fbf40613          	addi	a2,s0,-65
    80004e50:	85ca                	mv	a1,s2
    80004e52:	050a3503          	ld	a0,80(s4)
    80004e56:	ffffd097          	auipc	ra,0xffffd
    80004e5a:	854080e7          	jalr	-1964(ra) # 800016aa <copyout>
    80004e5e:	01650663          	beq	a0,s6,80004e6a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e62:	2985                	addiw	s3,s3,1
    80004e64:	0905                	addi	s2,s2,1
    80004e66:	fd3a91e3          	bne	s5,s3,80004e28 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e6a:	21c48513          	addi	a0,s1,540
    80004e6e:	ffffe097          	auipc	ra,0xffffe
    80004e72:	81e080e7          	jalr	-2018(ra) # 8000268c <wakeup>
  release(&pi->lock);
    80004e76:	8526                	mv	a0,s1
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	e38080e7          	jalr	-456(ra) # 80000cb0 <release>
  return i;
}
    80004e80:	854e                	mv	a0,s3
    80004e82:	60a6                	ld	ra,72(sp)
    80004e84:	6406                	ld	s0,64(sp)
    80004e86:	74e2                	ld	s1,56(sp)
    80004e88:	7942                	ld	s2,48(sp)
    80004e8a:	79a2                	ld	s3,40(sp)
    80004e8c:	7a02                	ld	s4,32(sp)
    80004e8e:	6ae2                	ld	s5,24(sp)
    80004e90:	6b42                	ld	s6,16(sp)
    80004e92:	6161                	addi	sp,sp,80
    80004e94:	8082                	ret
      release(&pi->lock);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	e18080e7          	jalr	-488(ra) # 80000cb0 <release>
      return -1;
    80004ea0:	59fd                	li	s3,-1
    80004ea2:	bff9                	j	80004e80 <piperead+0xc2>

0000000080004ea4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ea4:	de010113          	addi	sp,sp,-544
    80004ea8:	20113c23          	sd	ra,536(sp)
    80004eac:	20813823          	sd	s0,528(sp)
    80004eb0:	20913423          	sd	s1,520(sp)
    80004eb4:	21213023          	sd	s2,512(sp)
    80004eb8:	ffce                	sd	s3,504(sp)
    80004eba:	fbd2                	sd	s4,496(sp)
    80004ebc:	f7d6                	sd	s5,488(sp)
    80004ebe:	f3da                	sd	s6,480(sp)
    80004ec0:	efde                	sd	s7,472(sp)
    80004ec2:	ebe2                	sd	s8,464(sp)
    80004ec4:	e7e6                	sd	s9,456(sp)
    80004ec6:	e3ea                	sd	s10,448(sp)
    80004ec8:	ff6e                	sd	s11,440(sp)
    80004eca:	1400                	addi	s0,sp,544
    80004ecc:	892a                	mv	s2,a0
    80004ece:	dea43423          	sd	a0,-536(s0)
    80004ed2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	c60080e7          	jalr	-928(ra) # 80001b36 <myproc>
    80004ede:	84aa                	mv	s1,a0

  begin_op();
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	46c080e7          	jalr	1132(ra) # 8000434c <begin_op>

  if((ip = namei(path)) == 0){
    80004ee8:	854a                	mv	a0,s2
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	252080e7          	jalr	594(ra) # 8000413c <namei>
    80004ef2:	c93d                	beqz	a0,80004f68 <exec+0xc4>
    80004ef4:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	a96080e7          	jalr	-1386(ra) # 8000398c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004efe:	04000713          	li	a4,64
    80004f02:	4681                	li	a3,0
    80004f04:	e4840613          	addi	a2,s0,-440
    80004f08:	4581                	li	a1,0
    80004f0a:	8556                	mv	a0,s5
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	d34080e7          	jalr	-716(ra) # 80003c40 <readi>
    80004f14:	04000793          	li	a5,64
    80004f18:	00f51a63          	bne	a0,a5,80004f2c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f1c:	e4842703          	lw	a4,-440(s0)
    80004f20:	464c47b7          	lui	a5,0x464c4
    80004f24:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f28:	04f70663          	beq	a4,a5,80004f74 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f2c:	8556                	mv	a0,s5
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	cc0080e7          	jalr	-832(ra) # 80003bee <iunlockput>
    end_op();
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	496080e7          	jalr	1174(ra) # 800043cc <end_op>
  }
  return -1;
    80004f3e:	557d                	li	a0,-1
}
    80004f40:	21813083          	ld	ra,536(sp)
    80004f44:	21013403          	ld	s0,528(sp)
    80004f48:	20813483          	ld	s1,520(sp)
    80004f4c:	20013903          	ld	s2,512(sp)
    80004f50:	79fe                	ld	s3,504(sp)
    80004f52:	7a5e                	ld	s4,496(sp)
    80004f54:	7abe                	ld	s5,488(sp)
    80004f56:	7b1e                	ld	s6,480(sp)
    80004f58:	6bfe                	ld	s7,472(sp)
    80004f5a:	6c5e                	ld	s8,464(sp)
    80004f5c:	6cbe                	ld	s9,456(sp)
    80004f5e:	6d1e                	ld	s10,448(sp)
    80004f60:	7dfa                	ld	s11,440(sp)
    80004f62:	22010113          	addi	sp,sp,544
    80004f66:	8082                	ret
    end_op();
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	464080e7          	jalr	1124(ra) # 800043cc <end_op>
    return -1;
    80004f70:	557d                	li	a0,-1
    80004f72:	b7f9                	j	80004f40 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f74:	8526                	mv	a0,s1
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	c86080e7          	jalr	-890(ra) # 80001bfc <proc_pagetable>
    80004f7e:	8b2a                	mv	s6,a0
    80004f80:	d555                	beqz	a0,80004f2c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f82:	e6842783          	lw	a5,-408(s0)
    80004f86:	e8045703          	lhu	a4,-384(s0)
    80004f8a:	c735                	beqz	a4,80004ff6 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f8c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f8e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f92:	6a05                	lui	s4,0x1
    80004f94:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f98:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f9c:	6d85                	lui	s11,0x1
    80004f9e:	7d7d                	lui	s10,0xfffff
    80004fa0:	ac1d                	j	800051d6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fa2:	00003517          	auipc	a0,0x3
    80004fa6:	78e50513          	addi	a0,a0,1934 # 80008730 <syscalls+0x290>
    80004faa:	ffffb097          	auipc	ra,0xffffb
    80004fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fb2:	874a                	mv	a4,s2
    80004fb4:	009c86bb          	addw	a3,s9,s1
    80004fb8:	4581                	li	a1,0
    80004fba:	8556                	mv	a0,s5
    80004fbc:	fffff097          	auipc	ra,0xfffff
    80004fc0:	c84080e7          	jalr	-892(ra) # 80003c40 <readi>
    80004fc4:	2501                	sext.w	a0,a0
    80004fc6:	1aa91863          	bne	s2,a0,80005176 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fca:	009d84bb          	addw	s1,s11,s1
    80004fce:	013d09bb          	addw	s3,s10,s3
    80004fd2:	1f74f263          	bgeu	s1,s7,800051b6 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fd6:	02049593          	slli	a1,s1,0x20
    80004fda:	9181                	srli	a1,a1,0x20
    80004fdc:	95e2                	add	a1,a1,s8
    80004fde:	855a                	mv	a0,s6
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	096080e7          	jalr	150(ra) # 80001076 <walkaddr>
    80004fe8:	862a                	mv	a2,a0
    if(pa == 0)
    80004fea:	dd45                	beqz	a0,80004fa2 <exec+0xfe>
      n = PGSIZE;
    80004fec:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fee:	fd49f2e3          	bgeu	s3,s4,80004fb2 <exec+0x10e>
      n = sz - i;
    80004ff2:	894e                	mv	s2,s3
    80004ff4:	bf7d                	j	80004fb2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ff6:	4481                	li	s1,0
  iunlockput(ip);
    80004ff8:	8556                	mv	a0,s5
    80004ffa:	fffff097          	auipc	ra,0xfffff
    80004ffe:	bf4080e7          	jalr	-1036(ra) # 80003bee <iunlockput>
  end_op();
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	3ca080e7          	jalr	970(ra) # 800043cc <end_op>
  p = myproc();
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	b2c080e7          	jalr	-1236(ra) # 80001b36 <myproc>
    80005012:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005014:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005018:	6785                	lui	a5,0x1
    8000501a:	17fd                	addi	a5,a5,-1
    8000501c:	94be                	add	s1,s1,a5
    8000501e:	77fd                	lui	a5,0xfffff
    80005020:	8fe5                	and	a5,a5,s1
    80005022:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005026:	6609                	lui	a2,0x2
    80005028:	963e                	add	a2,a2,a5
    8000502a:	85be                	mv	a1,a5
    8000502c:	855a                	mv	a0,s6
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	42c080e7          	jalr	1068(ra) # 8000145a <uvmalloc>
    80005036:	8c2a                	mv	s8,a0
  ip = 0;
    80005038:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000503a:	12050e63          	beqz	a0,80005176 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000503e:	75f9                	lui	a1,0xffffe
    80005040:	95aa                	add	a1,a1,a0
    80005042:	855a                	mv	a0,s6
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	634080e7          	jalr	1588(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    8000504c:	7afd                	lui	s5,0xfffff
    8000504e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005050:	df043783          	ld	a5,-528(s0)
    80005054:	6388                	ld	a0,0(a5)
    80005056:	c925                	beqz	a0,800050c6 <exec+0x222>
    80005058:	e8840993          	addi	s3,s0,-376
    8000505c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005060:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005062:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	e18080e7          	jalr	-488(ra) # 80000e7c <strlen>
    8000506c:	0015079b          	addiw	a5,a0,1
    80005070:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005074:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005078:	13596363          	bltu	s2,s5,8000519e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000507c:	df043d83          	ld	s11,-528(s0)
    80005080:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005084:	8552                	mv	a0,s4
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	df6080e7          	jalr	-522(ra) # 80000e7c <strlen>
    8000508e:	0015069b          	addiw	a3,a0,1
    80005092:	8652                	mv	a2,s4
    80005094:	85ca                	mv	a1,s2
    80005096:	855a                	mv	a0,s6
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	612080e7          	jalr	1554(ra) # 800016aa <copyout>
    800050a0:	10054363          	bltz	a0,800051a6 <exec+0x302>
    ustack[argc] = sp;
    800050a4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a8:	0485                	addi	s1,s1,1
    800050aa:	008d8793          	addi	a5,s11,8
    800050ae:	def43823          	sd	a5,-528(s0)
    800050b2:	008db503          	ld	a0,8(s11)
    800050b6:	c911                	beqz	a0,800050ca <exec+0x226>
    if(argc >= MAXARG)
    800050b8:	09a1                	addi	s3,s3,8
    800050ba:	fb3c95e3          	bne	s9,s3,80005064 <exec+0x1c0>
  sz = sz1;
    800050be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c2:	4a81                	li	s5,0
    800050c4:	a84d                	j	80005176 <exec+0x2d2>
  sp = sz;
    800050c6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c8:	4481                	li	s1,0
  ustack[argc] = 0;
    800050ca:	00349793          	slli	a5,s1,0x3
    800050ce:	f9040713          	addi	a4,s0,-112
    800050d2:	97ba                	add	a5,a5,a4
    800050d4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050d8:	00148693          	addi	a3,s1,1
    800050dc:	068e                	slli	a3,a3,0x3
    800050de:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050e2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050e6:	01597663          	bgeu	s2,s5,800050f2 <exec+0x24e>
  sz = sz1;
    800050ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ee:	4a81                	li	s5,0
    800050f0:	a059                	j	80005176 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050f2:	e8840613          	addi	a2,s0,-376
    800050f6:	85ca                	mv	a1,s2
    800050f8:	855a                	mv	a0,s6
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	5b0080e7          	jalr	1456(ra) # 800016aa <copyout>
    80005102:	0a054663          	bltz	a0,800051ae <exec+0x30a>
  p->trapframe->a1 = sp;
    80005106:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000510a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000510e:	de843783          	ld	a5,-536(s0)
    80005112:	0007c703          	lbu	a4,0(a5)
    80005116:	cf11                	beqz	a4,80005132 <exec+0x28e>
    80005118:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000511a:	02f00693          	li	a3,47
    8000511e:	a039                	j	8000512c <exec+0x288>
      last = s+1;
    80005120:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005124:	0785                	addi	a5,a5,1
    80005126:	fff7c703          	lbu	a4,-1(a5)
    8000512a:	c701                	beqz	a4,80005132 <exec+0x28e>
    if(*s == '/')
    8000512c:	fed71ce3          	bne	a4,a3,80005124 <exec+0x280>
    80005130:	bfc5                	j	80005120 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005132:	4641                	li	a2,16
    80005134:	de843583          	ld	a1,-536(s0)
    80005138:	158b8513          	addi	a0,s7,344
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	d0e080e7          	jalr	-754(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    80005144:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005148:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000514c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005150:	058bb783          	ld	a5,88(s7)
    80005154:	e6043703          	ld	a4,-416(s0)
    80005158:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000515a:	058bb783          	ld	a5,88(s7)
    8000515e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005162:	85ea                	mv	a1,s10
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	b34080e7          	jalr	-1228(ra) # 80001c98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000516c:	0004851b          	sext.w	a0,s1
    80005170:	bbc1                	j	80004f40 <exec+0x9c>
    80005172:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005176:	df843583          	ld	a1,-520(s0)
    8000517a:	855a                	mv	a0,s6
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	b1c080e7          	jalr	-1252(ra) # 80001c98 <proc_freepagetable>
  if(ip){
    80005184:	da0a94e3          	bnez	s5,80004f2c <exec+0x88>
  return -1;
    80005188:	557d                	li	a0,-1
    8000518a:	bb5d                	j	80004f40 <exec+0x9c>
    8000518c:	de943c23          	sd	s1,-520(s0)
    80005190:	b7dd                	j	80005176 <exec+0x2d2>
    80005192:	de943c23          	sd	s1,-520(s0)
    80005196:	b7c5                	j	80005176 <exec+0x2d2>
    80005198:	de943c23          	sd	s1,-520(s0)
    8000519c:	bfe9                	j	80005176 <exec+0x2d2>
  sz = sz1;
    8000519e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a2:	4a81                	li	s5,0
    800051a4:	bfc9                	j	80005176 <exec+0x2d2>
  sz = sz1;
    800051a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051aa:	4a81                	li	s5,0
    800051ac:	b7e9                	j	80005176 <exec+0x2d2>
  sz = sz1;
    800051ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051b2:	4a81                	li	s5,0
    800051b4:	b7c9                	j	80005176 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b6:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ba:	e0843783          	ld	a5,-504(s0)
    800051be:	0017869b          	addiw	a3,a5,1
    800051c2:	e0d43423          	sd	a3,-504(s0)
    800051c6:	e0043783          	ld	a5,-512(s0)
    800051ca:	0387879b          	addiw	a5,a5,56
    800051ce:	e8045703          	lhu	a4,-384(s0)
    800051d2:	e2e6d3e3          	bge	a3,a4,80004ff8 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051d6:	2781                	sext.w	a5,a5
    800051d8:	e0f43023          	sd	a5,-512(s0)
    800051dc:	03800713          	li	a4,56
    800051e0:	86be                	mv	a3,a5
    800051e2:	e1040613          	addi	a2,s0,-496
    800051e6:	4581                	li	a1,0
    800051e8:	8556                	mv	a0,s5
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	a56080e7          	jalr	-1450(ra) # 80003c40 <readi>
    800051f2:	03800793          	li	a5,56
    800051f6:	f6f51ee3          	bne	a0,a5,80005172 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051fa:	e1042783          	lw	a5,-496(s0)
    800051fe:	4705                	li	a4,1
    80005200:	fae79de3          	bne	a5,a4,800051ba <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005204:	e3843603          	ld	a2,-456(s0)
    80005208:	e3043783          	ld	a5,-464(s0)
    8000520c:	f8f660e3          	bltu	a2,a5,8000518c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005210:	e2043783          	ld	a5,-480(s0)
    80005214:	963e                	add	a2,a2,a5
    80005216:	f6f66ee3          	bltu	a2,a5,80005192 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000521a:	85a6                	mv	a1,s1
    8000521c:	855a                	mv	a0,s6
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	23c080e7          	jalr	572(ra) # 8000145a <uvmalloc>
    80005226:	dea43c23          	sd	a0,-520(s0)
    8000522a:	d53d                	beqz	a0,80005198 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000522c:	e2043c03          	ld	s8,-480(s0)
    80005230:	de043783          	ld	a5,-544(s0)
    80005234:	00fc77b3          	and	a5,s8,a5
    80005238:	ff9d                	bnez	a5,80005176 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000523a:	e1842c83          	lw	s9,-488(s0)
    8000523e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005242:	f60b8ae3          	beqz	s7,800051b6 <exec+0x312>
    80005246:	89de                	mv	s3,s7
    80005248:	4481                	li	s1,0
    8000524a:	b371                	j	80004fd6 <exec+0x132>

000000008000524c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	e84a                	sd	s2,16(sp)
    80005256:	1800                	addi	s0,sp,48
    80005258:	892e                	mv	s2,a1
    8000525a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000525c:	fdc40593          	addi	a1,s0,-36
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	bb4080e7          	jalr	-1100(ra) # 80002e14 <argint>
    80005268:	04054063          	bltz	a0,800052a8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000526c:	fdc42703          	lw	a4,-36(s0)
    80005270:	47bd                	li	a5,15
    80005272:	02e7ed63          	bltu	a5,a4,800052ac <argfd+0x60>
    80005276:	ffffd097          	auipc	ra,0xffffd
    8000527a:	8c0080e7          	jalr	-1856(ra) # 80001b36 <myproc>
    8000527e:	fdc42703          	lw	a4,-36(s0)
    80005282:	01a70793          	addi	a5,a4,26
    80005286:	078e                	slli	a5,a5,0x3
    80005288:	953e                	add	a0,a0,a5
    8000528a:	611c                	ld	a5,0(a0)
    8000528c:	c395                	beqz	a5,800052b0 <argfd+0x64>
    return -1;
  if(pfd)
    8000528e:	00090463          	beqz	s2,80005296 <argfd+0x4a>
    *pfd = fd;
    80005292:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005296:	4501                	li	a0,0
  if(pf)
    80005298:	c091                	beqz	s1,8000529c <argfd+0x50>
    *pf = f;
    8000529a:	e09c                	sd	a5,0(s1)
}
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	64e2                	ld	s1,24(sp)
    800052a2:	6942                	ld	s2,16(sp)
    800052a4:	6145                	addi	sp,sp,48
    800052a6:	8082                	ret
    return -1;
    800052a8:	557d                	li	a0,-1
    800052aa:	bfcd                	j	8000529c <argfd+0x50>
    return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	b7fd                	j	8000529c <argfd+0x50>
    800052b0:	557d                	li	a0,-1
    800052b2:	b7ed                	j	8000529c <argfd+0x50>

00000000800052b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b4:	1101                	addi	sp,sp,-32
    800052b6:	ec06                	sd	ra,24(sp)
    800052b8:	e822                	sd	s0,16(sp)
    800052ba:	e426                	sd	s1,8(sp)
    800052bc:	1000                	addi	s0,sp,32
    800052be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c0:	ffffd097          	auipc	ra,0xffffd
    800052c4:	876080e7          	jalr	-1930(ra) # 80001b36 <myproc>
    800052c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ca:	0d050793          	addi	a5,a0,208
    800052ce:	4501                	li	a0,0
    800052d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052d2:	6398                	ld	a4,0(a5)
    800052d4:	cb19                	beqz	a4,800052ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052d6:	2505                	addiw	a0,a0,1
    800052d8:	07a1                	addi	a5,a5,8
    800052da:	fed51ce3          	bne	a0,a3,800052d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052de:	557d                	li	a0,-1
}
    800052e0:	60e2                	ld	ra,24(sp)
    800052e2:	6442                	ld	s0,16(sp)
    800052e4:	64a2                	ld	s1,8(sp)
    800052e6:	6105                	addi	sp,sp,32
    800052e8:	8082                	ret
      p->ofile[fd] = f;
    800052ea:	01a50793          	addi	a5,a0,26
    800052ee:	078e                	slli	a5,a5,0x3
    800052f0:	963e                	add	a2,a2,a5
    800052f2:	e204                	sd	s1,0(a2)
      return fd;
    800052f4:	b7f5                	j	800052e0 <fdalloc+0x2c>

00000000800052f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052f6:	715d                	addi	sp,sp,-80
    800052f8:	e486                	sd	ra,72(sp)
    800052fa:	e0a2                	sd	s0,64(sp)
    800052fc:	fc26                	sd	s1,56(sp)
    800052fe:	f84a                	sd	s2,48(sp)
    80005300:	f44e                	sd	s3,40(sp)
    80005302:	f052                	sd	s4,32(sp)
    80005304:	ec56                	sd	s5,24(sp)
    80005306:	0880                	addi	s0,sp,80
    80005308:	89ae                	mv	s3,a1
    8000530a:	8ab2                	mv	s5,a2
    8000530c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000530e:	fb040593          	addi	a1,s0,-80
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	e48080e7          	jalr	-440(ra) # 8000415a <nameiparent>
    8000531a:	892a                	mv	s2,a0
    8000531c:	12050e63          	beqz	a0,80005458 <create+0x162>
    return 0;

  ilock(dp);
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	66c080e7          	jalr	1644(ra) # 8000398c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005328:	4601                	li	a2,0
    8000532a:	fb040593          	addi	a1,s0,-80
    8000532e:	854a                	mv	a0,s2
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	b3a080e7          	jalr	-1222(ra) # 80003e6a <dirlookup>
    80005338:	84aa                	mv	s1,a0
    8000533a:	c921                	beqz	a0,8000538a <create+0x94>
    iunlockput(dp);
    8000533c:	854a                	mv	a0,s2
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	8b0080e7          	jalr	-1872(ra) # 80003bee <iunlockput>
    ilock(ip);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	644080e7          	jalr	1604(ra) # 8000398c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005350:	2981                	sext.w	s3,s3
    80005352:	4789                	li	a5,2
    80005354:	02f99463          	bne	s3,a5,8000537c <create+0x86>
    80005358:	0444d783          	lhu	a5,68(s1)
    8000535c:	37f9                	addiw	a5,a5,-2
    8000535e:	17c2                	slli	a5,a5,0x30
    80005360:	93c1                	srli	a5,a5,0x30
    80005362:	4705                	li	a4,1
    80005364:	00f76c63          	bltu	a4,a5,8000537c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005368:	8526                	mv	a0,s1
    8000536a:	60a6                	ld	ra,72(sp)
    8000536c:	6406                	ld	s0,64(sp)
    8000536e:	74e2                	ld	s1,56(sp)
    80005370:	7942                	ld	s2,48(sp)
    80005372:	79a2                	ld	s3,40(sp)
    80005374:	7a02                	ld	s4,32(sp)
    80005376:	6ae2                	ld	s5,24(sp)
    80005378:	6161                	addi	sp,sp,80
    8000537a:	8082                	ret
    iunlockput(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	870080e7          	jalr	-1936(ra) # 80003bee <iunlockput>
    return 0;
    80005386:	4481                	li	s1,0
    80005388:	b7c5                	j	80005368 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000538a:	85ce                	mv	a1,s3
    8000538c:	00092503          	lw	a0,0(s2)
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	464080e7          	jalr	1124(ra) # 800037f4 <ialloc>
    80005398:	84aa                	mv	s1,a0
    8000539a:	c521                	beqz	a0,800053e2 <create+0xec>
  ilock(ip);
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	5f0080e7          	jalr	1520(ra) # 8000398c <ilock>
  ip->major = major;
    800053a4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053a8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053ac:	4a05                	li	s4,1
    800053ae:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	50e080e7          	jalr	1294(ra) # 800038c2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053bc:	2981                	sext.w	s3,s3
    800053be:	03498a63          	beq	s3,s4,800053f2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053c2:	40d0                	lw	a2,4(s1)
    800053c4:	fb040593          	addi	a1,s0,-80
    800053c8:	854a                	mv	a0,s2
    800053ca:	fffff097          	auipc	ra,0xfffff
    800053ce:	cb0080e7          	jalr	-848(ra) # 8000407a <dirlink>
    800053d2:	06054b63          	bltz	a0,80005448 <create+0x152>
  iunlockput(dp);
    800053d6:	854a                	mv	a0,s2
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	816080e7          	jalr	-2026(ra) # 80003bee <iunlockput>
  return ip;
    800053e0:	b761                	j	80005368 <create+0x72>
    panic("create: ialloc");
    800053e2:	00003517          	auipc	a0,0x3
    800053e6:	36e50513          	addi	a0,a0,878 # 80008750 <syscalls+0x2b0>
    800053ea:	ffffb097          	auipc	ra,0xffffb
    800053ee:	156080e7          	jalr	342(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053f2:	04a95783          	lhu	a5,74(s2)
    800053f6:	2785                	addiw	a5,a5,1
    800053f8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053fc:	854a                	mv	a0,s2
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	4c4080e7          	jalr	1220(ra) # 800038c2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005406:	40d0                	lw	a2,4(s1)
    80005408:	00003597          	auipc	a1,0x3
    8000540c:	35858593          	addi	a1,a1,856 # 80008760 <syscalls+0x2c0>
    80005410:	8526                	mv	a0,s1
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	c68080e7          	jalr	-920(ra) # 8000407a <dirlink>
    8000541a:	00054f63          	bltz	a0,80005438 <create+0x142>
    8000541e:	00492603          	lw	a2,4(s2)
    80005422:	00003597          	auipc	a1,0x3
    80005426:	34658593          	addi	a1,a1,838 # 80008768 <syscalls+0x2c8>
    8000542a:	8526                	mv	a0,s1
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	c4e080e7          	jalr	-946(ra) # 8000407a <dirlink>
    80005434:	f80557e3          	bgez	a0,800053c2 <create+0xcc>
      panic("create dots");
    80005438:	00003517          	auipc	a0,0x3
    8000543c:	33850513          	addi	a0,a0,824 # 80008770 <syscalls+0x2d0>
    80005440:	ffffb097          	auipc	ra,0xffffb
    80005444:	100080e7          	jalr	256(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005448:	00003517          	auipc	a0,0x3
    8000544c:	33850513          	addi	a0,a0,824 # 80008780 <syscalls+0x2e0>
    80005450:	ffffb097          	auipc	ra,0xffffb
    80005454:	0f0080e7          	jalr	240(ra) # 80000540 <panic>
    return 0;
    80005458:	84aa                	mv	s1,a0
    8000545a:	b739                	j	80005368 <create+0x72>

000000008000545c <sys_dup>:
{
    8000545c:	7179                	addi	sp,sp,-48
    8000545e:	f406                	sd	ra,40(sp)
    80005460:	f022                	sd	s0,32(sp)
    80005462:	ec26                	sd	s1,24(sp)
    80005464:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005466:	fd840613          	addi	a2,s0,-40
    8000546a:	4581                	li	a1,0
    8000546c:	4501                	li	a0,0
    8000546e:	00000097          	auipc	ra,0x0
    80005472:	dde080e7          	jalr	-546(ra) # 8000524c <argfd>
    return -1;
    80005476:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005478:	02054363          	bltz	a0,8000549e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000547c:	fd843503          	ld	a0,-40(s0)
    80005480:	00000097          	auipc	ra,0x0
    80005484:	e34080e7          	jalr	-460(ra) # 800052b4 <fdalloc>
    80005488:	84aa                	mv	s1,a0
    return -1;
    8000548a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000548c:	00054963          	bltz	a0,8000549e <sys_dup+0x42>
  filedup(f);
    80005490:	fd843503          	ld	a0,-40(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	338080e7          	jalr	824(ra) # 800047cc <filedup>
  return fd;
    8000549c:	87a6                	mv	a5,s1
}
    8000549e:	853e                	mv	a0,a5
    800054a0:	70a2                	ld	ra,40(sp)
    800054a2:	7402                	ld	s0,32(sp)
    800054a4:	64e2                	ld	s1,24(sp)
    800054a6:	6145                	addi	sp,sp,48
    800054a8:	8082                	ret

00000000800054aa <sys_read>:
{
    800054aa:	7179                	addi	sp,sp,-48
    800054ac:	f406                	sd	ra,40(sp)
    800054ae:	f022                	sd	s0,32(sp)
    800054b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b2:	fe840613          	addi	a2,s0,-24
    800054b6:	4581                	li	a1,0
    800054b8:	4501                	li	a0,0
    800054ba:	00000097          	auipc	ra,0x0
    800054be:	d92080e7          	jalr	-622(ra) # 8000524c <argfd>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c4:	04054163          	bltz	a0,80005506 <sys_read+0x5c>
    800054c8:	fe440593          	addi	a1,s0,-28
    800054cc:	4509                	li	a0,2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	946080e7          	jalr	-1722(ra) # 80002e14 <argint>
    return -1;
    800054d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d8:	02054763          	bltz	a0,80005506 <sys_read+0x5c>
    800054dc:	fd840593          	addi	a1,s0,-40
    800054e0:	4505                	li	a0,1
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	954080e7          	jalr	-1708(ra) # 80002e36 <argaddr>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ec:	00054d63          	bltz	a0,80005506 <sys_read+0x5c>
  return fileread(f, p, n);
    800054f0:	fe442603          	lw	a2,-28(s0)
    800054f4:	fd843583          	ld	a1,-40(s0)
    800054f8:	fe843503          	ld	a0,-24(s0)
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	45c080e7          	jalr	1116(ra) # 80004958 <fileread>
    80005504:	87aa                	mv	a5,a0
}
    80005506:	853e                	mv	a0,a5
    80005508:	70a2                	ld	ra,40(sp)
    8000550a:	7402                	ld	s0,32(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret

0000000080005510 <sys_write>:
{
    80005510:	7179                	addi	sp,sp,-48
    80005512:	f406                	sd	ra,40(sp)
    80005514:	f022                	sd	s0,32(sp)
    80005516:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005518:	fe840613          	addi	a2,s0,-24
    8000551c:	4581                	li	a1,0
    8000551e:	4501                	li	a0,0
    80005520:	00000097          	auipc	ra,0x0
    80005524:	d2c080e7          	jalr	-724(ra) # 8000524c <argfd>
    return -1;
    80005528:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552a:	04054163          	bltz	a0,8000556c <sys_write+0x5c>
    8000552e:	fe440593          	addi	a1,s0,-28
    80005532:	4509                	li	a0,2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	8e0080e7          	jalr	-1824(ra) # 80002e14 <argint>
    return -1;
    8000553c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553e:	02054763          	bltz	a0,8000556c <sys_write+0x5c>
    80005542:	fd840593          	addi	a1,s0,-40
    80005546:	4505                	li	a0,1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	8ee080e7          	jalr	-1810(ra) # 80002e36 <argaddr>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005552:	00054d63          	bltz	a0,8000556c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005556:	fe442603          	lw	a2,-28(s0)
    8000555a:	fd843583          	ld	a1,-40(s0)
    8000555e:	fe843503          	ld	a0,-24(s0)
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	4b8080e7          	jalr	1208(ra) # 80004a1a <filewrite>
    8000556a:	87aa                	mv	a5,a0
}
    8000556c:	853e                	mv	a0,a5
    8000556e:	70a2                	ld	ra,40(sp)
    80005570:	7402                	ld	s0,32(sp)
    80005572:	6145                	addi	sp,sp,48
    80005574:	8082                	ret

0000000080005576 <sys_close>:
{
    80005576:	1101                	addi	sp,sp,-32
    80005578:	ec06                	sd	ra,24(sp)
    8000557a:	e822                	sd	s0,16(sp)
    8000557c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000557e:	fe040613          	addi	a2,s0,-32
    80005582:	fec40593          	addi	a1,s0,-20
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	cc4080e7          	jalr	-828(ra) # 8000524c <argfd>
    return -1;
    80005590:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005592:	02054463          	bltz	a0,800055ba <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	5a0080e7          	jalr	1440(ra) # 80001b36 <myproc>
    8000559e:	fec42783          	lw	a5,-20(s0)
    800055a2:	07e9                	addi	a5,a5,26
    800055a4:	078e                	slli	a5,a5,0x3
    800055a6:	97aa                	add	a5,a5,a0
    800055a8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055ac:	fe043503          	ld	a0,-32(s0)
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	26e080e7          	jalr	622(ra) # 8000481e <fileclose>
  return 0;
    800055b8:	4781                	li	a5,0
}
    800055ba:	853e                	mv	a0,a5
    800055bc:	60e2                	ld	ra,24(sp)
    800055be:	6442                	ld	s0,16(sp)
    800055c0:	6105                	addi	sp,sp,32
    800055c2:	8082                	ret

00000000800055c4 <sys_fstat>:
{
    800055c4:	1101                	addi	sp,sp,-32
    800055c6:	ec06                	sd	ra,24(sp)
    800055c8:	e822                	sd	s0,16(sp)
    800055ca:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055cc:	fe840613          	addi	a2,s0,-24
    800055d0:	4581                	li	a1,0
    800055d2:	4501                	li	a0,0
    800055d4:	00000097          	auipc	ra,0x0
    800055d8:	c78080e7          	jalr	-904(ra) # 8000524c <argfd>
    return -1;
    800055dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055de:	02054563          	bltz	a0,80005608 <sys_fstat+0x44>
    800055e2:	fe040593          	addi	a1,s0,-32
    800055e6:	4505                	li	a0,1
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	84e080e7          	jalr	-1970(ra) # 80002e36 <argaddr>
    return -1;
    800055f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055f2:	00054b63          	bltz	a0,80005608 <sys_fstat+0x44>
  return filestat(f, st);
    800055f6:	fe043583          	ld	a1,-32(s0)
    800055fa:	fe843503          	ld	a0,-24(s0)
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	2e8080e7          	jalr	744(ra) # 800048e6 <filestat>
    80005606:	87aa                	mv	a5,a0
}
    80005608:	853e                	mv	a0,a5
    8000560a:	60e2                	ld	ra,24(sp)
    8000560c:	6442                	ld	s0,16(sp)
    8000560e:	6105                	addi	sp,sp,32
    80005610:	8082                	ret

0000000080005612 <sys_link>:
{
    80005612:	7169                	addi	sp,sp,-304
    80005614:	f606                	sd	ra,296(sp)
    80005616:	f222                	sd	s0,288(sp)
    80005618:	ee26                	sd	s1,280(sp)
    8000561a:	ea4a                	sd	s2,272(sp)
    8000561c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000561e:	08000613          	li	a2,128
    80005622:	ed040593          	addi	a1,s0,-304
    80005626:	4501                	li	a0,0
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	830080e7          	jalr	-2000(ra) # 80002e58 <argstr>
    return -1;
    80005630:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005632:	10054e63          	bltz	a0,8000574e <sys_link+0x13c>
    80005636:	08000613          	li	a2,128
    8000563a:	f5040593          	addi	a1,s0,-176
    8000563e:	4505                	li	a0,1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	818080e7          	jalr	-2024(ra) # 80002e58 <argstr>
    return -1;
    80005648:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000564a:	10054263          	bltz	a0,8000574e <sys_link+0x13c>
  begin_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	cfe080e7          	jalr	-770(ra) # 8000434c <begin_op>
  if((ip = namei(old)) == 0){
    80005656:	ed040513          	addi	a0,s0,-304
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	ae2080e7          	jalr	-1310(ra) # 8000413c <namei>
    80005662:	84aa                	mv	s1,a0
    80005664:	c551                	beqz	a0,800056f0 <sys_link+0xde>
  ilock(ip);
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	326080e7          	jalr	806(ra) # 8000398c <ilock>
  if(ip->type == T_DIR){
    8000566e:	04449703          	lh	a4,68(s1)
    80005672:	4785                	li	a5,1
    80005674:	08f70463          	beq	a4,a5,800056fc <sys_link+0xea>
  ip->nlink++;
    80005678:	04a4d783          	lhu	a5,74(s1)
    8000567c:	2785                	addiw	a5,a5,1
    8000567e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	23e080e7          	jalr	574(ra) # 800038c2 <iupdate>
  iunlock(ip);
    8000568c:	8526                	mv	a0,s1
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	3c0080e7          	jalr	960(ra) # 80003a4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005696:	fd040593          	addi	a1,s0,-48
    8000569a:	f5040513          	addi	a0,s0,-176
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	abc080e7          	jalr	-1348(ra) # 8000415a <nameiparent>
    800056a6:	892a                	mv	s2,a0
    800056a8:	c935                	beqz	a0,8000571c <sys_link+0x10a>
  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	2e2080e7          	jalr	738(ra) # 8000398c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056b2:	00092703          	lw	a4,0(s2)
    800056b6:	409c                	lw	a5,0(s1)
    800056b8:	04f71d63          	bne	a4,a5,80005712 <sys_link+0x100>
    800056bc:	40d0                	lw	a2,4(s1)
    800056be:	fd040593          	addi	a1,s0,-48
    800056c2:	854a                	mv	a0,s2
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	9b6080e7          	jalr	-1610(ra) # 8000407a <dirlink>
    800056cc:	04054363          	bltz	a0,80005712 <sys_link+0x100>
  iunlockput(dp);
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	51c080e7          	jalr	1308(ra) # 80003bee <iunlockput>
  iput(ip);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	46a080e7          	jalr	1130(ra) # 80003b46 <iput>
  end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	ce8080e7          	jalr	-792(ra) # 800043cc <end_op>
  return 0;
    800056ec:	4781                	li	a5,0
    800056ee:	a085                	j	8000574e <sys_link+0x13c>
    end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	cdc080e7          	jalr	-804(ra) # 800043cc <end_op>
    return -1;
    800056f8:	57fd                	li	a5,-1
    800056fa:	a891                	j	8000574e <sys_link+0x13c>
    iunlockput(ip);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	4f0080e7          	jalr	1264(ra) # 80003bee <iunlockput>
    end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	cc6080e7          	jalr	-826(ra) # 800043cc <end_op>
    return -1;
    8000570e:	57fd                	li	a5,-1
    80005710:	a83d                	j	8000574e <sys_link+0x13c>
    iunlockput(dp);
    80005712:	854a                	mv	a0,s2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	4da080e7          	jalr	1242(ra) # 80003bee <iunlockput>
  ilock(ip);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	26e080e7          	jalr	622(ra) # 8000398c <ilock>
  ip->nlink--;
    80005726:	04a4d783          	lhu	a5,74(s1)
    8000572a:	37fd                	addiw	a5,a5,-1
    8000572c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	190080e7          	jalr	400(ra) # 800038c2 <iupdate>
  iunlockput(ip);
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	4b2080e7          	jalr	1202(ra) # 80003bee <iunlockput>
  end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	c88080e7          	jalr	-888(ra) # 800043cc <end_op>
  return -1;
    8000574c:	57fd                	li	a5,-1
}
    8000574e:	853e                	mv	a0,a5
    80005750:	70b2                	ld	ra,296(sp)
    80005752:	7412                	ld	s0,288(sp)
    80005754:	64f2                	ld	s1,280(sp)
    80005756:	6952                	ld	s2,272(sp)
    80005758:	6155                	addi	sp,sp,304
    8000575a:	8082                	ret

000000008000575c <sys_unlink>:
{
    8000575c:	7151                	addi	sp,sp,-240
    8000575e:	f586                	sd	ra,232(sp)
    80005760:	f1a2                	sd	s0,224(sp)
    80005762:	eda6                	sd	s1,216(sp)
    80005764:	e9ca                	sd	s2,208(sp)
    80005766:	e5ce                	sd	s3,200(sp)
    80005768:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000576a:	08000613          	li	a2,128
    8000576e:	f3040593          	addi	a1,s0,-208
    80005772:	4501                	li	a0,0
    80005774:	ffffd097          	auipc	ra,0xffffd
    80005778:	6e4080e7          	jalr	1764(ra) # 80002e58 <argstr>
    8000577c:	18054163          	bltz	a0,800058fe <sys_unlink+0x1a2>
  begin_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	bcc080e7          	jalr	-1076(ra) # 8000434c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005788:	fb040593          	addi	a1,s0,-80
    8000578c:	f3040513          	addi	a0,s0,-208
    80005790:	fffff097          	auipc	ra,0xfffff
    80005794:	9ca080e7          	jalr	-1590(ra) # 8000415a <nameiparent>
    80005798:	84aa                	mv	s1,a0
    8000579a:	c979                	beqz	a0,80005870 <sys_unlink+0x114>
  ilock(dp);
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	1f0080e7          	jalr	496(ra) # 8000398c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057a4:	00003597          	auipc	a1,0x3
    800057a8:	fbc58593          	addi	a1,a1,-68 # 80008760 <syscalls+0x2c0>
    800057ac:	fb040513          	addi	a0,s0,-80
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	6a0080e7          	jalr	1696(ra) # 80003e50 <namecmp>
    800057b8:	14050a63          	beqz	a0,8000590c <sys_unlink+0x1b0>
    800057bc:	00003597          	auipc	a1,0x3
    800057c0:	fac58593          	addi	a1,a1,-84 # 80008768 <syscalls+0x2c8>
    800057c4:	fb040513          	addi	a0,s0,-80
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	688080e7          	jalr	1672(ra) # 80003e50 <namecmp>
    800057d0:	12050e63          	beqz	a0,8000590c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057d4:	f2c40613          	addi	a2,s0,-212
    800057d8:	fb040593          	addi	a1,s0,-80
    800057dc:	8526                	mv	a0,s1
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	68c080e7          	jalr	1676(ra) # 80003e6a <dirlookup>
    800057e6:	892a                	mv	s2,a0
    800057e8:	12050263          	beqz	a0,8000590c <sys_unlink+0x1b0>
  ilock(ip);
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	1a0080e7          	jalr	416(ra) # 8000398c <ilock>
  if(ip->nlink < 1)
    800057f4:	04a91783          	lh	a5,74(s2)
    800057f8:	08f05263          	blez	a5,8000587c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057fc:	04491703          	lh	a4,68(s2)
    80005800:	4785                	li	a5,1
    80005802:	08f70563          	beq	a4,a5,8000588c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005806:	4641                	li	a2,16
    80005808:	4581                	li	a1,0
    8000580a:	fc040513          	addi	a0,s0,-64
    8000580e:	ffffb097          	auipc	ra,0xffffb
    80005812:	4ea080e7          	jalr	1258(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005816:	4741                	li	a4,16
    80005818:	f2c42683          	lw	a3,-212(s0)
    8000581c:	fc040613          	addi	a2,s0,-64
    80005820:	4581                	li	a1,0
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	512080e7          	jalr	1298(ra) # 80003d36 <writei>
    8000582c:	47c1                	li	a5,16
    8000582e:	0af51563          	bne	a0,a5,800058d8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005832:	04491703          	lh	a4,68(s2)
    80005836:	4785                	li	a5,1
    80005838:	0af70863          	beq	a4,a5,800058e8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	3b0080e7          	jalr	944(ra) # 80003bee <iunlockput>
  ip->nlink--;
    80005846:	04a95783          	lhu	a5,74(s2)
    8000584a:	37fd                	addiw	a5,a5,-1
    8000584c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	070080e7          	jalr	112(ra) # 800038c2 <iupdate>
  iunlockput(ip);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	392080e7          	jalr	914(ra) # 80003bee <iunlockput>
  end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	b68080e7          	jalr	-1176(ra) # 800043cc <end_op>
  return 0;
    8000586c:	4501                	li	a0,0
    8000586e:	a84d                	j	80005920 <sys_unlink+0x1c4>
    end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	b5c080e7          	jalr	-1188(ra) # 800043cc <end_op>
    return -1;
    80005878:	557d                	li	a0,-1
    8000587a:	a05d                	j	80005920 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000587c:	00003517          	auipc	a0,0x3
    80005880:	f1450513          	addi	a0,a0,-236 # 80008790 <syscalls+0x2f0>
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	cbc080e7          	jalr	-836(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000588c:	04c92703          	lw	a4,76(s2)
    80005890:	02000793          	li	a5,32
    80005894:	f6e7f9e3          	bgeu	a5,a4,80005806 <sys_unlink+0xaa>
    80005898:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000589c:	4741                	li	a4,16
    8000589e:	86ce                	mv	a3,s3
    800058a0:	f1840613          	addi	a2,s0,-232
    800058a4:	4581                	li	a1,0
    800058a6:	854a                	mv	a0,s2
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	398080e7          	jalr	920(ra) # 80003c40 <readi>
    800058b0:	47c1                	li	a5,16
    800058b2:	00f51b63          	bne	a0,a5,800058c8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058b6:	f1845783          	lhu	a5,-232(s0)
    800058ba:	e7a1                	bnez	a5,80005902 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058bc:	29c1                	addiw	s3,s3,16
    800058be:	04c92783          	lw	a5,76(s2)
    800058c2:	fcf9ede3          	bltu	s3,a5,8000589c <sys_unlink+0x140>
    800058c6:	b781                	j	80005806 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058c8:	00003517          	auipc	a0,0x3
    800058cc:	ee050513          	addi	a0,a0,-288 # 800087a8 <syscalls+0x308>
    800058d0:	ffffb097          	auipc	ra,0xffffb
    800058d4:	c70080e7          	jalr	-912(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058d8:	00003517          	auipc	a0,0x3
    800058dc:	ee850513          	addi	a0,a0,-280 # 800087c0 <syscalls+0x320>
    800058e0:	ffffb097          	auipc	ra,0xffffb
    800058e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
    dp->nlink--;
    800058e8:	04a4d783          	lhu	a5,74(s1)
    800058ec:	37fd                	addiw	a5,a5,-1
    800058ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	fce080e7          	jalr	-50(ra) # 800038c2 <iupdate>
    800058fc:	b781                	j	8000583c <sys_unlink+0xe0>
    return -1;
    800058fe:	557d                	li	a0,-1
    80005900:	a005                	j	80005920 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	2ea080e7          	jalr	746(ra) # 80003bee <iunlockput>
  iunlockput(dp);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	2e0080e7          	jalr	736(ra) # 80003bee <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	ab6080e7          	jalr	-1354(ra) # 800043cc <end_op>
  return -1;
    8000591e:	557d                	li	a0,-1
}
    80005920:	70ae                	ld	ra,232(sp)
    80005922:	740e                	ld	s0,224(sp)
    80005924:	64ee                	ld	s1,216(sp)
    80005926:	694e                	ld	s2,208(sp)
    80005928:	69ae                	ld	s3,200(sp)
    8000592a:	616d                	addi	sp,sp,240
    8000592c:	8082                	ret

000000008000592e <sys_open>:

uint64
sys_open(void)
{
    8000592e:	7131                	addi	sp,sp,-192
    80005930:	fd06                	sd	ra,184(sp)
    80005932:	f922                	sd	s0,176(sp)
    80005934:	f526                	sd	s1,168(sp)
    80005936:	f14a                	sd	s2,160(sp)
    80005938:	ed4e                	sd	s3,152(sp)
    8000593a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000593c:	08000613          	li	a2,128
    80005940:	f5040593          	addi	a1,s0,-176
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	512080e7          	jalr	1298(ra) # 80002e58 <argstr>
    return -1;
    8000594e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005950:	0c054163          	bltz	a0,80005a12 <sys_open+0xe4>
    80005954:	f4c40593          	addi	a1,s0,-180
    80005958:	4505                	li	a0,1
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	4ba080e7          	jalr	1210(ra) # 80002e14 <argint>
    80005962:	0a054863          	bltz	a0,80005a12 <sys_open+0xe4>

  begin_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	9e6080e7          	jalr	-1562(ra) # 8000434c <begin_op>

  if(omode & O_CREATE){
    8000596e:	f4c42783          	lw	a5,-180(s0)
    80005972:	2007f793          	andi	a5,a5,512
    80005976:	cbdd                	beqz	a5,80005a2c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005978:	4681                	li	a3,0
    8000597a:	4601                	li	a2,0
    8000597c:	4589                	li	a1,2
    8000597e:	f5040513          	addi	a0,s0,-176
    80005982:	00000097          	auipc	ra,0x0
    80005986:	974080e7          	jalr	-1676(ra) # 800052f6 <create>
    8000598a:	892a                	mv	s2,a0
    if(ip == 0){
    8000598c:	c959                	beqz	a0,80005a22 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000598e:	04491703          	lh	a4,68(s2)
    80005992:	478d                	li	a5,3
    80005994:	00f71763          	bne	a4,a5,800059a2 <sys_open+0x74>
    80005998:	04695703          	lhu	a4,70(s2)
    8000599c:	47a5                	li	a5,9
    8000599e:	0ce7ec63          	bltu	a5,a4,80005a76 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	dc0080e7          	jalr	-576(ra) # 80004762 <filealloc>
    800059aa:	89aa                	mv	s3,a0
    800059ac:	10050263          	beqz	a0,80005ab0 <sys_open+0x182>
    800059b0:	00000097          	auipc	ra,0x0
    800059b4:	904080e7          	jalr	-1788(ra) # 800052b4 <fdalloc>
    800059b8:	84aa                	mv	s1,a0
    800059ba:	0e054663          	bltz	a0,80005aa6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059be:	04491703          	lh	a4,68(s2)
    800059c2:	478d                	li	a5,3
    800059c4:	0cf70463          	beq	a4,a5,80005a8c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059c8:	4789                	li	a5,2
    800059ca:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059ce:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059d2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059d6:	f4c42783          	lw	a5,-180(s0)
    800059da:	0017c713          	xori	a4,a5,1
    800059de:	8b05                	andi	a4,a4,1
    800059e0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059e4:	0037f713          	andi	a4,a5,3
    800059e8:	00e03733          	snez	a4,a4
    800059ec:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059f0:	4007f793          	andi	a5,a5,1024
    800059f4:	c791                	beqz	a5,80005a00 <sys_open+0xd2>
    800059f6:	04491703          	lh	a4,68(s2)
    800059fa:	4789                	li	a5,2
    800059fc:	08f70f63          	beq	a4,a5,80005a9a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	04c080e7          	jalr	76(ra) # 80003a4e <iunlock>
  end_op();
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	9c2080e7          	jalr	-1598(ra) # 800043cc <end_op>

  return fd;
}
    80005a12:	8526                	mv	a0,s1
    80005a14:	70ea                	ld	ra,184(sp)
    80005a16:	744a                	ld	s0,176(sp)
    80005a18:	74aa                	ld	s1,168(sp)
    80005a1a:	790a                	ld	s2,160(sp)
    80005a1c:	69ea                	ld	s3,152(sp)
    80005a1e:	6129                	addi	sp,sp,192
    80005a20:	8082                	ret
      end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	9aa080e7          	jalr	-1622(ra) # 800043cc <end_op>
      return -1;
    80005a2a:	b7e5                	j	80005a12 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a2c:	f5040513          	addi	a0,s0,-176
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	70c080e7          	jalr	1804(ra) # 8000413c <namei>
    80005a38:	892a                	mv	s2,a0
    80005a3a:	c905                	beqz	a0,80005a6a <sys_open+0x13c>
    ilock(ip);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	f50080e7          	jalr	-176(ra) # 8000398c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a44:	04491703          	lh	a4,68(s2)
    80005a48:	4785                	li	a5,1
    80005a4a:	f4f712e3          	bne	a4,a5,8000598e <sys_open+0x60>
    80005a4e:	f4c42783          	lw	a5,-180(s0)
    80005a52:	dba1                	beqz	a5,800059a2 <sys_open+0x74>
      iunlockput(ip);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	198080e7          	jalr	408(ra) # 80003bee <iunlockput>
      end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	96e080e7          	jalr	-1682(ra) # 800043cc <end_op>
      return -1;
    80005a66:	54fd                	li	s1,-1
    80005a68:	b76d                	j	80005a12 <sys_open+0xe4>
      end_op();
    80005a6a:	fffff097          	auipc	ra,0xfffff
    80005a6e:	962080e7          	jalr	-1694(ra) # 800043cc <end_op>
      return -1;
    80005a72:	54fd                	li	s1,-1
    80005a74:	bf79                	j	80005a12 <sys_open+0xe4>
    iunlockput(ip);
    80005a76:	854a                	mv	a0,s2
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	176080e7          	jalr	374(ra) # 80003bee <iunlockput>
    end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	94c080e7          	jalr	-1716(ra) # 800043cc <end_op>
    return -1;
    80005a88:	54fd                	li	s1,-1
    80005a8a:	b761                	j	80005a12 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a8c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a90:	04691783          	lh	a5,70(s2)
    80005a94:	02f99223          	sh	a5,36(s3)
    80005a98:	bf2d                	j	800059d2 <sys_open+0xa4>
    itrunc(ip);
    80005a9a:	854a                	mv	a0,s2
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	ffe080e7          	jalr	-2(ra) # 80003a9a <itrunc>
    80005aa4:	bfb1                	j	80005a00 <sys_open+0xd2>
      fileclose(f);
    80005aa6:	854e                	mv	a0,s3
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	d76080e7          	jalr	-650(ra) # 8000481e <fileclose>
    iunlockput(ip);
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	13c080e7          	jalr	316(ra) # 80003bee <iunlockput>
    end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	912080e7          	jalr	-1774(ra) # 800043cc <end_op>
    return -1;
    80005ac2:	54fd                	li	s1,-1
    80005ac4:	b7b9                	j	80005a12 <sys_open+0xe4>

0000000080005ac6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ac6:	7175                	addi	sp,sp,-144
    80005ac8:	e506                	sd	ra,136(sp)
    80005aca:	e122                	sd	s0,128(sp)
    80005acc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	87e080e7          	jalr	-1922(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ad6:	08000613          	li	a2,128
    80005ada:	f7040593          	addi	a1,s0,-144
    80005ade:	4501                	li	a0,0
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	378080e7          	jalr	888(ra) # 80002e58 <argstr>
    80005ae8:	02054963          	bltz	a0,80005b1a <sys_mkdir+0x54>
    80005aec:	4681                	li	a3,0
    80005aee:	4601                	li	a2,0
    80005af0:	4585                	li	a1,1
    80005af2:	f7040513          	addi	a0,s0,-144
    80005af6:	00000097          	auipc	ra,0x0
    80005afa:	800080e7          	jalr	-2048(ra) # 800052f6 <create>
    80005afe:	cd11                	beqz	a0,80005b1a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	0ee080e7          	jalr	238(ra) # 80003bee <iunlockput>
  end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	8c4080e7          	jalr	-1852(ra) # 800043cc <end_op>
  return 0;
    80005b10:	4501                	li	a0,0
}
    80005b12:	60aa                	ld	ra,136(sp)
    80005b14:	640a                	ld	s0,128(sp)
    80005b16:	6149                	addi	sp,sp,144
    80005b18:	8082                	ret
    end_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	8b2080e7          	jalr	-1870(ra) # 800043cc <end_op>
    return -1;
    80005b22:	557d                	li	a0,-1
    80005b24:	b7fd                	j	80005b12 <sys_mkdir+0x4c>

0000000080005b26 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b26:	7135                	addi	sp,sp,-160
    80005b28:	ed06                	sd	ra,152(sp)
    80005b2a:	e922                	sd	s0,144(sp)
    80005b2c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	81e080e7          	jalr	-2018(ra) # 8000434c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b36:	08000613          	li	a2,128
    80005b3a:	f7040593          	addi	a1,s0,-144
    80005b3e:	4501                	li	a0,0
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	318080e7          	jalr	792(ra) # 80002e58 <argstr>
    80005b48:	04054a63          	bltz	a0,80005b9c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b4c:	f6c40593          	addi	a1,s0,-148
    80005b50:	4505                	li	a0,1
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	2c2080e7          	jalr	706(ra) # 80002e14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b5a:	04054163          	bltz	a0,80005b9c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b5e:	f6840593          	addi	a1,s0,-152
    80005b62:	4509                	li	a0,2
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	2b0080e7          	jalr	688(ra) # 80002e14 <argint>
     argint(1, &major) < 0 ||
    80005b6c:	02054863          	bltz	a0,80005b9c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b70:	f6841683          	lh	a3,-152(s0)
    80005b74:	f6c41603          	lh	a2,-148(s0)
    80005b78:	458d                	li	a1,3
    80005b7a:	f7040513          	addi	a0,s0,-144
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	778080e7          	jalr	1912(ra) # 800052f6 <create>
     argint(2, &minor) < 0 ||
    80005b86:	c919                	beqz	a0,80005b9c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	066080e7          	jalr	102(ra) # 80003bee <iunlockput>
  end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	83c080e7          	jalr	-1988(ra) # 800043cc <end_op>
  return 0;
    80005b98:	4501                	li	a0,0
    80005b9a:	a031                	j	80005ba6 <sys_mknod+0x80>
    end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	830080e7          	jalr	-2000(ra) # 800043cc <end_op>
    return -1;
    80005ba4:	557d                	li	a0,-1
}
    80005ba6:	60ea                	ld	ra,152(sp)
    80005ba8:	644a                	ld	s0,144(sp)
    80005baa:	610d                	addi	sp,sp,160
    80005bac:	8082                	ret

0000000080005bae <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bae:	7135                	addi	sp,sp,-160
    80005bb0:	ed06                	sd	ra,152(sp)
    80005bb2:	e922                	sd	s0,144(sp)
    80005bb4:	e526                	sd	s1,136(sp)
    80005bb6:	e14a                	sd	s2,128(sp)
    80005bb8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bba:	ffffc097          	auipc	ra,0xffffc
    80005bbe:	f7c080e7          	jalr	-132(ra) # 80001b36 <myproc>
    80005bc2:	892a                	mv	s2,a0
  
  begin_op();
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	788080e7          	jalr	1928(ra) # 8000434c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bcc:	08000613          	li	a2,128
    80005bd0:	f6040593          	addi	a1,s0,-160
    80005bd4:	4501                	li	a0,0
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	282080e7          	jalr	642(ra) # 80002e58 <argstr>
    80005bde:	04054b63          	bltz	a0,80005c34 <sys_chdir+0x86>
    80005be2:	f6040513          	addi	a0,s0,-160
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	556080e7          	jalr	1366(ra) # 8000413c <namei>
    80005bee:	84aa                	mv	s1,a0
    80005bf0:	c131                	beqz	a0,80005c34 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	d9a080e7          	jalr	-614(ra) # 8000398c <ilock>
  if(ip->type != T_DIR){
    80005bfa:	04449703          	lh	a4,68(s1)
    80005bfe:	4785                	li	a5,1
    80005c00:	04f71063          	bne	a4,a5,80005c40 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c04:	8526                	mv	a0,s1
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	e48080e7          	jalr	-440(ra) # 80003a4e <iunlock>
  iput(p->cwd);
    80005c0e:	15093503          	ld	a0,336(s2)
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	f34080e7          	jalr	-204(ra) # 80003b46 <iput>
  end_op();
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	7b2080e7          	jalr	1970(ra) # 800043cc <end_op>
  p->cwd = ip;
    80005c22:	14993823          	sd	s1,336(s2)
  return 0;
    80005c26:	4501                	li	a0,0
}
    80005c28:	60ea                	ld	ra,152(sp)
    80005c2a:	644a                	ld	s0,144(sp)
    80005c2c:	64aa                	ld	s1,136(sp)
    80005c2e:	690a                	ld	s2,128(sp)
    80005c30:	610d                	addi	sp,sp,160
    80005c32:	8082                	ret
    end_op();
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	798080e7          	jalr	1944(ra) # 800043cc <end_op>
    return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	b7ed                	j	80005c28 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	fac080e7          	jalr	-84(ra) # 80003bee <iunlockput>
    end_op();
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	782080e7          	jalr	1922(ra) # 800043cc <end_op>
    return -1;
    80005c52:	557d                	li	a0,-1
    80005c54:	bfd1                	j	80005c28 <sys_chdir+0x7a>

0000000080005c56 <sys_exec>:

uint64
sys_exec(void)
{
    80005c56:	7145                	addi	sp,sp,-464
    80005c58:	e786                	sd	ra,456(sp)
    80005c5a:	e3a2                	sd	s0,448(sp)
    80005c5c:	ff26                	sd	s1,440(sp)
    80005c5e:	fb4a                	sd	s2,432(sp)
    80005c60:	f74e                	sd	s3,424(sp)
    80005c62:	f352                	sd	s4,416(sp)
    80005c64:	ef56                	sd	s5,408(sp)
    80005c66:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c68:	08000613          	li	a2,128
    80005c6c:	f4040593          	addi	a1,s0,-192
    80005c70:	4501                	li	a0,0
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	1e6080e7          	jalr	486(ra) # 80002e58 <argstr>
    return -1;
    80005c7a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c7c:	0c054a63          	bltz	a0,80005d50 <sys_exec+0xfa>
    80005c80:	e3840593          	addi	a1,s0,-456
    80005c84:	4505                	li	a0,1
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	1b0080e7          	jalr	432(ra) # 80002e36 <argaddr>
    80005c8e:	0c054163          	bltz	a0,80005d50 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c92:	10000613          	li	a2,256
    80005c96:	4581                	li	a1,0
    80005c98:	e4040513          	addi	a0,s0,-448
    80005c9c:	ffffb097          	auipc	ra,0xffffb
    80005ca0:	05c080e7          	jalr	92(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ca4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ca8:	89a6                	mv	s3,s1
    80005caa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cac:	02000a13          	li	s4,32
    80005cb0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cb4:	00391793          	slli	a5,s2,0x3
    80005cb8:	e3040593          	addi	a1,s0,-464
    80005cbc:	e3843503          	ld	a0,-456(s0)
    80005cc0:	953e                	add	a0,a0,a5
    80005cc2:	ffffd097          	auipc	ra,0xffffd
    80005cc6:	0b8080e7          	jalr	184(ra) # 80002d7a <fetchaddr>
    80005cca:	02054a63          	bltz	a0,80005cfe <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cce:	e3043783          	ld	a5,-464(s0)
    80005cd2:	c3b9                	beqz	a5,80005d18 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cd4:	ffffb097          	auipc	ra,0xffffb
    80005cd8:	e38080e7          	jalr	-456(ra) # 80000b0c <kalloc>
    80005cdc:	85aa                	mv	a1,a0
    80005cde:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ce2:	cd11                	beqz	a0,80005cfe <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ce4:	6605                	lui	a2,0x1
    80005ce6:	e3043503          	ld	a0,-464(s0)
    80005cea:	ffffd097          	auipc	ra,0xffffd
    80005cee:	0e2080e7          	jalr	226(ra) # 80002dcc <fetchstr>
    80005cf2:	00054663          	bltz	a0,80005cfe <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cf6:	0905                	addi	s2,s2,1
    80005cf8:	09a1                	addi	s3,s3,8
    80005cfa:	fb491be3          	bne	s2,s4,80005cb0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfe:	10048913          	addi	s2,s1,256
    80005d02:	6088                	ld	a0,0(s1)
    80005d04:	c529                	beqz	a0,80005d4e <sys_exec+0xf8>
    kfree(argv[i]);
    80005d06:	ffffb097          	auipc	ra,0xffffb
    80005d0a:	d0a080e7          	jalr	-758(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0e:	04a1                	addi	s1,s1,8
    80005d10:	ff2499e3          	bne	s1,s2,80005d02 <sys_exec+0xac>
  return -1;
    80005d14:	597d                	li	s2,-1
    80005d16:	a82d                	j	80005d50 <sys_exec+0xfa>
      argv[i] = 0;
    80005d18:	0a8e                	slli	s5,s5,0x3
    80005d1a:	fc040793          	addi	a5,s0,-64
    80005d1e:	9abe                	add	s5,s5,a5
    80005d20:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005d24:	e4040593          	addi	a1,s0,-448
    80005d28:	f4040513          	addi	a0,s0,-192
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	178080e7          	jalr	376(ra) # 80004ea4 <exec>
    80005d34:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d36:	10048993          	addi	s3,s1,256
    80005d3a:	6088                	ld	a0,0(s1)
    80005d3c:	c911                	beqz	a0,80005d50 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d3e:	ffffb097          	auipc	ra,0xffffb
    80005d42:	cd2080e7          	jalr	-814(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d46:	04a1                	addi	s1,s1,8
    80005d48:	ff3499e3          	bne	s1,s3,80005d3a <sys_exec+0xe4>
    80005d4c:	a011                	j	80005d50 <sys_exec+0xfa>
  return -1;
    80005d4e:	597d                	li	s2,-1
}
    80005d50:	854a                	mv	a0,s2
    80005d52:	60be                	ld	ra,456(sp)
    80005d54:	641e                	ld	s0,448(sp)
    80005d56:	74fa                	ld	s1,440(sp)
    80005d58:	795a                	ld	s2,432(sp)
    80005d5a:	79ba                	ld	s3,424(sp)
    80005d5c:	7a1a                	ld	s4,416(sp)
    80005d5e:	6afa                	ld	s5,408(sp)
    80005d60:	6179                	addi	sp,sp,464
    80005d62:	8082                	ret

0000000080005d64 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d64:	7139                	addi	sp,sp,-64
    80005d66:	fc06                	sd	ra,56(sp)
    80005d68:	f822                	sd	s0,48(sp)
    80005d6a:	f426                	sd	s1,40(sp)
    80005d6c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d6e:	ffffc097          	auipc	ra,0xffffc
    80005d72:	dc8080e7          	jalr	-568(ra) # 80001b36 <myproc>
    80005d76:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d78:	fd840593          	addi	a1,s0,-40
    80005d7c:	4501                	li	a0,0
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	0b8080e7          	jalr	184(ra) # 80002e36 <argaddr>
    return -1;
    80005d86:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d88:	0e054063          	bltz	a0,80005e68 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d8c:	fc840593          	addi	a1,s0,-56
    80005d90:	fd040513          	addi	a0,s0,-48
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	de0080e7          	jalr	-544(ra) # 80004b74 <pipealloc>
    return -1;
    80005d9c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d9e:	0c054563          	bltz	a0,80005e68 <sys_pipe+0x104>
  fd0 = -1;
    80005da2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005da6:	fd043503          	ld	a0,-48(s0)
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	50a080e7          	jalr	1290(ra) # 800052b4 <fdalloc>
    80005db2:	fca42223          	sw	a0,-60(s0)
    80005db6:	08054c63          	bltz	a0,80005e4e <sys_pipe+0xea>
    80005dba:	fc843503          	ld	a0,-56(s0)
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	4f6080e7          	jalr	1270(ra) # 800052b4 <fdalloc>
    80005dc6:	fca42023          	sw	a0,-64(s0)
    80005dca:	06054863          	bltz	a0,80005e3a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dce:	4691                	li	a3,4
    80005dd0:	fc440613          	addi	a2,s0,-60
    80005dd4:	fd843583          	ld	a1,-40(s0)
    80005dd8:	68a8                	ld	a0,80(s1)
    80005dda:	ffffc097          	auipc	ra,0xffffc
    80005dde:	8d0080e7          	jalr	-1840(ra) # 800016aa <copyout>
    80005de2:	02054063          	bltz	a0,80005e02 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005de6:	4691                	li	a3,4
    80005de8:	fc040613          	addi	a2,s0,-64
    80005dec:	fd843583          	ld	a1,-40(s0)
    80005df0:	0591                	addi	a1,a1,4
    80005df2:	68a8                	ld	a0,80(s1)
    80005df4:	ffffc097          	auipc	ra,0xffffc
    80005df8:	8b6080e7          	jalr	-1866(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dfc:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dfe:	06055563          	bgez	a0,80005e68 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e02:	fc442783          	lw	a5,-60(s0)
    80005e06:	07e9                	addi	a5,a5,26
    80005e08:	078e                	slli	a5,a5,0x3
    80005e0a:	97a6                	add	a5,a5,s1
    80005e0c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e10:	fc042503          	lw	a0,-64(s0)
    80005e14:	0569                	addi	a0,a0,26
    80005e16:	050e                	slli	a0,a0,0x3
    80005e18:	9526                	add	a0,a0,s1
    80005e1a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e1e:	fd043503          	ld	a0,-48(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	9fc080e7          	jalr	-1540(ra) # 8000481e <fileclose>
    fileclose(wf);
    80005e2a:	fc843503          	ld	a0,-56(s0)
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	9f0080e7          	jalr	-1552(ra) # 8000481e <fileclose>
    return -1;
    80005e36:	57fd                	li	a5,-1
    80005e38:	a805                	j	80005e68 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e3a:	fc442783          	lw	a5,-60(s0)
    80005e3e:	0007c863          	bltz	a5,80005e4e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e42:	01a78513          	addi	a0,a5,26
    80005e46:	050e                	slli	a0,a0,0x3
    80005e48:	9526                	add	a0,a0,s1
    80005e4a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e4e:	fd043503          	ld	a0,-48(s0)
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	9cc080e7          	jalr	-1588(ra) # 8000481e <fileclose>
    fileclose(wf);
    80005e5a:	fc843503          	ld	a0,-56(s0)
    80005e5e:	fffff097          	auipc	ra,0xfffff
    80005e62:	9c0080e7          	jalr	-1600(ra) # 8000481e <fileclose>
    return -1;
    80005e66:	57fd                	li	a5,-1
}
    80005e68:	853e                	mv	a0,a5
    80005e6a:	70e2                	ld	ra,56(sp)
    80005e6c:	7442                	ld	s0,48(sp)
    80005e6e:	74a2                	ld	s1,40(sp)
    80005e70:	6121                	addi	sp,sp,64
    80005e72:	8082                	ret
	...

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	d6ffc0ef          	jal	ra,80002c2e <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	710c                	ld	a1,32(a0)
    80005f1c:	7510                	ld	a2,40(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	bb2080e7          	jalr	-1102(ra) # 80001b0a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	953e                	add	a0,a0,a5
    80005f7c:	00052023          	sw	zero,0(a0)
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e406                	sd	ra,8(sp)
    80005f8c:	e022                	sd	s0,0(sp)
    80005f8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f90:	ffffc097          	auipc	ra,0xffffc
    80005f94:	b7a080e7          	jalr	-1158(ra) # 80001b0a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f98:	00d5179b          	slliw	a5,a0,0xd
    80005f9c:	0c201537          	lui	a0,0xc201
    80005fa0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fa2:	4148                	lw	a0,4(a0)
    80005fa4:	60a2                	ld	ra,8(sp)
    80005fa6:	6402                	ld	s0,0(sp)
    80005fa8:	0141                	addi	sp,sp,16
    80005faa:	8082                	ret

0000000080005fac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fac:	1101                	addi	sp,sp,-32
    80005fae:	ec06                	sd	ra,24(sp)
    80005fb0:	e822                	sd	s0,16(sp)
    80005fb2:	e426                	sd	s1,8(sp)
    80005fb4:	1000                	addi	s0,sp,32
    80005fb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	b52080e7          	jalr	-1198(ra) # 80001b0a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fc0:	00d5151b          	slliw	a0,a0,0xd
    80005fc4:	0c2017b7          	lui	a5,0xc201
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	c3c4                	sw	s1,4(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret

0000000080005fd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fd6:	1141                	addi	sp,sp,-16
    80005fd8:	e406                	sd	ra,8(sp)
    80005fda:	e022                	sd	s0,0(sp)
    80005fdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fde:	479d                	li	a5,7
    80005fe0:	04a7cc63          	blt	a5,a0,80006038 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fe4:	0001e797          	auipc	a5,0x1e
    80005fe8:	01c78793          	addi	a5,a5,28 # 80024000 <disk>
    80005fec:	00a78733          	add	a4,a5,a0
    80005ff0:	6789                	lui	a5,0x2
    80005ff2:	97ba                	add	a5,a5,a4
    80005ff4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ff8:	eba1                	bnez	a5,80006048 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005ffa:	00451713          	slli	a4,a0,0x4
    80005ffe:	00020797          	auipc	a5,0x20
    80006002:	0027b783          	ld	a5,2(a5) # 80026000 <disk+0x2000>
    80006006:	97ba                	add	a5,a5,a4
    80006008:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000600c:	0001e797          	auipc	a5,0x1e
    80006010:	ff478793          	addi	a5,a5,-12 # 80024000 <disk>
    80006014:	97aa                	add	a5,a5,a0
    80006016:	6509                	lui	a0,0x2
    80006018:	953e                	add	a0,a0,a5
    8000601a:	4785                	li	a5,1
    8000601c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006020:	00020517          	auipc	a0,0x20
    80006024:	ff850513          	addi	a0,a0,-8 # 80026018 <disk+0x2018>
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	664080e7          	jalr	1636(ra) # 8000268c <wakeup>
}
    80006030:	60a2                	ld	ra,8(sp)
    80006032:	6402                	ld	s0,0(sp)
    80006034:	0141                	addi	sp,sp,16
    80006036:	8082                	ret
    panic("virtio_disk_intr 1");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	79850513          	addi	a0,a0,1944 # 800087d0 <syscalls+0x330>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	500080e7          	jalr	1280(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	7a050513          	addi	a0,a0,1952 # 800087e8 <syscalls+0x348>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f0080e7          	jalr	1264(ra) # 80000540 <panic>

0000000080006058 <virtio_disk_init>:
{
    80006058:	1101                	addi	sp,sp,-32
    8000605a:	ec06                	sd	ra,24(sp)
    8000605c:	e822                	sd	s0,16(sp)
    8000605e:	e426                	sd	s1,8(sp)
    80006060:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006062:	00002597          	auipc	a1,0x2
    80006066:	79e58593          	addi	a1,a1,1950 # 80008800 <syscalls+0x360>
    8000606a:	00020517          	auipc	a0,0x20
    8000606e:	03e50513          	addi	a0,a0,62 # 800260a8 <disk+0x20a8>
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	afa080e7          	jalr	-1286(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000607a:	100017b7          	lui	a5,0x10001
    8000607e:	4398                	lw	a4,0(a5)
    80006080:	2701                	sext.w	a4,a4
    80006082:	747277b7          	lui	a5,0x74727
    80006086:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000608a:	0ef71163          	bne	a4,a5,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000608e:	100017b7          	lui	a5,0x10001
    80006092:	43dc                	lw	a5,4(a5)
    80006094:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006096:	4705                	li	a4,1
    80006098:	0ce79a63          	bne	a5,a4,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	479c                	lw	a5,8(a5)
    800060a2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060a4:	4709                	li	a4,2
    800060a6:	0ce79363          	bne	a5,a4,8000616c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060aa:	100017b7          	lui	a5,0x10001
    800060ae:	47d8                	lw	a4,12(a5)
    800060b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060b2:	554d47b7          	lui	a5,0x554d4
    800060b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060ba:	0af71963          	bne	a4,a5,8000616c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060be:	100017b7          	lui	a5,0x10001
    800060c2:	4705                	li	a4,1
    800060c4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c6:	470d                	li	a4,3
    800060c8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ca:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060cc:	c7ffe737          	lui	a4,0xc7ffe
    800060d0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800060d4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060d6:	2701                	sext.w	a4,a4
    800060d8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060da:	472d                	li	a4,11
    800060dc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	473d                	li	a4,15
    800060e0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060e2:	6705                	lui	a4,0x1
    800060e4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060e6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060ea:	5bdc                	lw	a5,52(a5)
    800060ec:	2781                	sext.w	a5,a5
  if(max == 0)
    800060ee:	c7d9                	beqz	a5,8000617c <virtio_disk_init+0x124>
  if(max < NUM)
    800060f0:	471d                	li	a4,7
    800060f2:	08f77d63          	bgeu	a4,a5,8000618c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060f6:	100014b7          	lui	s1,0x10001
    800060fa:	47a1                	li	a5,8
    800060fc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060fe:	6609                	lui	a2,0x2
    80006100:	4581                	li	a1,0
    80006102:	0001e517          	auipc	a0,0x1e
    80006106:	efe50513          	addi	a0,a0,-258 # 80024000 <disk>
    8000610a:	ffffb097          	auipc	ra,0xffffb
    8000610e:	bee080e7          	jalr	-1042(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006112:	0001e717          	auipc	a4,0x1e
    80006116:	eee70713          	addi	a4,a4,-274 # 80024000 <disk>
    8000611a:	00c75793          	srli	a5,a4,0xc
    8000611e:	2781                	sext.w	a5,a5
    80006120:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006122:	00020797          	auipc	a5,0x20
    80006126:	ede78793          	addi	a5,a5,-290 # 80026000 <disk+0x2000>
    8000612a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000612c:	0001e717          	auipc	a4,0x1e
    80006130:	f5470713          	addi	a4,a4,-172 # 80024080 <disk+0x80>
    80006134:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006136:	0001f717          	auipc	a4,0x1f
    8000613a:	eca70713          	addi	a4,a4,-310 # 80025000 <disk+0x1000>
    8000613e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006140:	4705                	li	a4,1
    80006142:	00e78c23          	sb	a4,24(a5)
    80006146:	00e78ca3          	sb	a4,25(a5)
    8000614a:	00e78d23          	sb	a4,26(a5)
    8000614e:	00e78da3          	sb	a4,27(a5)
    80006152:	00e78e23          	sb	a4,28(a5)
    80006156:	00e78ea3          	sb	a4,29(a5)
    8000615a:	00e78f23          	sb	a4,30(a5)
    8000615e:	00e78fa3          	sb	a4,31(a5)
}
    80006162:	60e2                	ld	ra,24(sp)
    80006164:	6442                	ld	s0,16(sp)
    80006166:	64a2                	ld	s1,8(sp)
    80006168:	6105                	addi	sp,sp,32
    8000616a:	8082                	ret
    panic("could not find virtio disk");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	6a450513          	addi	a0,a0,1700 # 80008810 <syscalls+0x370>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	6b450513          	addi	a0,a0,1716 # 80008830 <syscalls+0x390>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3bc080e7          	jalr	956(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000618c:	00002517          	auipc	a0,0x2
    80006190:	6c450513          	addi	a0,a0,1732 # 80008850 <syscalls+0x3b0>
    80006194:	ffffa097          	auipc	ra,0xffffa
    80006198:	3ac080e7          	jalr	940(ra) # 80000540 <panic>

000000008000619c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000619c:	7175                	addi	sp,sp,-144
    8000619e:	e506                	sd	ra,136(sp)
    800061a0:	e122                	sd	s0,128(sp)
    800061a2:	fca6                	sd	s1,120(sp)
    800061a4:	f8ca                	sd	s2,112(sp)
    800061a6:	f4ce                	sd	s3,104(sp)
    800061a8:	f0d2                	sd	s4,96(sp)
    800061aa:	ecd6                	sd	s5,88(sp)
    800061ac:	e8da                	sd	s6,80(sp)
    800061ae:	e4de                	sd	s7,72(sp)
    800061b0:	e0e2                	sd	s8,64(sp)
    800061b2:	fc66                	sd	s9,56(sp)
    800061b4:	f86a                	sd	s10,48(sp)
    800061b6:	f46e                	sd	s11,40(sp)
    800061b8:	0900                	addi	s0,sp,144
    800061ba:	8aaa                	mv	s5,a0
    800061bc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061be:	00c52c83          	lw	s9,12(a0)
    800061c2:	001c9c9b          	slliw	s9,s9,0x1
    800061c6:	1c82                	slli	s9,s9,0x20
    800061c8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061cc:	00020517          	auipc	a0,0x20
    800061d0:	edc50513          	addi	a0,a0,-292 # 800260a8 <disk+0x20a8>
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	a28080e7          	jalr	-1496(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    800061dc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061de:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061e0:	0001ec17          	auipc	s8,0x1e
    800061e4:	e20c0c13          	addi	s8,s8,-480 # 80024000 <disk>
    800061e8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061ea:	4b0d                	li	s6,3
    800061ec:	a0ad                	j	80006256 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061ee:	00fc0733          	add	a4,s8,a5
    800061f2:	975e                	add	a4,a4,s7
    800061f4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061f8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061fa:	0207c563          	bltz	a5,80006224 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061fe:	2905                	addiw	s2,s2,1
    80006200:	0611                	addi	a2,a2,4
    80006202:	19690d63          	beq	s2,s6,8000639c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006206:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006208:	00020717          	auipc	a4,0x20
    8000620c:	e1070713          	addi	a4,a4,-496 # 80026018 <disk+0x2018>
    80006210:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006212:	00074683          	lbu	a3,0(a4)
    80006216:	fee1                	bnez	a3,800061ee <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006218:	2785                	addiw	a5,a5,1
    8000621a:	0705                	addi	a4,a4,1
    8000621c:	fe979be3          	bne	a5,s1,80006212 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006220:	57fd                	li	a5,-1
    80006222:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006224:	01205d63          	blez	s2,8000623e <virtio_disk_rw+0xa2>
    80006228:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000622a:	000a2503          	lw	a0,0(s4)
    8000622e:	00000097          	auipc	ra,0x0
    80006232:	da8080e7          	jalr	-600(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    80006236:	2d85                	addiw	s11,s11,1
    80006238:	0a11                	addi	s4,s4,4
    8000623a:	ffb918e3          	bne	s2,s11,8000622a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000623e:	00020597          	auipc	a1,0x20
    80006242:	e6a58593          	addi	a1,a1,-406 # 800260a8 <disk+0x20a8>
    80006246:	00020517          	auipc	a0,0x20
    8000624a:	dd250513          	addi	a0,a0,-558 # 80026018 <disk+0x2018>
    8000624e:	ffffc097          	auipc	ra,0xffffc
    80006252:	280080e7          	jalr	640(ra) # 800024ce <sleep>
  for(int i = 0; i < 3; i++){
    80006256:	f8040a13          	addi	s4,s0,-128
{
    8000625a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000625c:	894e                	mv	s2,s3
    8000625e:	b765                	j	80006206 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006260:	00020717          	auipc	a4,0x20
    80006264:	da073703          	ld	a4,-608(a4) # 80026000 <disk+0x2000>
    80006268:	973e                	add	a4,a4,a5
    8000626a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000626e:	0001e517          	auipc	a0,0x1e
    80006272:	d9250513          	addi	a0,a0,-622 # 80024000 <disk>
    80006276:	00020717          	auipc	a4,0x20
    8000627a:	d8a70713          	addi	a4,a4,-630 # 80026000 <disk+0x2000>
    8000627e:	6314                	ld	a3,0(a4)
    80006280:	96be                	add	a3,a3,a5
    80006282:	00c6d603          	lhu	a2,12(a3)
    80006286:	00166613          	ori	a2,a2,1
    8000628a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000628e:	f8842683          	lw	a3,-120(s0)
    80006292:	6310                	ld	a2,0(a4)
    80006294:	97b2                	add	a5,a5,a2
    80006296:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000629a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000629e:	0612                	slli	a2,a2,0x4
    800062a0:	962a                	add	a2,a2,a0
    800062a2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062a6:	00469793          	slli	a5,a3,0x4
    800062aa:	630c                	ld	a1,0(a4)
    800062ac:	95be                	add	a1,a1,a5
    800062ae:	6689                	lui	a3,0x2
    800062b0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800062b4:	96ca                	add	a3,a3,s2
    800062b6:	96aa                	add	a3,a3,a0
    800062b8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800062ba:	6314                	ld	a3,0(a4)
    800062bc:	96be                	add	a3,a3,a5
    800062be:	4585                	li	a1,1
    800062c0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062c2:	6314                	ld	a3,0(a4)
    800062c4:	96be                	add	a3,a3,a5
    800062c6:	4509                	li	a0,2
    800062c8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062cc:	6314                	ld	a3,0(a4)
    800062ce:	97b6                	add	a5,a5,a3
    800062d0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062d4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062d8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062dc:	6714                	ld	a3,8(a4)
    800062de:	0026d783          	lhu	a5,2(a3)
    800062e2:	8b9d                	andi	a5,a5,7
    800062e4:	0789                	addi	a5,a5,2
    800062e6:	0786                	slli	a5,a5,0x1
    800062e8:	97b6                	add	a5,a5,a3
    800062ea:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062ee:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062f2:	6718                	ld	a4,8(a4)
    800062f4:	00275783          	lhu	a5,2(a4)
    800062f8:	2785                	addiw	a5,a5,1
    800062fa:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062fe:	100017b7          	lui	a5,0x10001
    80006302:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006306:	004aa783          	lw	a5,4(s5)
    8000630a:	02b79163          	bne	a5,a1,8000632c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000630e:	00020917          	auipc	s2,0x20
    80006312:	d9a90913          	addi	s2,s2,-614 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006316:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006318:	85ca                	mv	a1,s2
    8000631a:	8556                	mv	a0,s5
    8000631c:	ffffc097          	auipc	ra,0xffffc
    80006320:	1b2080e7          	jalr	434(ra) # 800024ce <sleep>
  while(b->disk == 1) {
    80006324:	004aa783          	lw	a5,4(s5)
    80006328:	fe9788e3          	beq	a5,s1,80006318 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000632c:	f8042483          	lw	s1,-128(s0)
    80006330:	20048793          	addi	a5,s1,512
    80006334:	00479713          	slli	a4,a5,0x4
    80006338:	0001e797          	auipc	a5,0x1e
    8000633c:	cc878793          	addi	a5,a5,-824 # 80024000 <disk>
    80006340:	97ba                	add	a5,a5,a4
    80006342:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006346:	00020917          	auipc	s2,0x20
    8000634a:	cba90913          	addi	s2,s2,-838 # 80026000 <disk+0x2000>
    8000634e:	a019                	j	80006354 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006350:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006354:	8526                	mv	a0,s1
    80006356:	00000097          	auipc	ra,0x0
    8000635a:	c80080e7          	jalr	-896(ra) # 80005fd6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000635e:	0492                	slli	s1,s1,0x4
    80006360:	00093783          	ld	a5,0(s2)
    80006364:	94be                	add	s1,s1,a5
    80006366:	00c4d783          	lhu	a5,12(s1)
    8000636a:	8b85                	andi	a5,a5,1
    8000636c:	f3f5                	bnez	a5,80006350 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000636e:	00020517          	auipc	a0,0x20
    80006372:	d3a50513          	addi	a0,a0,-710 # 800260a8 <disk+0x20a8>
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	93a080e7          	jalr	-1734(ra) # 80000cb0 <release>
}
    8000637e:	60aa                	ld	ra,136(sp)
    80006380:	640a                	ld	s0,128(sp)
    80006382:	74e6                	ld	s1,120(sp)
    80006384:	7946                	ld	s2,112(sp)
    80006386:	79a6                	ld	s3,104(sp)
    80006388:	7a06                	ld	s4,96(sp)
    8000638a:	6ae6                	ld	s5,88(sp)
    8000638c:	6b46                	ld	s6,80(sp)
    8000638e:	6ba6                	ld	s7,72(sp)
    80006390:	6c06                	ld	s8,64(sp)
    80006392:	7ce2                	ld	s9,56(sp)
    80006394:	7d42                	ld	s10,48(sp)
    80006396:	7da2                	ld	s11,40(sp)
    80006398:	6149                	addi	sp,sp,144
    8000639a:	8082                	ret
  if(write)
    8000639c:	01a037b3          	snez	a5,s10
    800063a0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800063a4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800063a8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800063ac:	f8042483          	lw	s1,-128(s0)
    800063b0:	00449913          	slli	s2,s1,0x4
    800063b4:	00020997          	auipc	s3,0x20
    800063b8:	c4c98993          	addi	s3,s3,-948 # 80026000 <disk+0x2000>
    800063bc:	0009ba03          	ld	s4,0(s3)
    800063c0:	9a4a                	add	s4,s4,s2
    800063c2:	f7040513          	addi	a0,s0,-144
    800063c6:	ffffb097          	auipc	ra,0xffffb
    800063ca:	cf2080e7          	jalr	-782(ra) # 800010b8 <kvmpa>
    800063ce:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063d2:	0009b783          	ld	a5,0(s3)
    800063d6:	97ca                	add	a5,a5,s2
    800063d8:	4741                	li	a4,16
    800063da:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063dc:	0009b783          	ld	a5,0(s3)
    800063e0:	97ca                	add	a5,a5,s2
    800063e2:	4705                	li	a4,1
    800063e4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063e8:	f8442783          	lw	a5,-124(s0)
    800063ec:	0009b703          	ld	a4,0(s3)
    800063f0:	974a                	add	a4,a4,s2
    800063f2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063f6:	0792                	slli	a5,a5,0x4
    800063f8:	0009b703          	ld	a4,0(s3)
    800063fc:	973e                	add	a4,a4,a5
    800063fe:	058a8693          	addi	a3,s5,88
    80006402:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006404:	0009b703          	ld	a4,0(s3)
    80006408:	973e                	add	a4,a4,a5
    8000640a:	40000693          	li	a3,1024
    8000640e:	c714                	sw	a3,8(a4)
  if(write)
    80006410:	e40d18e3          	bnez	s10,80006260 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006414:	00020717          	auipc	a4,0x20
    80006418:	bec73703          	ld	a4,-1044(a4) # 80026000 <disk+0x2000>
    8000641c:	973e                	add	a4,a4,a5
    8000641e:	4689                	li	a3,2
    80006420:	00d71623          	sh	a3,12(a4)
    80006424:	b5a9                	j	8000626e <virtio_disk_rw+0xd2>

0000000080006426 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006426:	1101                	addi	sp,sp,-32
    80006428:	ec06                	sd	ra,24(sp)
    8000642a:	e822                	sd	s0,16(sp)
    8000642c:	e426                	sd	s1,8(sp)
    8000642e:	e04a                	sd	s2,0(sp)
    80006430:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006432:	00020517          	auipc	a0,0x20
    80006436:	c7650513          	addi	a0,a0,-906 # 800260a8 <disk+0x20a8>
    8000643a:	ffffa097          	auipc	ra,0xffffa
    8000643e:	7c2080e7          	jalr	1986(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006442:	00020717          	auipc	a4,0x20
    80006446:	bbe70713          	addi	a4,a4,-1090 # 80026000 <disk+0x2000>
    8000644a:	02075783          	lhu	a5,32(a4)
    8000644e:	6b18                	ld	a4,16(a4)
    80006450:	00275683          	lhu	a3,2(a4)
    80006454:	8ebd                	xor	a3,a3,a5
    80006456:	8a9d                	andi	a3,a3,7
    80006458:	cab9                	beqz	a3,800064ae <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000645a:	0001e917          	auipc	s2,0x1e
    8000645e:	ba690913          	addi	s2,s2,-1114 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006462:	00020497          	auipc	s1,0x20
    80006466:	b9e48493          	addi	s1,s1,-1122 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000646a:	078e                	slli	a5,a5,0x3
    8000646c:	97ba                	add	a5,a5,a4
    8000646e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006470:	20078713          	addi	a4,a5,512
    80006474:	0712                	slli	a4,a4,0x4
    80006476:	974a                	add	a4,a4,s2
    80006478:	03074703          	lbu	a4,48(a4)
    8000647c:	ef21                	bnez	a4,800064d4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000647e:	20078793          	addi	a5,a5,512
    80006482:	0792                	slli	a5,a5,0x4
    80006484:	97ca                	add	a5,a5,s2
    80006486:	7798                	ld	a4,40(a5)
    80006488:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000648c:	7788                	ld	a0,40(a5)
    8000648e:	ffffc097          	auipc	ra,0xffffc
    80006492:	1fe080e7          	jalr	510(ra) # 8000268c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006496:	0204d783          	lhu	a5,32(s1)
    8000649a:	2785                	addiw	a5,a5,1
    8000649c:	8b9d                	andi	a5,a5,7
    8000649e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064a2:	6898                	ld	a4,16(s1)
    800064a4:	00275683          	lhu	a3,2(a4)
    800064a8:	8a9d                	andi	a3,a3,7
    800064aa:	fcf690e3          	bne	a3,a5,8000646a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064ae:	10001737          	lui	a4,0x10001
    800064b2:	533c                	lw	a5,96(a4)
    800064b4:	8b8d                	andi	a5,a5,3
    800064b6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064b8:	00020517          	auipc	a0,0x20
    800064bc:	bf050513          	addi	a0,a0,-1040 # 800260a8 <disk+0x20a8>
    800064c0:	ffffa097          	auipc	ra,0xffffa
    800064c4:	7f0080e7          	jalr	2032(ra) # 80000cb0 <release>
}
    800064c8:	60e2                	ld	ra,24(sp)
    800064ca:	6442                	ld	s0,16(sp)
    800064cc:	64a2                	ld	s1,8(sp)
    800064ce:	6902                	ld	s2,0(sp)
    800064d0:	6105                	addi	sp,sp,32
    800064d2:	8082                	ret
      panic("virtio_disk_intr status");
    800064d4:	00002517          	auipc	a0,0x2
    800064d8:	39c50513          	addi	a0,a0,924 # 80008870 <syscalls+0x3d0>
    800064dc:	ffffa097          	auipc	ra,0xffffa
    800064e0:	064080e7          	jalr	100(ra) # 80000540 <panic>
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


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
    8000005e:	e5678793          	addi	a5,a5,-426 # 80005eb0 <timervec>
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
    80000128:	660080e7          	jalr	1632(ra) # 80002784 <either_copyin>
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
    800001cc:	926080e7          	jalr	-1754(ra) # 80001aee <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	2e0080e7          	jalr	736(ra) # 800024b8 <sleep>
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
    80000218:	51a080e7          	jalr	1306(ra) # 8000272e <either_copyout>
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
    800002f8:	4e6080e7          	jalr	1254(ra) # 800027da <procdump>
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
    8000044c:	1fc080e7          	jalr	508(ra) # 80002644 <wakeup>
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
    800008a4:	da4080e7          	jalr	-604(ra) # 80002644 <wakeup>
    
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
    8000093e:	b7e080e7          	jalr	-1154(ra) # 800024b8 <sleep>
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
    80000b9a:	f3c080e7          	jalr	-196(ra) # 80001ad2 <mycpu>
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
    80000bcc:	f0a080e7          	jalr	-246(ra) # 80001ad2 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	efe080e7          	jalr	-258(ra) # 80001ad2 <mycpu>
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
    80000bf0:	ee6080e7          	jalr	-282(ra) # 80001ad2 <mycpu>
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
    80000c30:	ea6080e7          	jalr	-346(ra) # 80001ad2 <mycpu>
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
    80000c5c:	e7a080e7          	jalr	-390(ra) # 80001ad2 <mycpu>
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
    80000eb2:	c14080e7          	jalr	-1004(ra) # 80001ac2 <cpuid>
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
    80000ece:	bf8080e7          	jalr	-1032(ra) # 80001ac2 <cpuid>
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
    80000ef0:	a30080e7          	jalr	-1488(ra) # 8000291c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	ffc080e7          	jalr	-4(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1aa080e7          	jalr	426(ra) # 800020a6 <scheduler>
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
    80000f50:	aa6080e7          	jalr	-1370(ra) # 800019f2 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	9a0080e7          	jalr	-1632(ra) # 800028f4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	9c0080e7          	jalr	-1600(ra) # 8000291c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f76080e7          	jalr	-138(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	f84080e7          	jalr	-124(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	128080e7          	jalr	296(ra) # 8000309c <binit>
    iinit();         // inode cache
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	7ba080e7          	jalr	1978(ra) # 80003736 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	758080e7          	jalr	1880(ra) # 800046dc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	06c080e7          	jalr	108(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e72080e7          	jalr	-398(ra) # 80001e06 <userinit>
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
    // should be moved to Q2
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
  obj->change = 0;
    800019e0:	1604a423          	sw	zero,360(s1)
}
    800019e4:	70a2                	ld	ra,40(sp)
    800019e6:	7402                	ld	s0,32(sp)
    800019e8:	64e2                	ld	s1,24(sp)
    800019ea:	6942                	ld	s2,16(sp)
    800019ec:	69a2                	ld	s3,8(sp)
    800019ee:	6145                	addi	sp,sp,48
    800019f0:	8082                	ret

00000000800019f2 <procinit>:
{
    800019f2:	715d                	addi	sp,sp,-80
    800019f4:	e486                	sd	ra,72(sp)
    800019f6:	e0a2                	sd	s0,64(sp)
    800019f8:	fc26                	sd	s1,56(sp)
    800019fa:	f84a                	sd	s2,48(sp)
    800019fc:	f44e                	sd	s3,40(sp)
    800019fe:	f052                	sd	s4,32(sp)
    80001a00:	ec56                	sd	s5,24(sp)
    80001a02:	e85a                	sd	s6,16(sp)
    80001a04:	e45e                	sd	s7,8(sp)
    80001a06:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a08:	00006597          	auipc	a1,0x6
    80001a0c:	7e858593          	addi	a1,a1,2024 # 800081f0 <digits+0x1b0>
    80001a10:	00010517          	auipc	a0,0x10
    80001a14:	54050513          	addi	a0,a0,1344 # 80011f50 <pid_lock>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	154080e7          	jalr	340(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a20:	00011917          	auipc	s2,0x11
    80001a24:	94890913          	addi	s2,s2,-1720 # 80012368 <proc>
    initlock(&p->lock, "proc");
    80001a28:	00006b97          	auipc	s7,0x6
    80001a2c:	7d0b8b93          	addi	s7,s7,2000 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a30:	8b4a                	mv	s6,s2
    80001a32:	00006a97          	auipc	s5,0x6
    80001a36:	5cea8a93          	addi	s5,s5,1486 # 80008000 <etext>
    80001a3a:	040009b7          	lui	s3,0x4000
    80001a3e:	19fd                	addi	s3,s3,-1
    80001a40:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a42:	00017a17          	auipc	s4,0x17
    80001a46:	926a0a13          	addi	s4,s4,-1754 # 80018368 <tickslock>
    initlock(&p->lock, "proc");
    80001a4a:	85de                	mv	a1,s7
    80001a4c:	854a                	mv	a0,s2
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	11e080e7          	jalr	286(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	0b6080e7          	jalr	182(ra) # 80000b0c <kalloc>
    80001a5e:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a60:	c929                	beqz	a0,80001ab2 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a62:	416904b3          	sub	s1,s2,s6
    80001a66:	849d                	srai	s1,s1,0x7
    80001a68:	000ab783          	ld	a5,0(s5)
    80001a6c:	02f484b3          	mul	s1,s1,a5
    80001a70:	2485                	addiw	s1,s1,1
    80001a72:	00d4949b          	slliw	s1,s1,0xd
    80001a76:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a7a:	4699                	li	a3,6
    80001a7c:	6605                	lui	a2,0x1
    80001a7e:	8526                	mv	a0,s1
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	724080e7          	jalr	1828(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001a88:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8c:	18090913          	addi	s2,s2,384
    80001a90:	fb491de3          	bne	s2,s4,80001a4a <procinit+0x58>
  kvminithart();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	518080e7          	jalr	1304(ra) # 80000fac <kvminithart>
}
    80001a9c:	60a6                	ld	ra,72(sp)
    80001a9e:	6406                	ld	s0,64(sp)
    80001aa0:	74e2                	ld	s1,56(sp)
    80001aa2:	7942                	ld	s2,48(sp)
    80001aa4:	79a2                	ld	s3,40(sp)
    80001aa6:	7a02                	ld	s4,32(sp)
    80001aa8:	6ae2                	ld	s5,24(sp)
    80001aaa:	6b42                	ld	s6,16(sp)
    80001aac:	6ba2                	ld	s7,8(sp)
    80001aae:	6161                	addi	sp,sp,80
    80001ab0:	8082                	ret
      panic("kalloc");
    80001ab2:	00006517          	auipc	a0,0x6
    80001ab6:	74e50513          	addi	a0,a0,1870 # 80008200 <digits+0x1c0>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	a86080e7          	jalr	-1402(ra) # 80000540 <panic>

0000000080001ac2 <cpuid>:
{
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e422                	sd	s0,8(sp)
    80001ac6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ac8:	8512                	mv	a0,tp
}
    80001aca:	2501                	sext.w	a0,a0
    80001acc:	6422                	ld	s0,8(sp)
    80001ace:	0141                	addi	sp,sp,16
    80001ad0:	8082                	ret

0000000080001ad2 <mycpu>:
{
    80001ad2:	1141                	addi	sp,sp,-16
    80001ad4:	e422                	sd	s0,8(sp)
    80001ad6:	0800                	addi	s0,sp,16
    80001ad8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ada:	2781                	sext.w	a5,a5
    80001adc:	079e                	slli	a5,a5,0x7
}
    80001ade:	00010517          	auipc	a0,0x10
    80001ae2:	48a50513          	addi	a0,a0,1162 # 80011f68 <cpus>
    80001ae6:	953e                	add	a0,a0,a5
    80001ae8:	6422                	ld	s0,8(sp)
    80001aea:	0141                	addi	sp,sp,16
    80001aec:	8082                	ret

0000000080001aee <myproc>:
{
    80001aee:	1101                	addi	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	1000                	addi	s0,sp,32
  push_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	0b8080e7          	jalr	184(ra) # 80000bb0 <push_off>
    80001b00:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b02:	2781                	sext.w	a5,a5
    80001b04:	079e                	slli	a5,a5,0x7
    80001b06:	00010717          	auipc	a4,0x10
    80001b0a:	e4a70713          	addi	a4,a4,-438 # 80011950 <Q>
    80001b0e:	97ba                	add	a5,a5,a4
    80001b10:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	13c080e7          	jalr	316(ra) # 80000c50 <pop_off>
}
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	60e2                	ld	ra,24(sp)
    80001b20:	6442                	ld	s0,16(sp)
    80001b22:	64a2                	ld	s1,8(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret

0000000080001b28 <forkret>:
{
    80001b28:	1141                	addi	sp,sp,-16
    80001b2a:	e406                	sd	ra,8(sp)
    80001b2c:	e022                	sd	s0,0(sp)
    80001b2e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	fbe080e7          	jalr	-66(ra) # 80001aee <myproc>
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>
  if (first)
    80001b40:	00007797          	auipc	a5,0x7
    80001b44:	d407a783          	lw	a5,-704(a5) # 80008880 <first.1>
    80001b48:	eb89                	bnez	a5,80001b5a <forkret+0x32>
  usertrapret();
    80001b4a:	00001097          	auipc	ra,0x1
    80001b4e:	dea080e7          	jalr	-534(ra) # 80002934 <usertrapret>
}
    80001b52:	60a2                	ld	ra,8(sp)
    80001b54:	6402                	ld	s0,0(sp)
    80001b56:	0141                	addi	sp,sp,16
    80001b58:	8082                	ret
    first = 0;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	d207a323          	sw	zero,-730(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001b62:	4505                	li	a0,1
    80001b64:	00002097          	auipc	ra,0x2
    80001b68:	b52080e7          	jalr	-1198(ra) # 800036b6 <fsinit>
    80001b6c:	bff9                	j	80001b4a <forkret+0x22>

0000000080001b6e <allocpid>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b7a:	00010917          	auipc	s2,0x10
    80001b7e:	3d690913          	addi	s2,s2,982 # 80011f50 <pid_lock>
    80001b82:	854a                	mv	a0,s2
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	078080e7          	jalr	120(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b8c:	00007797          	auipc	a5,0x7
    80001b90:	cf878793          	addi	a5,a5,-776 # 80008884 <nextpid>
    80001b94:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b96:	0014871b          	addiw	a4,s1,1
    80001b9a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b9c:	854a                	mv	a0,s2
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	112080e7          	jalr	274(ra) # 80000cb0 <release>
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <proc_pagetable>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	e04a                	sd	s2,0(sp)
    80001bbe:	1000                	addi	s0,sp,32
    80001bc0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	7b0080e7          	jalr	1968(ra) # 80001372 <uvmcreate>
    80001bca:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bcc:	c121                	beqz	a0,80001c0c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bce:	4729                	li	a4,10
    80001bd0:	00005697          	auipc	a3,0x5
    80001bd4:	43068693          	addi	a3,a3,1072 # 80007000 <_trampoline>
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	040005b7          	lui	a1,0x4000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b2                	slli	a1,a1,0xc
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	534080e7          	jalr	1332(ra) # 80001116 <mappages>
    80001bea:	02054863          	bltz	a0,80001c1a <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bee:	4719                	li	a4,6
    80001bf0:	05893683          	ld	a3,88(s2)
    80001bf4:	6605                	lui	a2,0x1
    80001bf6:	020005b7          	lui	a1,0x2000
    80001bfa:	15fd                	addi	a1,a1,-1
    80001bfc:	05b6                	slli	a1,a1,0xd
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	516080e7          	jalr	1302(ra) # 80001116 <mappages>
    80001c08:	02054163          	bltz	a0,80001c2a <proc_pagetable+0x76>
}
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6902                	ld	s2,0(sp)
    80001c16:	6105                	addi	sp,sp,32
    80001c18:	8082                	ret
    uvmfree(pagetable, 0);
    80001c1a:	4581                	li	a1,0
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	950080e7          	jalr	-1712(ra) # 8000156e <uvmfree>
    return 0;
    80001c26:	4481                	li	s1,0
    80001c28:	b7d5                	j	80001c0c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2a:	4681                	li	a3,0
    80001c2c:	4605                	li	a2,1
    80001c2e:	040005b7          	lui	a1,0x4000
    80001c32:	15fd                	addi	a1,a1,-1
    80001c34:	05b2                	slli	a1,a1,0xc
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	676080e7          	jalr	1654(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c40:	4581                	li	a1,0
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	92a080e7          	jalr	-1750(ra) # 8000156e <uvmfree>
    return 0;
    80001c4c:	4481                	li	s1,0
    80001c4e:	bf7d                	j	80001c0c <proc_pagetable+0x58>

0000000080001c50 <proc_freepagetable>:
{
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	e04a                	sd	s2,0(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	84aa                	mv	s1,a0
    80001c5e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c60:	4681                	li	a3,0
    80001c62:	4605                	li	a2,1
    80001c64:	040005b7          	lui	a1,0x4000
    80001c68:	15fd                	addi	a1,a1,-1
    80001c6a:	05b2                	slli	a1,a1,0xc
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	642080e7          	jalr	1602(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c74:	4681                	li	a3,0
    80001c76:	4605                	li	a2,1
    80001c78:	020005b7          	lui	a1,0x2000
    80001c7c:	15fd                	addi	a1,a1,-1
    80001c7e:	05b6                	slli	a1,a1,0xd
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	62c080e7          	jalr	1580(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c8a:	85ca                	mv	a1,s2
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	8e0080e7          	jalr	-1824(ra) # 8000156e <uvmfree>
}
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret

0000000080001ca2 <freeproc>:
{
    80001ca2:	1101                	addi	sp,sp,-32
    80001ca4:	ec06                	sd	ra,24(sp)
    80001ca6:	e822                	sd	s0,16(sp)
    80001ca8:	e426                	sd	s1,8(sp)
    80001caa:	1000                	addi	s0,sp,32
    80001cac:	84aa                	mv	s1,a0
  getportion(p);
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	c14080e7          	jalr	-1004(ra) # 800018c2 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cb6:	16c4a783          	lw	a5,364(s1)
    80001cba:	1704a703          	lw	a4,368(s1)
    80001cbe:	1744a683          	lw	a3,372(s1)
    80001cc2:	5c90                	lw	a2,56(s1)
    80001cc4:	15848593          	addi	a1,s1,344
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	54050513          	addi	a0,a0,1344 # 80008208 <digits+0x1c8>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8ba080e7          	jalr	-1862(ra) # 8000058a <printf>
  if (p->trapframe)
    80001cd8:	6ca8                	ld	a0,88(s1)
    80001cda:	c509                	beqz	a0,80001ce4 <freeproc+0x42>
    kfree((void *)p->trapframe);
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	d34080e7          	jalr	-716(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001ce4:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ce8:	68a8                	ld	a0,80(s1)
    80001cea:	c511                	beqz	a0,80001cf6 <freeproc+0x54>
    proc_freepagetable(p->pagetable, p->sz);
    80001cec:	64ac                	ld	a1,72(s1)
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	f62080e7          	jalr	-158(ra) # 80001c50 <proc_freepagetable>
  p->pagetable = 0;
    80001cf6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cfe:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d02:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d0a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d0e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d12:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d16:	0004ac23          	sw	zero,24(s1)
  p->change = 0;
    80001d1a:	1604a423          	sw	zero,360(s1)
  p->Qtime[2] = 0;
    80001d1e:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001d22:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001d26:	1604a623          	sw	zero,364(s1)
  p->priority = 0;
    80001d2a:	1604ac23          	sw	zero,376(s1)
  movequeue(p, 0, DELETE);
    80001d2e:	4609                	li	a2,2
    80001d30:	4581                	li	a1,0
    80001d32:	8526                	mv	a0,s1
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c12080e7          	jalr	-1006(ra) # 80001946 <movequeue>
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <allocproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d52:	00010497          	auipc	s1,0x10
    80001d56:	61648493          	addi	s1,s1,1558 # 80012368 <proc>
    80001d5a:	00016917          	auipc	s2,0x16
    80001d5e:	60e90913          	addi	s2,s2,1550 # 80018368 <tickslock>
    acquire(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	e98080e7          	jalr	-360(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001d6c:	4c9c                	lw	a5,24(s1)
    80001d6e:	cf81                	beqz	a5,80001d86 <allocproc+0x40>
      release(&p->lock);
    80001d70:	8526                	mv	a0,s1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f3e080e7          	jalr	-194(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d7a:	18048493          	addi	s1,s1,384
    80001d7e:	ff2492e3          	bne	s1,s2,80001d62 <allocproc+0x1c>
  return 0;
    80001d82:	4481                	li	s1,0
    80001d84:	a0b9                	j	80001dd2 <allocproc+0x8c>
  p->pid = allocpid();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	de8080e7          	jalr	-536(ra) # 80001b6e <allocpid>
    80001d8e:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	d7c080e7          	jalr	-644(ra) # 80000b0c <kalloc>
    80001d98:	892a                	mv	s2,a0
    80001d9a:	eca8                	sd	a0,88(s1)
    80001d9c:	c131                	beqz	a0,80001de0 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e14080e7          	jalr	-492(ra) # 80001bb4 <proc_pagetable>
    80001da8:	892a                	mv	s2,a0
    80001daa:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dac:	c129                	beqz	a0,80001dee <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001dae:	07000613          	li	a2,112
    80001db2:	4581                	li	a1,0
    80001db4:	06048513          	addi	a0,s1,96
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	f40080e7          	jalr	-192(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001dc0:	00000797          	auipc	a5,0x0
    80001dc4:	d6878793          	addi	a5,a5,-664 # 80001b28 <forkret>
    80001dc8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dca:	60bc                	ld	a5,64(s1)
    80001dcc:	6705                	lui	a4,0x1
    80001dce:	97ba                	add	a5,a5,a4
    80001dd0:	f4bc                	sd	a5,104(s1)
}
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	60e2                	ld	ra,24(sp)
    80001dd6:	6442                	ld	s0,16(sp)
    80001dd8:	64a2                	ld	s1,8(sp)
    80001dda:	6902                	ld	s2,0(sp)
    80001ddc:	6105                	addi	sp,sp,32
    80001dde:	8082                	ret
    release(&p->lock);
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	ece080e7          	jalr	-306(ra) # 80000cb0 <release>
    return 0;
    80001dea:	84ca                	mv	s1,s2
    80001dec:	b7dd                	j	80001dd2 <allocproc+0x8c>
    freeproc(p);
    80001dee:	8526                	mv	a0,s1
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	eb2080e7          	jalr	-334(ra) # 80001ca2 <freeproc>
    release(&p->lock);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	eb6080e7          	jalr	-330(ra) # 80000cb0 <release>
    return 0;
    80001e02:	84ca                	mv	s1,s2
    80001e04:	b7f9                	j	80001dd2 <allocproc+0x8c>

0000000080001e06 <userinit>:
{
    80001e06:	1101                	addi	sp,sp,-32
    80001e08:	ec06                	sd	ra,24(sp)
    80001e0a:	e822                	sd	s0,16(sp)
    80001e0c:	e426                	sd	s1,8(sp)
    80001e0e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	f36080e7          	jalr	-202(ra) # 80001d46 <allocproc>
    80001e18:	84aa                	mv	s1,a0
  initproc = p;
    80001e1a:	00007797          	auipc	a5,0x7
    80001e1e:	1ea7bf23          	sd	a0,510(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e22:	03400613          	li	a2,52
    80001e26:	00007597          	auipc	a1,0x7
    80001e2a:	a6a58593          	addi	a1,a1,-1430 # 80008890 <initcode>
    80001e2e:	6928                	ld	a0,80(a0)
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	570080e7          	jalr	1392(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e38:	6785                	lui	a5,0x1
    80001e3a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e3c:	6cb8                	ld	a4,88(s1)
    80001e3e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e42:	6cb8                	ld	a4,88(s1)
    80001e44:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e46:	4641                	li	a2,16
    80001e48:	00006597          	auipc	a1,0x6
    80001e4c:	3f058593          	addi	a1,a1,1008 # 80008238 <digits+0x1f8>
    80001e50:	15848513          	addi	a0,s1,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	ff6080e7          	jalr	-10(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001e5c:	00006517          	auipc	a0,0x6
    80001e60:	3ec50513          	addi	a0,a0,1004 # 80008248 <digits+0x208>
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	27a080e7          	jalr	634(ra) # 800040de <namei>
    80001e6c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e70:	4789                	li	a5,2
    80001e72:	cc9c                	sw	a5,24(s1)
  movequeue(p, 2, INSERT);
    80001e74:	4605                	li	a2,1
    80001e76:	4589                	li	a1,2
    80001e78:	8526                	mv	a0,s1
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	acc080e7          	jalr	-1332(ra) # 80001946 <movequeue>
  p->Qtime[2] = 0;
    80001e82:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001e86:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001e8a:	1604a623          	sw	zero,364(s1)
  release(&p->lock);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	e20080e7          	jalr	-480(ra) # 80000cb0 <release>
}
    80001e98:	60e2                	ld	ra,24(sp)
    80001e9a:	6442                	ld	s0,16(sp)
    80001e9c:	64a2                	ld	s1,8(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret

0000000080001ea2 <growproc>:
{
    80001ea2:	1101                	addi	sp,sp,-32
    80001ea4:	ec06                	sd	ra,24(sp)
    80001ea6:	e822                	sd	s0,16(sp)
    80001ea8:	e426                	sd	s1,8(sp)
    80001eaa:	e04a                	sd	s2,0(sp)
    80001eac:	1000                	addi	s0,sp,32
    80001eae:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	c3e080e7          	jalr	-962(ra) # 80001aee <myproc>
    80001eb8:	892a                	mv	s2,a0
  sz = p->sz;
    80001eba:	652c                	ld	a1,72(a0)
    80001ebc:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001ec0:	00904f63          	bgtz	s1,80001ede <growproc+0x3c>
  else if (n < 0)
    80001ec4:	0204cc63          	bltz	s1,80001efc <growproc+0x5a>
  p->sz = sz;
    80001ec8:	1602                	slli	a2,a2,0x20
    80001eca:	9201                	srli	a2,a2,0x20
    80001ecc:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ed0:	4501                	li	a0,0
}
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6902                	ld	s2,0(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ede:	9e25                	addw	a2,a2,s1
    80001ee0:	1602                	slli	a2,a2,0x20
    80001ee2:	9201                	srli	a2,a2,0x20
    80001ee4:	1582                	slli	a1,a1,0x20
    80001ee6:	9181                	srli	a1,a1,0x20
    80001ee8:	6928                	ld	a0,80(a0)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	570080e7          	jalr	1392(ra) # 8000145a <uvmalloc>
    80001ef2:	0005061b          	sext.w	a2,a0
    80001ef6:	fa69                	bnez	a2,80001ec8 <growproc+0x26>
      return -1;
    80001ef8:	557d                	li	a0,-1
    80001efa:	bfe1                	j	80001ed2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001efc:	9e25                	addw	a2,a2,s1
    80001efe:	1602                	slli	a2,a2,0x20
    80001f00:	9201                	srli	a2,a2,0x20
    80001f02:	1582                	slli	a1,a1,0x20
    80001f04:	9181                	srli	a1,a1,0x20
    80001f06:	6928                	ld	a0,80(a0)
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	50a080e7          	jalr	1290(ra) # 80001412 <uvmdealloc>
    80001f10:	0005061b          	sext.w	a2,a0
    80001f14:	bf55                	j	80001ec8 <growproc+0x26>

0000000080001f16 <fork>:
{
    80001f16:	7139                	addi	sp,sp,-64
    80001f18:	fc06                	sd	ra,56(sp)
    80001f1a:	f822                	sd	s0,48(sp)
    80001f1c:	f426                	sd	s1,40(sp)
    80001f1e:	f04a                	sd	s2,32(sp)
    80001f20:	ec4e                	sd	s3,24(sp)
    80001f22:	e852                	sd	s4,16(sp)
    80001f24:	e456                	sd	s5,8(sp)
    80001f26:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	bc6080e7          	jalr	-1082(ra) # 80001aee <myproc>
    80001f30:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	e14080e7          	jalr	-492(ra) # 80001d46 <allocproc>
    80001f3a:	10050163          	beqz	a0,8000203c <fork+0x126>
    80001f3e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f40:	048ab603          	ld	a2,72(s5)
    80001f44:	692c                	ld	a1,80(a0)
    80001f46:	050ab503          	ld	a0,80(s5)
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	65c080e7          	jalr	1628(ra) # 800015a6 <uvmcopy>
    80001f52:	04054a63          	bltz	a0,80001fa6 <fork+0x90>
  np->sz = p->sz;
    80001f56:	048ab783          	ld	a5,72(s5)
    80001f5a:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f5e:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f62:	058ab683          	ld	a3,88(s5)
    80001f66:	87b6                	mv	a5,a3
    80001f68:	0589b703          	ld	a4,88(s3)
    80001f6c:	12068693          	addi	a3,a3,288
    80001f70:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f74:	6788                	ld	a0,8(a5)
    80001f76:	6b8c                	ld	a1,16(a5)
    80001f78:	6f90                	ld	a2,24(a5)
    80001f7a:	01073023          	sd	a6,0(a4)
    80001f7e:	e708                	sd	a0,8(a4)
    80001f80:	eb0c                	sd	a1,16(a4)
    80001f82:	ef10                	sd	a2,24(a4)
    80001f84:	02078793          	addi	a5,a5,32
    80001f88:	02070713          	addi	a4,a4,32
    80001f8c:	fed792e3          	bne	a5,a3,80001f70 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001f90:	0589b783          	ld	a5,88(s3)
    80001f94:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f98:	0d0a8493          	addi	s1,s5,208
    80001f9c:	0d098913          	addi	s2,s3,208
    80001fa0:	150a8a13          	addi	s4,s5,336
    80001fa4:	a00d                	j	80001fc6 <fork+0xb0>
    freeproc(np);
    80001fa6:	854e                	mv	a0,s3
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	cfa080e7          	jalr	-774(ra) # 80001ca2 <freeproc>
    release(&np->lock);
    80001fb0:	854e                	mv	a0,s3
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	cfe080e7          	jalr	-770(ra) # 80000cb0 <release>
    return -1;
    80001fba:	54fd                	li	s1,-1
    80001fbc:	a0b5                	j	80002028 <fork+0x112>
  for (i = 0; i < NOFILE; i++)
    80001fbe:	04a1                	addi	s1,s1,8
    80001fc0:	0921                	addi	s2,s2,8
    80001fc2:	01448b63          	beq	s1,s4,80001fd8 <fork+0xc2>
    if (p->ofile[i])
    80001fc6:	6088                	ld	a0,0(s1)
    80001fc8:	d97d                	beqz	a0,80001fbe <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fca:	00002097          	auipc	ra,0x2
    80001fce:	7a4080e7          	jalr	1956(ra) # 8000476e <filedup>
    80001fd2:	00a93023          	sd	a0,0(s2)
    80001fd6:	b7e5                	j	80001fbe <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001fd8:	150ab503          	ld	a0,336(s5)
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	914080e7          	jalr	-1772(ra) # 800038f0 <idup>
    80001fe4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fe8:	4641                	li	a2,16
    80001fea:	158a8593          	addi	a1,s5,344
    80001fee:	15898513          	addi	a0,s3,344
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	e58080e7          	jalr	-424(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80001ffa:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ffe:	4789                	li	a5,2
    80002000:	00f9ac23          	sw	a5,24(s3)
  movequeue(np, 2, INSERT);
    80002004:	4605                	li	a2,1
    80002006:	4589                	li	a1,2
    80002008:	854e                	mv	a0,s3
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	93c080e7          	jalr	-1732(ra) # 80001946 <movequeue>
  np->Qtime[2] = 0;
    80002012:	1609aa23          	sw	zero,372(s3)
  np->Qtime[1] = 0;
    80002016:	1609a823          	sw	zero,368(s3)
  np->Qtime[0] = 0;
    8000201a:	1609a623          	sw	zero,364(s3)
  release(&np->lock);
    8000201e:	854e                	mv	a0,s3
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c90080e7          	jalr	-880(ra) # 80000cb0 <release>
}
    80002028:	8526                	mv	a0,s1
    8000202a:	70e2                	ld	ra,56(sp)
    8000202c:	7442                	ld	s0,48(sp)
    8000202e:	74a2                	ld	s1,40(sp)
    80002030:	7902                	ld	s2,32(sp)
    80002032:	69e2                	ld	s3,24(sp)
    80002034:	6a42                	ld	s4,16(sp)
    80002036:	6aa2                	ld	s5,8(sp)
    80002038:	6121                	addi	sp,sp,64
    8000203a:	8082                	ret
    return -1;
    8000203c:	54fd                	li	s1,-1
    8000203e:	b7ed                	j	80002028 <fork+0x112>

0000000080002040 <reparent>:
{
    80002040:	7179                	addi	sp,sp,-48
    80002042:	f406                	sd	ra,40(sp)
    80002044:	f022                	sd	s0,32(sp)
    80002046:	ec26                	sd	s1,24(sp)
    80002048:	e84a                	sd	s2,16(sp)
    8000204a:	e44e                	sd	s3,8(sp)
    8000204c:	e052                	sd	s4,0(sp)
    8000204e:	1800                	addi	s0,sp,48
    80002050:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002052:	00010497          	auipc	s1,0x10
    80002056:	31648493          	addi	s1,s1,790 # 80012368 <proc>
      pp->parent = initproc;
    8000205a:	00007a17          	auipc	s4,0x7
    8000205e:	fbea0a13          	addi	s4,s4,-66 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002062:	00016997          	auipc	s3,0x16
    80002066:	30698993          	addi	s3,s3,774 # 80018368 <tickslock>
    8000206a:	a029                	j	80002074 <reparent+0x34>
    8000206c:	18048493          	addi	s1,s1,384
    80002070:	03348363          	beq	s1,s3,80002096 <reparent+0x56>
    if (pp->parent == p)
    80002074:	709c                	ld	a5,32(s1)
    80002076:	ff279be3          	bne	a5,s2,8000206c <reparent+0x2c>
      acquire(&pp->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b80080e7          	jalr	-1152(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    80002084:	000a3783          	ld	a5,0(s4)
    80002088:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c24080e7          	jalr	-988(ra) # 80000cb0 <release>
    80002094:	bfe1                	j	8000206c <reparent+0x2c>
}
    80002096:	70a2                	ld	ra,40(sp)
    80002098:	7402                	ld	s0,32(sp)
    8000209a:	64e2                	ld	s1,24(sp)
    8000209c:	6942                	ld	s2,16(sp)
    8000209e:	69a2                	ld	s3,8(sp)
    800020a0:	6a02                	ld	s4,0(sp)
    800020a2:	6145                	addi	sp,sp,48
    800020a4:	8082                	ret

00000000800020a6 <scheduler>:
{
    800020a6:	711d                	addi	sp,sp,-96
    800020a8:	ec86                	sd	ra,88(sp)
    800020aa:	e8a2                	sd	s0,80(sp)
    800020ac:	e4a6                	sd	s1,72(sp)
    800020ae:	e0ca                	sd	s2,64(sp)
    800020b0:	fc4e                	sd	s3,56(sp)
    800020b2:	f852                	sd	s4,48(sp)
    800020b4:	f456                	sd	s5,40(sp)
    800020b6:	f05a                	sd	s6,32(sp)
    800020b8:	ec5e                	sd	s7,24(sp)
    800020ba:	e862                	sd	s8,16(sp)
    800020bc:	e466                	sd	s9,8(sp)
    800020be:	e06a                	sd	s10,0(sp)
    800020c0:	1080                	addi	s0,sp,96
    800020c2:	8792                	mv	a5,tp
  int id = r_tp();
    800020c4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020c6:	00779c13          	slli	s8,a5,0x7
    800020ca:	00010717          	auipc	a4,0x10
    800020ce:	88670713          	addi	a4,a4,-1914 # 80011950 <Q>
    800020d2:	9762                	add	a4,a4,s8
    800020d4:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    800020d8:	00010717          	auipc	a4,0x10
    800020dc:	e9870713          	addi	a4,a4,-360 # 80011f70 <cpus+0x8>
    800020e0:	9c3a                	add	s8,s8,a4
  int exec = 0;
    800020e2:	4b81                	li	s7,0
      switch (p->change)
    800020e4:	4a0d                	li	s4,3
    for (p = proc; p < &proc[NPROC]; p++)
    800020e6:	00016a97          	auipc	s5,0x16
    800020ea:	282a8a93          	addi	s5,s5,642 # 80018368 <tickslock>
        c->proc = p;
    800020ee:	00010c97          	auipc	s9,0x10
    800020f2:	862c8c93          	addi	s9,s9,-1950 # 80011950 <Q>
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	00fc8b33          	add	s6,s9,a5
    800020fc:	aa0d                	j	8000222e <scheduler+0x188>
      exec = 0;
    800020fe:	4b81                	li	s7,0
    80002100:	aa05                	j	80002230 <scheduler+0x18a>
        movequeue(p, 1, MOVE);
    80002102:	4601                	li	a2,0
    80002104:	85ce                	mv	a1,s3
    80002106:	8526                	mv	a0,s1
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	83e080e7          	jalr	-1986(ra) # 80001946 <movequeue>
        break;
    80002110:	a8a1                	j	80002168 <scheduler+0xc2>
        movequeue(p, 0, MOVE);
    80002112:	4601                	li	a2,0
    80002114:	4581                	li	a1,0
    80002116:	8526                	mv	a0,s1
    80002118:	00000097          	auipc	ra,0x0
    8000211c:	82e080e7          	jalr	-2002(ra) # 80001946 <movequeue>
        break;
    80002120:	a0a1                	j	80002168 <scheduler+0xc2>
        movequeue(p, 2, MOVE);
    80002122:	4601                	li	a2,0
    80002124:	85ca                	mv	a1,s2
    80002126:	8526                	mv	a0,s1
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	81e080e7          	jalr	-2018(ra) # 80001946 <movequeue>
        break;
    80002130:	a825                	j	80002168 <scheduler+0xc2>
          (p->Qtime[2])++;
    80002132:	1744a783          	lw	a5,372(s1)
    80002136:	2785                	addiw	a5,a5,1
    80002138:	16f4aa23          	sw	a5,372(s1)
      release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b72080e7          	jalr	-1166(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002146:	18048493          	addi	s1,s1,384
    8000214a:	05548463          	beq	s1,s5,80002192 <scheduler+0xec>
      acquire(&p->lock);
    8000214e:	8526                	mv	a0,s1
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	aac080e7          	jalr	-1364(ra) # 80000bfc <acquire>
      switch (p->change)
    80002158:	1684a783          	lw	a5,360(s1)
    8000215c:	fb278be3          	beq	a5,s2,80002112 <scheduler+0x6c>
    80002160:	fd4781e3          	beq	a5,s4,80002122 <scheduler+0x7c>
    80002164:	f9378fe3          	beq	a5,s3,80002102 <scheduler+0x5c>
      if (p->state != UNUSED)
    80002168:	4c9c                	lw	a5,24(s1)
    8000216a:	dbe9                	beqz	a5,8000213c <scheduler+0x96>
        if (p->priority == 2)
    8000216c:	1784a783          	lw	a5,376(s1)
    80002170:	fd2781e3          	beq	a5,s2,80002132 <scheduler+0x8c>
        else if (p->priority == 1)
    80002174:	01378963          	beq	a5,s3,80002186 <scheduler+0xe0>
        else if (p->priority == 0)
    80002178:	f3f1                	bnez	a5,8000213c <scheduler+0x96>
          (p->Qtime[0])++;
    8000217a:	16c4a783          	lw	a5,364(s1)
    8000217e:	2785                	addiw	a5,a5,1
    80002180:	16f4a623          	sw	a5,364(s1)
    80002184:	bf65                	j	8000213c <scheduler+0x96>
          (p->Qtime[1])++;
    80002186:	1704a783          	lw	a5,368(s1)
    8000218a:	2785                	addiw	a5,a5,1
    8000218c:	16f4a823          	sw	a5,368(s1)
    80002190:	b775                	j	8000213c <scheduler+0x96>
    int tail2 = findproc(0, 2) - 1;
    80002192:	85ca                	mv	a1,s2
    80002194:	4501                	li	a0,0
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	772080e7          	jalr	1906(ra) # 80001908 <findproc>
    for (int i = 0; i <= tail2; i++)
    8000219e:	06a05263          	blez	a0,80002202 <scheduler+0x15c>
    800021a2:	00010997          	auipc	s3,0x10
    800021a6:	bae98993          	addi	s3,s3,-1106 # 80011d50 <Q+0x400>
    800021aa:	fff50d1b          	addiw	s10,a0,-1
    800021ae:	020d1793          	slli	a5,s10,0x20
    800021b2:	01d7dd13          	srli	s10,a5,0x1d
    800021b6:	00010797          	auipc	a5,0x10
    800021ba:	ba278793          	addi	a5,a5,-1118 # 80011d58 <Q+0x408>
    800021be:	9d3e                	add	s10,s10,a5
    800021c0:	a809                	j	800021d2 <scheduler+0x12c>
      release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	aec080e7          	jalr	-1300(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    800021cc:	09a1                	addi	s3,s3,8
    800021ce:	03a98a63          	beq	s3,s10,80002202 <scheduler+0x15c>
      p = Q[2][i];
    800021d2:	0009b483          	ld	s1,0(s3)
      acquire(&p->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	a24080e7          	jalr	-1500(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    800021e0:	4c9c                	lw	a5,24(s1)
    800021e2:	ff2790e3          	bne	a5,s2,800021c2 <scheduler+0x11c>
        p->state = RUNNING;
    800021e6:	0144ac23          	sw	s4,24(s1)
        c->proc = p;
    800021ea:	609b3c23          	sd	s1,1560(s6) # 1618 <_entry-0x7fffe9e8>
        swtch(&c->context, &p->context);
    800021ee:	06048593          	addi	a1,s1,96
    800021f2:	8562                	mv	a0,s8
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	696080e7          	jalr	1686(ra) # 8000288a <swtch>
        c->proc = 0;
    800021fc:	600b3c23          	sd	zero,1560(s6)
    80002200:	b7c9                	j	800021c2 <scheduler+0x11c>
    p = Q[1][exec];
    80002202:	040b8793          	addi	a5,s7,64
    80002206:	078e                	slli	a5,a5,0x3
    80002208:	97e6                	add	a5,a5,s9
    8000220a:	6384                	ld	s1,0(a5)
    if (p == 0)
    8000220c:	ee0489e3          	beqz	s1,800020fe <scheduler+0x58>
    acquire(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9ea080e7          	jalr	-1558(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000221a:	4c98                	lw	a4,24(s1)
    8000221c:	4789                	li	a5,2
    8000221e:	02f70563          	beq	a4,a5,80002248 <scheduler+0x1a2>
    release(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a8c080e7          	jalr	-1396(ra) # 80000cb0 <release>
    exec++;
    8000222c:	2b85                	addiw	s7,s7,1
      switch (p->change)
    8000222e:	4909                	li	s2,2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002230:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002234:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002238:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000223c:	00010497          	auipc	s1,0x10
    80002240:	12c48493          	addi	s1,s1,300 # 80012368 <proc>
      switch (p->change)
    80002244:	4985                	li	s3,1
    80002246:	b721                	j	8000214e <scheduler+0xa8>
      p->state = RUNNING;
    80002248:	0144ac23          	sw	s4,24(s1)
      c->proc = p;
    8000224c:	609b3c23          	sd	s1,1560(s6)
      swtch(&c->context, &p->context);
    80002250:	06048593          	addi	a1,s1,96
    80002254:	8562                	mv	a0,s8
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	634080e7          	jalr	1588(ra) # 8000288a <swtch>
      c->proc = 0;
    8000225e:	600b3c23          	sd	zero,1560(s6)
    80002262:	b7c1                	j	80002222 <scheduler+0x17c>

0000000080002264 <sched>:
{
    80002264:	7179                	addi	sp,sp,-48
    80002266:	f406                	sd	ra,40(sp)
    80002268:	f022                	sd	s0,32(sp)
    8000226a:	ec26                	sd	s1,24(sp)
    8000226c:	e84a                	sd	s2,16(sp)
    8000226e:	e44e                	sd	s3,8(sp)
    80002270:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002272:	00000097          	auipc	ra,0x0
    80002276:	87c080e7          	jalr	-1924(ra) # 80001aee <myproc>
    8000227a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	906080e7          	jalr	-1786(ra) # 80000b82 <holding>
    80002284:	c93d                	beqz	a0,800022fa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002286:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002288:	2781                	sext.w	a5,a5
    8000228a:	079e                	slli	a5,a5,0x7
    8000228c:	0000f717          	auipc	a4,0xf
    80002290:	6c470713          	addi	a4,a4,1732 # 80011950 <Q>
    80002294:	97ba                	add	a5,a5,a4
    80002296:	6907a703          	lw	a4,1680(a5)
    8000229a:	4785                	li	a5,1
    8000229c:	06f71763          	bne	a4,a5,8000230a <sched+0xa6>
  if (p->state == RUNNING)
    800022a0:	4c98                	lw	a4,24(s1)
    800022a2:	478d                	li	a5,3
    800022a4:	06f70b63          	beq	a4,a5,8000231a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022a8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ac:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022ae:	efb5                	bnez	a5,8000232a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022b0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022b2:	0000f917          	auipc	s2,0xf
    800022b6:	69e90913          	addi	s2,s2,1694 # 80011950 <Q>
    800022ba:	2781                	sext.w	a5,a5
    800022bc:	079e                	slli	a5,a5,0x7
    800022be:	97ca                	add	a5,a5,s2
    800022c0:	6947a983          	lw	s3,1684(a5)
    800022c4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022c6:	2781                	sext.w	a5,a5
    800022c8:	079e                	slli	a5,a5,0x7
    800022ca:	00010597          	auipc	a1,0x10
    800022ce:	ca658593          	addi	a1,a1,-858 # 80011f70 <cpus+0x8>
    800022d2:	95be                	add	a1,a1,a5
    800022d4:	06048513          	addi	a0,s1,96
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	5b2080e7          	jalr	1458(ra) # 8000288a <swtch>
    800022e0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022e2:	2781                	sext.w	a5,a5
    800022e4:	079e                	slli	a5,a5,0x7
    800022e6:	97ca                	add	a5,a5,s2
    800022e8:	6937aa23          	sw	s3,1684(a5)
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret
    panic("sched p->lock");
    800022fa:	00006517          	auipc	a0,0x6
    800022fe:	f5650513          	addi	a0,a0,-170 # 80008250 <digits+0x210>
    80002302:	ffffe097          	auipc	ra,0xffffe
    80002306:	23e080e7          	jalr	574(ra) # 80000540 <panic>
    panic("sched locks");
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	f5650513          	addi	a0,a0,-170 # 80008260 <digits+0x220>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	22e080e7          	jalr	558(ra) # 80000540 <panic>
    panic("sched running");
    8000231a:	00006517          	auipc	a0,0x6
    8000231e:	f5650513          	addi	a0,a0,-170 # 80008270 <digits+0x230>
    80002322:	ffffe097          	auipc	ra,0xffffe
    80002326:	21e080e7          	jalr	542(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000232a:	00006517          	auipc	a0,0x6
    8000232e:	f5650513          	addi	a0,a0,-170 # 80008280 <digits+0x240>
    80002332:	ffffe097          	auipc	ra,0xffffe
    80002336:	20e080e7          	jalr	526(ra) # 80000540 <panic>

000000008000233a <exit>:
{
    8000233a:	7179                	addi	sp,sp,-48
    8000233c:	f406                	sd	ra,40(sp)
    8000233e:	f022                	sd	s0,32(sp)
    80002340:	ec26                	sd	s1,24(sp)
    80002342:	e84a                	sd	s2,16(sp)
    80002344:	e44e                	sd	s3,8(sp)
    80002346:	e052                	sd	s4,0(sp)
    80002348:	1800                	addi	s0,sp,48
    8000234a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	7a2080e7          	jalr	1954(ra) # 80001aee <myproc>
    80002354:	89aa                	mv	s3,a0
  if (p == initproc)
    80002356:	00007797          	auipc	a5,0x7
    8000235a:	cc27b783          	ld	a5,-830(a5) # 80009018 <initproc>
    8000235e:	0d050493          	addi	s1,a0,208
    80002362:	15050913          	addi	s2,a0,336
    80002366:	02a79363          	bne	a5,a0,8000238c <exit+0x52>
    panic("init exiting");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	f2e50513          	addi	a0,a0,-210 # 80008298 <digits+0x258>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>
      fileclose(f);
    8000237a:	00002097          	auipc	ra,0x2
    8000237e:	446080e7          	jalr	1094(ra) # 800047c0 <fileclose>
      p->ofile[fd] = 0;
    80002382:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002386:	04a1                	addi	s1,s1,8
    80002388:	01248563          	beq	s1,s2,80002392 <exit+0x58>
    if (p->ofile[fd])
    8000238c:	6088                	ld	a0,0(s1)
    8000238e:	f575                	bnez	a0,8000237a <exit+0x40>
    80002390:	bfdd                	j	80002386 <exit+0x4c>
  begin_op();
    80002392:	00002097          	auipc	ra,0x2
    80002396:	f5c080e7          	jalr	-164(ra) # 800042ee <begin_op>
  iput(p->cwd);
    8000239a:	1509b503          	ld	a0,336(s3)
    8000239e:	00001097          	auipc	ra,0x1
    800023a2:	74a080e7          	jalr	1866(ra) # 80003ae8 <iput>
  end_op();
    800023a6:	00002097          	auipc	ra,0x2
    800023aa:	fc8080e7          	jalr	-56(ra) # 8000436e <end_op>
  p->cwd = 0;
    800023ae:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023b2:	00007497          	auipc	s1,0x7
    800023b6:	c6648493          	addi	s1,s1,-922 # 80009018 <initproc>
    800023ba:	6088                	ld	a0,0(s1)
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	840080e7          	jalr	-1984(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    800023c4:	6088                	ld	a0,0(s1)
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	4b2080e7          	jalr	1202(ra) # 80001878 <wakeup1>
  release(&initproc->lock);
    800023ce:	6088                	ld	a0,0(s1)
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8e0080e7          	jalr	-1824(ra) # 80000cb0 <release>
  acquire(&p->lock);
    800023d8:	854e                	mv	a0,s3
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	822080e7          	jalr	-2014(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    800023e2:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023e6:	854e                	mv	a0,s3
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8c8080e7          	jalr	-1848(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	80a080e7          	jalr	-2038(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    800023fa:	854e                	mv	a0,s3
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	800080e7          	jalr	-2048(ra) # 80000bfc <acquire>
  reparent(p);
    80002404:	854e                	mv	a0,s3
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	c3a080e7          	jalr	-966(ra) # 80002040 <reparent>
  wakeup1(original_parent);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	468080e7          	jalr	1128(ra) # 80001878 <wakeup1>
  p->xstate = status;
    80002418:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000241c:	4791                	li	a5,4
    8000241e:	00f9ac23          	sw	a5,24(s3)
  p->change = 2;
    80002422:	4789                	li	a5,2
    80002424:	16f9a423          	sw	a5,360(s3)
  release(&original_parent->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	886080e7          	jalr	-1914(ra) # 80000cb0 <release>
  sched();
    80002432:	00000097          	auipc	ra,0x0
    80002436:	e32080e7          	jalr	-462(ra) # 80002264 <sched>
  panic("zombie exit");
    8000243a:	00006517          	auipc	a0,0x6
    8000243e:	e6e50513          	addi	a0,a0,-402 # 800082a8 <digits+0x268>
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	0fe080e7          	jalr	254(ra) # 80000540 <panic>

000000008000244a <yield>:
{
    8000244a:	1101                	addi	sp,sp,-32
    8000244c:	ec06                	sd	ra,24(sp)
    8000244e:	e822                	sd	s0,16(sp)
    80002450:	e426                	sd	s1,8(sp)
    80002452:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	69a080e7          	jalr	1690(ra) # 80001aee <myproc>
    8000245c:	84aa                	mv	s1,a0
  printf("Q%d %s %d\n", p->priority, p->name, ticks);
    8000245e:	00007697          	auipc	a3,0x7
    80002462:	bc26a683          	lw	a3,-1086(a3) # 80009020 <ticks>
    80002466:	15850613          	addi	a2,a0,344
    8000246a:	17852583          	lw	a1,376(a0)
    8000246e:	00006517          	auipc	a0,0x6
    80002472:	e4a50513          	addi	a0,a0,-438 # 800082b8 <digits+0x278>
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	114080e7          	jalr	276(ra) # 8000058a <printf>
  acquire(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	77c080e7          	jalr	1916(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    80002488:	4789                	li	a5,2
    8000248a:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    8000248c:	1784a703          	lw	a4,376(s1)
    80002490:	02f70063          	beq	a4,a5,800024b0 <yield+0x66>
  sched();
    80002494:	00000097          	auipc	ra,0x0
    80002498:	dd0080e7          	jalr	-560(ra) # 80002264 <sched>
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
    800024b6:	bff9                	j	80002494 <yield+0x4a>

00000000800024b8 <sleep>:
{
    800024b8:	7179                	addi	sp,sp,-48
    800024ba:	f406                	sd	ra,40(sp)
    800024bc:	f022                	sd	s0,32(sp)
    800024be:	ec26                	sd	s1,24(sp)
    800024c0:	e84a                	sd	s2,16(sp)
    800024c2:	e44e                	sd	s3,8(sp)
    800024c4:	1800                	addi	s0,sp,48
    800024c6:	89aa                	mv	s3,a0
    800024c8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	624080e7          	jalr	1572(ra) # 80001aee <myproc>
    800024d2:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    800024d4:	05250963          	beq	a0,s2,80002526 <sleep+0x6e>
    acquire(&p->lock); //DOC: sleeplock1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	724080e7          	jalr	1828(ra) # 80000bfc <acquire>
    release(lk);
    800024e0:	854a                	mv	a0,s2
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	7ce080e7          	jalr	1998(ra) # 80000cb0 <release>
  p->chan = chan;
    800024ea:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800024ee:	4785                	li	a5,1
    800024f0:	cc9c                	sw	a5,24(s1)
  p->change = 2;
    800024f2:	4789                	li	a5,2
    800024f4:	16f4a423          	sw	a5,360(s1)
  sched();
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	d6c080e7          	jalr	-660(ra) # 80002264 <sched>
  p->chan = 0;
    80002500:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	7aa080e7          	jalr	1962(ra) # 80000cb0 <release>
    acquire(lk);
    8000250e:	854a                	mv	a0,s2
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	6ec080e7          	jalr	1772(ra) # 80000bfc <acquire>
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6145                	addi	sp,sp,48
    80002524:	8082                	ret
  p->chan = chan;
    80002526:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000252a:	4785                	li	a5,1
    8000252c:	cd1c                	sw	a5,24(a0)
  p->change = 2;
    8000252e:	4789                	li	a5,2
    80002530:	16f52423          	sw	a5,360(a0)
  sched();
    80002534:	00000097          	auipc	ra,0x0
    80002538:	d30080e7          	jalr	-720(ra) # 80002264 <sched>
  p->chan = 0;
    8000253c:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    80002540:	bfe1                	j	80002518 <sleep+0x60>

0000000080002542 <wait>:
{
    80002542:	715d                	addi	sp,sp,-80
    80002544:	e486                	sd	ra,72(sp)
    80002546:	e0a2                	sd	s0,64(sp)
    80002548:	fc26                	sd	s1,56(sp)
    8000254a:	f84a                	sd	s2,48(sp)
    8000254c:	f44e                	sd	s3,40(sp)
    8000254e:	f052                	sd	s4,32(sp)
    80002550:	ec56                	sd	s5,24(sp)
    80002552:	e85a                	sd	s6,16(sp)
    80002554:	e45e                	sd	s7,8(sp)
    80002556:	0880                	addi	s0,sp,80
    80002558:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	594080e7          	jalr	1428(ra) # 80001aee <myproc>
    80002562:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	698080e7          	jalr	1688(ra) # 80000bfc <acquire>
    havekids = 0;
    8000256c:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000256e:	4a11                	li	s4,4
        havekids = 1;
    80002570:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002572:	00016997          	auipc	s3,0x16
    80002576:	df698993          	addi	s3,s3,-522 # 80018368 <tickslock>
    havekids = 0;
    8000257a:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000257c:	00010497          	auipc	s1,0x10
    80002580:	dec48493          	addi	s1,s1,-532 # 80012368 <proc>
    80002584:	a08d                	j	800025e6 <wait+0xa4>
          pid = np->pid;
    80002586:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000258a:	000b0e63          	beqz	s6,800025a6 <wait+0x64>
    8000258e:	4691                	li	a3,4
    80002590:	03448613          	addi	a2,s1,52
    80002594:	85da                	mv	a1,s6
    80002596:	05093503          	ld	a0,80(s2)
    8000259a:	fffff097          	auipc	ra,0xfffff
    8000259e:	110080e7          	jalr	272(ra) # 800016aa <copyout>
    800025a2:	02054263          	bltz	a0,800025c6 <wait+0x84>
          freeproc(np);
    800025a6:	8526                	mv	a0,s1
    800025a8:	fffff097          	auipc	ra,0xfffff
    800025ac:	6fa080e7          	jalr	1786(ra) # 80001ca2 <freeproc>
          release(&np->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	6fe080e7          	jalr	1790(ra) # 80000cb0 <release>
          release(&p->lock);
    800025ba:	854a                	mv	a0,s2
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6f4080e7          	jalr	1780(ra) # 80000cb0 <release>
          return pid;
    800025c4:	a8a9                	j	8000261e <wait+0xdc>
            release(&np->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6e8080e7          	jalr	1768(ra) # 80000cb0 <release>
            release(&p->lock);
    800025d0:	854a                	mv	a0,s2
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6de080e7          	jalr	1758(ra) # 80000cb0 <release>
            return -1;
    800025da:	59fd                	li	s3,-1
    800025dc:	a089                	j	8000261e <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    800025de:	18048493          	addi	s1,s1,384
    800025e2:	03348463          	beq	s1,s3,8000260a <wait+0xc8>
      if (np->parent == p)
    800025e6:	709c                	ld	a5,32(s1)
    800025e8:	ff279be3          	bne	a5,s2,800025de <wait+0x9c>
        acquire(&np->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	60e080e7          	jalr	1550(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    800025f6:	4c9c                	lw	a5,24(s1)
    800025f8:	f94787e3          	beq	a5,s4,80002586 <wait+0x44>
        release(&np->lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	6b2080e7          	jalr	1714(ra) # 80000cb0 <release>
        havekids = 1;
    80002606:	8756                	mv	a4,s5
    80002608:	bfd9                	j	800025de <wait+0x9c>
    if (!havekids || p->killed)
    8000260a:	c701                	beqz	a4,80002612 <wait+0xd0>
    8000260c:	03092783          	lw	a5,48(s2)
    80002610:	c39d                	beqz	a5,80002636 <wait+0xf4>
      release(&p->lock);
    80002612:	854a                	mv	a0,s2
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	69c080e7          	jalr	1692(ra) # 80000cb0 <release>
      return -1;
    8000261c:	59fd                	li	s3,-1
}
    8000261e:	854e                	mv	a0,s3
    80002620:	60a6                	ld	ra,72(sp)
    80002622:	6406                	ld	s0,64(sp)
    80002624:	74e2                	ld	s1,56(sp)
    80002626:	7942                	ld	s2,48(sp)
    80002628:	79a2                	ld	s3,40(sp)
    8000262a:	7a02                	ld	s4,32(sp)
    8000262c:	6ae2                	ld	s5,24(sp)
    8000262e:	6b42                	ld	s6,16(sp)
    80002630:	6ba2                	ld	s7,8(sp)
    80002632:	6161                	addi	sp,sp,80
    80002634:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    80002636:	85ca                	mv	a1,s2
    80002638:	854a                	mv	a0,s2
    8000263a:	00000097          	auipc	ra,0x0
    8000263e:	e7e080e7          	jalr	-386(ra) # 800024b8 <sleep>
    havekids = 0;
    80002642:	bf25                	j	8000257a <wait+0x38>

0000000080002644 <wakeup>:
{
    80002644:	7139                	addi	sp,sp,-64
    80002646:	fc06                	sd	ra,56(sp)
    80002648:	f822                	sd	s0,48(sp)
    8000264a:	f426                	sd	s1,40(sp)
    8000264c:	f04a                	sd	s2,32(sp)
    8000264e:	ec4e                	sd	s3,24(sp)
    80002650:	e852                	sd	s4,16(sp)
    80002652:	e456                	sd	s5,8(sp)
    80002654:	e05a                	sd	s6,0(sp)
    80002656:	0080                	addi	s0,sp,64
    80002658:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    8000265a:	00010497          	auipc	s1,0x10
    8000265e:	d0e48493          	addi	s1,s1,-754 # 80012368 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    80002662:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002664:	4b09                	li	s6,2
      p->change = 3;
    80002666:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002668:	00016917          	auipc	s2,0x16
    8000266c:	d0090913          	addi	s2,s2,-768 # 80018368 <tickslock>
    80002670:	a811                	j	80002684 <wakeup+0x40>
    release(&p->lock);
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	63c080e7          	jalr	1596(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000267c:	18048493          	addi	s1,s1,384
    80002680:	03248263          	beq	s1,s2,800026a4 <wakeup+0x60>
    acquire(&p->lock);
    80002684:	8526                	mv	a0,s1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	576080e7          	jalr	1398(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    8000268e:	4c9c                	lw	a5,24(s1)
    80002690:	ff3791e3          	bne	a5,s3,80002672 <wakeup+0x2e>
    80002694:	749c                	ld	a5,40(s1)
    80002696:	fd479ee3          	bne	a5,s4,80002672 <wakeup+0x2e>
      p->state = RUNNABLE;
    8000269a:	0164ac23          	sw	s6,24(s1)
      p->change = 3;
    8000269e:	1754a423          	sw	s5,360(s1)
    800026a2:	bfc1                	j	80002672 <wakeup+0x2e>
}
    800026a4:	70e2                	ld	ra,56(sp)
    800026a6:	7442                	ld	s0,48(sp)
    800026a8:	74a2                	ld	s1,40(sp)
    800026aa:	7902                	ld	s2,32(sp)
    800026ac:	69e2                	ld	s3,24(sp)
    800026ae:	6a42                	ld	s4,16(sp)
    800026b0:	6aa2                	ld	s5,8(sp)
    800026b2:	6b02                	ld	s6,0(sp)
    800026b4:	6121                	addi	sp,sp,64
    800026b6:	8082                	ret

00000000800026b8 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026b8:	7179                	addi	sp,sp,-48
    800026ba:	f406                	sd	ra,40(sp)
    800026bc:	f022                	sd	s0,32(sp)
    800026be:	ec26                	sd	s1,24(sp)
    800026c0:	e84a                	sd	s2,16(sp)
    800026c2:	e44e                	sd	s3,8(sp)
    800026c4:	1800                	addi	s0,sp,48
    800026c6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026c8:	00010497          	auipc	s1,0x10
    800026cc:	ca048493          	addi	s1,s1,-864 # 80012368 <proc>
    800026d0:	00016997          	auipc	s3,0x16
    800026d4:	c9898993          	addi	s3,s3,-872 # 80018368 <tickslock>
  {
    acquire(&p->lock);
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	522080e7          	jalr	1314(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    800026e2:	5c9c                	lw	a5,56(s1)
    800026e4:	01278d63          	beq	a5,s2,800026fe <kill+0x46>
        p->change = 3;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026e8:	8526                	mv	a0,s1
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5c6080e7          	jalr	1478(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026f2:	18048493          	addi	s1,s1,384
    800026f6:	ff3491e3          	bne	s1,s3,800026d8 <kill+0x20>
  }
  return -1;
    800026fa:	557d                	li	a0,-1
    800026fc:	a821                	j	80002714 <kill+0x5c>
      p->killed = 1;
    800026fe:	4785                	li	a5,1
    80002700:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    80002702:	4c98                	lw	a4,24(s1)
    80002704:	00f70f63          	beq	a4,a5,80002722 <kill+0x6a>
      release(&p->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	5a6080e7          	jalr	1446(ra) # 80000cb0 <release>
      return 0;
    80002712:	4501                	li	a0,0
}
    80002714:	70a2                	ld	ra,40(sp)
    80002716:	7402                	ld	s0,32(sp)
    80002718:	64e2                	ld	s1,24(sp)
    8000271a:	6942                	ld	s2,16(sp)
    8000271c:	69a2                	ld	s3,8(sp)
    8000271e:	6145                	addi	sp,sp,48
    80002720:	8082                	ret
        p->state = RUNNABLE;
    80002722:	4789                	li	a5,2
    80002724:	cc9c                	sw	a5,24(s1)
        p->change = 3;
    80002726:	478d                	li	a5,3
    80002728:	16f4a423          	sw	a5,360(s1)
    8000272c:	bff1                	j	80002708 <kill+0x50>

000000008000272e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000272e:	7179                	addi	sp,sp,-48
    80002730:	f406                	sd	ra,40(sp)
    80002732:	f022                	sd	s0,32(sp)
    80002734:	ec26                	sd	s1,24(sp)
    80002736:	e84a                	sd	s2,16(sp)
    80002738:	e44e                	sd	s3,8(sp)
    8000273a:	e052                	sd	s4,0(sp)
    8000273c:	1800                	addi	s0,sp,48
    8000273e:	84aa                	mv	s1,a0
    80002740:	892e                	mv	s2,a1
    80002742:	89b2                	mv	s3,a2
    80002744:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002746:	fffff097          	auipc	ra,0xfffff
    8000274a:	3a8080e7          	jalr	936(ra) # 80001aee <myproc>
  if (user_dst)
    8000274e:	c08d                	beqz	s1,80002770 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002750:	86d2                	mv	a3,s4
    80002752:	864e                	mv	a2,s3
    80002754:	85ca                	mv	a1,s2
    80002756:	6928                	ld	a0,80(a0)
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	f52080e7          	jalr	-174(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002760:	70a2                	ld	ra,40(sp)
    80002762:	7402                	ld	s0,32(sp)
    80002764:	64e2                	ld	s1,24(sp)
    80002766:	6942                	ld	s2,16(sp)
    80002768:	69a2                	ld	s3,8(sp)
    8000276a:	6a02                	ld	s4,0(sp)
    8000276c:	6145                	addi	sp,sp,48
    8000276e:	8082                	ret
    memmove((char *)dst, src, len);
    80002770:	000a061b          	sext.w	a2,s4
    80002774:	85ce                	mv	a1,s3
    80002776:	854a                	mv	a0,s2
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	5dc080e7          	jalr	1500(ra) # 80000d54 <memmove>
    return 0;
    80002780:	8526                	mv	a0,s1
    80002782:	bff9                	j	80002760 <either_copyout+0x32>

0000000080002784 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002784:	7179                	addi	sp,sp,-48
    80002786:	f406                	sd	ra,40(sp)
    80002788:	f022                	sd	s0,32(sp)
    8000278a:	ec26                	sd	s1,24(sp)
    8000278c:	e84a                	sd	s2,16(sp)
    8000278e:	e44e                	sd	s3,8(sp)
    80002790:	e052                	sd	s4,0(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	892a                	mv	s2,a0
    80002796:	84ae                	mv	s1,a1
    80002798:	89b2                	mv	s3,a2
    8000279a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	352080e7          	jalr	850(ra) # 80001aee <myproc>
  if (user_src)
    800027a4:	c08d                	beqz	s1,800027c6 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027a6:	86d2                	mv	a3,s4
    800027a8:	864e                	mv	a2,s3
    800027aa:	85ca                	mv	a1,s2
    800027ac:	6928                	ld	a0,80(a0)
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	f88080e7          	jalr	-120(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027b6:	70a2                	ld	ra,40(sp)
    800027b8:	7402                	ld	s0,32(sp)
    800027ba:	64e2                	ld	s1,24(sp)
    800027bc:	6942                	ld	s2,16(sp)
    800027be:	69a2                	ld	s3,8(sp)
    800027c0:	6a02                	ld	s4,0(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret
    memmove(dst, (char *)src, len);
    800027c6:	000a061b          	sext.w	a2,s4
    800027ca:	85ce                	mv	a1,s3
    800027cc:	854a                	mv	a0,s2
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	586080e7          	jalr	1414(ra) # 80000d54 <memmove>
    return 0;
    800027d6:	8526                	mv	a0,s1
    800027d8:	bff9                	j	800027b6 <either_copyin+0x32>

00000000800027da <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800027da:	715d                	addi	sp,sp,-80
    800027dc:	e486                	sd	ra,72(sp)
    800027de:	e0a2                	sd	s0,64(sp)
    800027e0:	fc26                	sd	s1,56(sp)
    800027e2:	f84a                	sd	s2,48(sp)
    800027e4:	f44e                	sd	s3,40(sp)
    800027e6:	f052                	sd	s4,32(sp)
    800027e8:	ec56                	sd	s5,24(sp)
    800027ea:	e85a                	sd	s6,16(sp)
    800027ec:	e45e                	sd	s7,8(sp)
    800027ee:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800027f0:	00006517          	auipc	a0,0x6
    800027f4:	8f850513          	addi	a0,a0,-1800 # 800080e8 <digits+0xa8>
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	d92080e7          	jalr	-622(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002800:	00010497          	auipc	s1,0x10
    80002804:	cc048493          	addi	s1,s1,-832 # 800124c0 <proc+0x158>
    80002808:	00016917          	auipc	s2,0x16
    8000280c:	cb890913          	addi	s2,s2,-840 # 800184c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002810:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002812:	00006997          	auipc	s3,0x6
    80002816:	ab698993          	addi	s3,s3,-1354 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    8000281a:	00006a97          	auipc	s5,0x6
    8000281e:	ab6a8a93          	addi	s5,s5,-1354 # 800082d0 <digits+0x290>
    printf("\n");
    80002822:	00006a17          	auipc	s4,0x6
    80002826:	8c6a0a13          	addi	s4,s4,-1850 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000282a:	00006b97          	auipc	s7,0x6
    8000282e:	adeb8b93          	addi	s7,s7,-1314 # 80008308 <states.0>
    80002832:	a00d                	j	80002854 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002834:	ee06a583          	lw	a1,-288(a3)
    80002838:	8556                	mv	a0,s5
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	d50080e7          	jalr	-688(ra) # 8000058a <printf>
    printf("\n");
    80002842:	8552                	mv	a0,s4
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	d46080e7          	jalr	-698(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000284c:	18048493          	addi	s1,s1,384
    80002850:	03248263          	beq	s1,s2,80002874 <procdump+0x9a>
    if (p->state == UNUSED)
    80002854:	86a6                	mv	a3,s1
    80002856:	ec04a783          	lw	a5,-320(s1)
    8000285a:	dbed                	beqz	a5,8000284c <procdump+0x72>
      state = "???";
    8000285c:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000285e:	fcfb6be3          	bltu	s6,a5,80002834 <procdump+0x5a>
    80002862:	02079713          	slli	a4,a5,0x20
    80002866:	01d75793          	srli	a5,a4,0x1d
    8000286a:	97de                	add	a5,a5,s7
    8000286c:	6390                	ld	a2,0(a5)
    8000286e:	f279                	bnez	a2,80002834 <procdump+0x5a>
      state = "???";
    80002870:	864e                	mv	a2,s3
    80002872:	b7c9                	j	80002834 <procdump+0x5a>
  }
}
    80002874:	60a6                	ld	ra,72(sp)
    80002876:	6406                	ld	s0,64(sp)
    80002878:	74e2                	ld	s1,56(sp)
    8000287a:	7942                	ld	s2,48(sp)
    8000287c:	79a2                	ld	s3,40(sp)
    8000287e:	7a02                	ld	s4,32(sp)
    80002880:	6ae2                	ld	s5,24(sp)
    80002882:	6b42                	ld	s6,16(sp)
    80002884:	6ba2                	ld	s7,8(sp)
    80002886:	6161                	addi	sp,sp,80
    80002888:	8082                	ret

000000008000288a <swtch>:
    8000288a:	00153023          	sd	ra,0(a0)
    8000288e:	00253423          	sd	sp,8(a0)
    80002892:	e900                	sd	s0,16(a0)
    80002894:	ed04                	sd	s1,24(a0)
    80002896:	03253023          	sd	s2,32(a0)
    8000289a:	03353423          	sd	s3,40(a0)
    8000289e:	03453823          	sd	s4,48(a0)
    800028a2:	03553c23          	sd	s5,56(a0)
    800028a6:	05653023          	sd	s6,64(a0)
    800028aa:	05753423          	sd	s7,72(a0)
    800028ae:	05853823          	sd	s8,80(a0)
    800028b2:	05953c23          	sd	s9,88(a0)
    800028b6:	07a53023          	sd	s10,96(a0)
    800028ba:	07b53423          	sd	s11,104(a0)
    800028be:	0005b083          	ld	ra,0(a1)
    800028c2:	0085b103          	ld	sp,8(a1)
    800028c6:	6980                	ld	s0,16(a1)
    800028c8:	6d84                	ld	s1,24(a1)
    800028ca:	0205b903          	ld	s2,32(a1)
    800028ce:	0285b983          	ld	s3,40(a1)
    800028d2:	0305ba03          	ld	s4,48(a1)
    800028d6:	0385ba83          	ld	s5,56(a1)
    800028da:	0405bb03          	ld	s6,64(a1)
    800028de:	0485bb83          	ld	s7,72(a1)
    800028e2:	0505bc03          	ld	s8,80(a1)
    800028e6:	0585bc83          	ld	s9,88(a1)
    800028ea:	0605bd03          	ld	s10,96(a1)
    800028ee:	0685bd83          	ld	s11,104(a1)
    800028f2:	8082                	ret

00000000800028f4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028f4:	1141                	addi	sp,sp,-16
    800028f6:	e406                	sd	ra,8(sp)
    800028f8:	e022                	sd	s0,0(sp)
    800028fa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028fc:	00006597          	auipc	a1,0x6
    80002900:	a3458593          	addi	a1,a1,-1484 # 80008330 <states.0+0x28>
    80002904:	00016517          	auipc	a0,0x16
    80002908:	a6450513          	addi	a0,a0,-1436 # 80018368 <tickslock>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	260080e7          	jalr	608(ra) # 80000b6c <initlock>
}
    80002914:	60a2                	ld	ra,8(sp)
    80002916:	6402                	ld	s0,0(sp)
    80002918:	0141                	addi	sp,sp,16
    8000291a:	8082                	ret

000000008000291c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000291c:	1141                	addi	sp,sp,-16
    8000291e:	e422                	sd	s0,8(sp)
    80002920:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002922:	00003797          	auipc	a5,0x3
    80002926:	4fe78793          	addi	a5,a5,1278 # 80005e20 <kernelvec>
    8000292a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000292e:	6422                	ld	s0,8(sp)
    80002930:	0141                	addi	sp,sp,16
    80002932:	8082                	ret

0000000080002934 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002934:	1141                	addi	sp,sp,-16
    80002936:	e406                	sd	ra,8(sp)
    80002938:	e022                	sd	s0,0(sp)
    8000293a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000293c:	fffff097          	auipc	ra,0xfffff
    80002940:	1b2080e7          	jalr	434(ra) # 80001aee <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002944:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002948:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000294e:	00004617          	auipc	a2,0x4
    80002952:	6b260613          	addi	a2,a2,1714 # 80007000 <_trampoline>
    80002956:	00004697          	auipc	a3,0x4
    8000295a:	6aa68693          	addi	a3,a3,1706 # 80007000 <_trampoline>
    8000295e:	8e91                	sub	a3,a3,a2
    80002960:	040007b7          	lui	a5,0x4000
    80002964:	17fd                	addi	a5,a5,-1
    80002966:	07b2                	slli	a5,a5,0xc
    80002968:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000296e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002970:	180026f3          	csrr	a3,satp
    80002974:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002976:	6d38                	ld	a4,88(a0)
    80002978:	6134                	ld	a3,64(a0)
    8000297a:	6585                	lui	a1,0x1
    8000297c:	96ae                	add	a3,a3,a1
    8000297e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002980:	6d38                	ld	a4,88(a0)
    80002982:	00000697          	auipc	a3,0x0
    80002986:	13868693          	addi	a3,a3,312 # 80002aba <usertrap>
    8000298a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000298c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000298e:	8692                	mv	a3,tp
    80002990:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002996:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000299a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a4:	6f18                	ld	a4,24(a4)
    800029a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029aa:	692c                	ld	a1,80(a0)
    800029ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029ae:	00004717          	auipc	a4,0x4
    800029b2:	6e270713          	addi	a4,a4,1762 # 80007090 <userret>
    800029b6:	8f11                	sub	a4,a4,a2
    800029b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ba:	577d                	li	a4,-1
    800029bc:	177e                	slli	a4,a4,0x3f
    800029be:	8dd9                	or	a1,a1,a4
    800029c0:	02000537          	lui	a0,0x2000
    800029c4:	157d                	addi	a0,a0,-1
    800029c6:	0536                	slli	a0,a0,0xd
    800029c8:	9782                	jalr	a5
}
    800029ca:	60a2                	ld	ra,8(sp)
    800029cc:	6402                	ld	s0,0(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029d2:	1101                	addi	sp,sp,-32
    800029d4:	ec06                	sd	ra,24(sp)
    800029d6:	e822                	sd	s0,16(sp)
    800029d8:	e426                	sd	s1,8(sp)
    800029da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029dc:	00016497          	auipc	s1,0x16
    800029e0:	98c48493          	addi	s1,s1,-1652 # 80018368 <tickslock>
    800029e4:	8526                	mv	a0,s1
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	216080e7          	jalr	534(ra) # 80000bfc <acquire>
  ticks++;
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	63250513          	addi	a0,a0,1586 # 80009020 <ticks>
    800029f6:	411c                	lw	a5,0(a0)
    800029f8:	2785                	addiw	a5,a5,1
    800029fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	c48080e7          	jalr	-952(ra) # 80002644 <wakeup>
  release(&tickslock);
    80002a04:	8526                	mv	a0,s1
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	2aa080e7          	jalr	682(ra) # 80000cb0 <release>
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6105                	addi	sp,sp,32
    80002a16:	8082                	ret

0000000080002a18 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a18:	1101                	addi	sp,sp,-32
    80002a1a:	ec06                	sd	ra,24(sp)
    80002a1c:	e822                	sd	s0,16(sp)
    80002a1e:	e426                	sd	s1,8(sp)
    80002a20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a22:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a26:	00074d63          	bltz	a4,80002a40 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a2a:	57fd                	li	a5,-1
    80002a2c:	17fe                	slli	a5,a5,0x3f
    80002a2e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a30:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a32:	06f70363          	beq	a4,a5,80002a98 <devintr+0x80>
  }
}
    80002a36:	60e2                	ld	ra,24(sp)
    80002a38:	6442                	ld	s0,16(sp)
    80002a3a:	64a2                	ld	s1,8(sp)
    80002a3c:	6105                	addi	sp,sp,32
    80002a3e:	8082                	ret
     (scause & 0xff) == 9){
    80002a40:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a44:	46a5                	li	a3,9
    80002a46:	fed792e3          	bne	a5,a3,80002a2a <devintr+0x12>
    int irq = plic_claim();
    80002a4a:	00003097          	auipc	ra,0x3
    80002a4e:	4de080e7          	jalr	1246(ra) # 80005f28 <plic_claim>
    80002a52:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a54:	47a9                	li	a5,10
    80002a56:	02f50763          	beq	a0,a5,80002a84 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a5a:	4785                	li	a5,1
    80002a5c:	02f50963          	beq	a0,a5,80002a8e <devintr+0x76>
    return 1;
    80002a60:	4505                	li	a0,1
    } else if(irq){
    80002a62:	d8f1                	beqz	s1,80002a36 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a64:	85a6                	mv	a1,s1
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	8d250513          	addi	a0,a0,-1838 # 80008338 <states.0+0x30>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	b1c080e7          	jalr	-1252(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a76:	8526                	mv	a0,s1
    80002a78:	00003097          	auipc	ra,0x3
    80002a7c:	4d4080e7          	jalr	1236(ra) # 80005f4c <plic_complete>
    return 1;
    80002a80:	4505                	li	a0,1
    80002a82:	bf55                	j	80002a36 <devintr+0x1e>
      uartintr();
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	f3c080e7          	jalr	-196(ra) # 800009c0 <uartintr>
    80002a8c:	b7ed                	j	80002a76 <devintr+0x5e>
      virtio_disk_intr();
    80002a8e:	00004097          	auipc	ra,0x4
    80002a92:	938080e7          	jalr	-1736(ra) # 800063c6 <virtio_disk_intr>
    80002a96:	b7c5                	j	80002a76 <devintr+0x5e>
    if(cpuid() == 0){
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	02a080e7          	jalr	42(ra) # 80001ac2 <cpuid>
    80002aa0:	c901                	beqz	a0,80002ab0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002aa2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aa6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aa8:	14479073          	csrw	sip,a5
    return 2;
    80002aac:	4509                	li	a0,2
    80002aae:	b761                	j	80002a36 <devintr+0x1e>
      clockintr();
    80002ab0:	00000097          	auipc	ra,0x0
    80002ab4:	f22080e7          	jalr	-222(ra) # 800029d2 <clockintr>
    80002ab8:	b7ed                	j	80002aa2 <devintr+0x8a>

0000000080002aba <usertrap>:
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002aca:	1007f793          	andi	a5,a5,256
    80002ace:	e3ad                	bnez	a5,80002b30 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ad0:	00003797          	auipc	a5,0x3
    80002ad4:	35078793          	addi	a5,a5,848 # 80005e20 <kernelvec>
    80002ad8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	012080e7          	jalr	18(ra) # 80001aee <myproc>
    80002ae4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ae6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae8:	14102773          	csrr	a4,sepc
    80002aec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002af2:	47a1                	li	a5,8
    80002af4:	04f71c63          	bne	a4,a5,80002b4c <usertrap+0x92>
    if(p->killed)
    80002af8:	591c                	lw	a5,48(a0)
    80002afa:	e3b9                	bnez	a5,80002b40 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002afc:	6cb8                	ld	a4,88(s1)
    80002afe:	6f1c                	ld	a5,24(a4)
    80002b00:	0791                	addi	a5,a5,4
    80002b02:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b0c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b10:	00000097          	auipc	ra,0x0
    80002b14:	2f8080e7          	jalr	760(ra) # 80002e08 <syscall>
  if(p->killed)
    80002b18:	589c                	lw	a5,48(s1)
    80002b1a:	ebc1                	bnez	a5,80002baa <usertrap+0xf0>
  usertrapret();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	e18080e7          	jalr	-488(ra) # 80002934 <usertrapret>
}
    80002b24:	60e2                	ld	ra,24(sp)
    80002b26:	6442                	ld	s0,16(sp)
    80002b28:	64a2                	ld	s1,8(sp)
    80002b2a:	6902                	ld	s2,0(sp)
    80002b2c:	6105                	addi	sp,sp,32
    80002b2e:	8082                	ret
    panic("usertrap: not from user mode");
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	82850513          	addi	a0,a0,-2008 # 80008358 <states.0+0x50>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a08080e7          	jalr	-1528(ra) # 80000540 <panic>
      exit(-1);
    80002b40:	557d                	li	a0,-1
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	7f8080e7          	jalr	2040(ra) # 8000233a <exit>
    80002b4a:	bf4d                	j	80002afc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	ecc080e7          	jalr	-308(ra) # 80002a18 <devintr>
    80002b54:	892a                	mv	s2,a0
    80002b56:	c501                	beqz	a0,80002b5e <usertrap+0xa4>
  if(p->killed)
    80002b58:	589c                	lw	a5,48(s1)
    80002b5a:	c3a1                	beqz	a5,80002b9a <usertrap+0xe0>
    80002b5c:	a815                	j	80002b90 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b62:	5c90                	lw	a2,56(s1)
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	81450513          	addi	a0,a0,-2028 # 80008378 <states.0+0x70>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a1e080e7          	jalr	-1506(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b78:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	82c50513          	addi	a0,a0,-2004 # 800083a8 <states.0+0xa0>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a06080e7          	jalr	-1530(ra) # 8000058a <printf>
    p->killed = 1;
    80002b8c:	4785                	li	a5,1
    80002b8e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b90:	557d                	li	a0,-1
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	7a8080e7          	jalr	1960(ra) # 8000233a <exit>
  if(which_dev == 2)
    80002b9a:	4789                	li	a5,2
    80002b9c:	f8f910e3          	bne	s2,a5,80002b1c <usertrap+0x62>
    yield();
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	8aa080e7          	jalr	-1878(ra) # 8000244a <yield>
    80002ba8:	bf95                	j	80002b1c <usertrap+0x62>
  int which_dev = 0;
    80002baa:	4901                	li	s2,0
    80002bac:	b7d5                	j	80002b90 <usertrap+0xd6>

0000000080002bae <kerneltrap>:
{
    80002bae:	7179                	addi	sp,sp,-48
    80002bb0:	f406                	sd	ra,40(sp)
    80002bb2:	f022                	sd	s0,32(sp)
    80002bb4:	ec26                	sd	s1,24(sp)
    80002bb6:	e84a                	sd	s2,16(sp)
    80002bb8:	e44e                	sd	s3,8(sp)
    80002bba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bbc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bc4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bc8:	1004f793          	andi	a5,s1,256
    80002bcc:	cb85                	beqz	a5,80002bfc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bd2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bd4:	ef85                	bnez	a5,80002c0c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	e42080e7          	jalr	-446(ra) # 80002a18 <devintr>
    80002bde:	cd1d                	beqz	a0,80002c1c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002be0:	4789                	li	a5,2
    80002be2:	08f50663          	beq	a0,a5,80002c6e <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002be6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bea:	10049073          	csrw	sstatus,s1
}
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	69a2                	ld	s3,8(sp)
    80002bf8:	6145                	addi	sp,sp,48
    80002bfa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bfc:	00005517          	auipc	a0,0x5
    80002c00:	7cc50513          	addi	a0,a0,1996 # 800083c8 <states.0+0xc0>
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	93c080e7          	jalr	-1732(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c0c:	00005517          	auipc	a0,0x5
    80002c10:	7e450513          	addi	a0,a0,2020 # 800083f0 <states.0+0xe8>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	92c080e7          	jalr	-1748(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c1c:	00006597          	auipc	a1,0x6
    80002c20:	4045a583          	lw	a1,1028(a1) # 80009020 <ticks>
    80002c24:	00006517          	auipc	a0,0x6
    80002c28:	85450513          	addi	a0,a0,-1964 # 80008478 <states.0+0x170>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	95e080e7          	jalr	-1698(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002c34:	85ce                	mv	a1,s3
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	7da50513          	addi	a0,a0,2010 # 80008410 <states.0+0x108>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	94c080e7          	jalr	-1716(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c4a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	7d250513          	addi	a0,a0,2002 # 80008420 <states.0+0x118>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	934080e7          	jalr	-1740(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c5e:	00005517          	auipc	a0,0x5
    80002c62:	7da50513          	addi	a0,a0,2010 # 80008438 <states.0+0x130>
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	8da080e7          	jalr	-1830(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6e:	fffff097          	auipc	ra,0xfffff
    80002c72:	e80080e7          	jalr	-384(ra) # 80001aee <myproc>
    80002c76:	d925                	beqz	a0,80002be6 <kerneltrap+0x38>
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	e76080e7          	jalr	-394(ra) # 80001aee <myproc>
    80002c80:	4d18                	lw	a4,24(a0)
    80002c82:	478d                	li	a5,3
    80002c84:	f6f711e3          	bne	a4,a5,80002be6 <kerneltrap+0x38>
    yield();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	7c2080e7          	jalr	1986(ra) # 8000244a <yield>
    80002c90:	bf99                	j	80002be6 <kerneltrap+0x38>

0000000080002c92 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c92:	1101                	addi	sp,sp,-32
    80002c94:	ec06                	sd	ra,24(sp)
    80002c96:	e822                	sd	s0,16(sp)
    80002c98:	e426                	sd	s1,8(sp)
    80002c9a:	1000                	addi	s0,sp,32
    80002c9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	e50080e7          	jalr	-432(ra) # 80001aee <myproc>
  switch (n)
    80002ca6:	4795                	li	a5,5
    80002ca8:	0497e163          	bltu	a5,s1,80002cea <argraw+0x58>
    80002cac:	048a                	slli	s1,s1,0x2
    80002cae:	00005717          	auipc	a4,0x5
    80002cb2:	7d270713          	addi	a4,a4,2002 # 80008480 <states.0+0x178>
    80002cb6:	94ba                	add	s1,s1,a4
    80002cb8:	409c                	lw	a5,0(s1)
    80002cba:	97ba                	add	a5,a5,a4
    80002cbc:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002cbe:	6d3c                	ld	a5,88(a0)
    80002cc0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc2:	60e2                	ld	ra,24(sp)
    80002cc4:	6442                	ld	s0,16(sp)
    80002cc6:	64a2                	ld	s1,8(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    return p->trapframe->a1;
    80002ccc:	6d3c                	ld	a5,88(a0)
    80002cce:	7fa8                	ld	a0,120(a5)
    80002cd0:	bfcd                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a2;
    80002cd2:	6d3c                	ld	a5,88(a0)
    80002cd4:	63c8                	ld	a0,128(a5)
    80002cd6:	b7f5                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a3;
    80002cd8:	6d3c                	ld	a5,88(a0)
    80002cda:	67c8                	ld	a0,136(a5)
    80002cdc:	b7dd                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a4;
    80002cde:	6d3c                	ld	a5,88(a0)
    80002ce0:	6bc8                	ld	a0,144(a5)
    80002ce2:	b7c5                	j	80002cc2 <argraw+0x30>
    return p->trapframe->a5;
    80002ce4:	6d3c                	ld	a5,88(a0)
    80002ce6:	6fc8                	ld	a0,152(a5)
    80002ce8:	bfe9                	j	80002cc2 <argraw+0x30>
  panic("argraw");
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	75e50513          	addi	a0,a0,1886 # 80008448 <states.0+0x140>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	84e080e7          	jalr	-1970(ra) # 80000540 <panic>

0000000080002cfa <fetchaddr>:
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	e04a                	sd	s2,0(sp)
    80002d04:	1000                	addi	s0,sp,32
    80002d06:	84aa                	mv	s1,a0
    80002d08:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	de4080e7          	jalr	-540(ra) # 80001aee <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d12:	653c                	ld	a5,72(a0)
    80002d14:	02f4f863          	bgeu	s1,a5,80002d44 <fetchaddr+0x4a>
    80002d18:	00848713          	addi	a4,s1,8
    80002d1c:	02e7e663          	bltu	a5,a4,80002d48 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d20:	46a1                	li	a3,8
    80002d22:	8626                	mv	a2,s1
    80002d24:	85ca                	mv	a1,s2
    80002d26:	6928                	ld	a0,80(a0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	a0e080e7          	jalr	-1522(ra) # 80001736 <copyin>
    80002d30:	00a03533          	snez	a0,a0
    80002d34:	40a00533          	neg	a0,a0
}
    80002d38:	60e2                	ld	ra,24(sp)
    80002d3a:	6442                	ld	s0,16(sp)
    80002d3c:	64a2                	ld	s1,8(sp)
    80002d3e:	6902                	ld	s2,0(sp)
    80002d40:	6105                	addi	sp,sp,32
    80002d42:	8082                	ret
    return -1;
    80002d44:	557d                	li	a0,-1
    80002d46:	bfcd                	j	80002d38 <fetchaddr+0x3e>
    80002d48:	557d                	li	a0,-1
    80002d4a:	b7fd                	j	80002d38 <fetchaddr+0x3e>

0000000080002d4c <fetchstr>:
{
    80002d4c:	7179                	addi	sp,sp,-48
    80002d4e:	f406                	sd	ra,40(sp)
    80002d50:	f022                	sd	s0,32(sp)
    80002d52:	ec26                	sd	s1,24(sp)
    80002d54:	e84a                	sd	s2,16(sp)
    80002d56:	e44e                	sd	s3,8(sp)
    80002d58:	1800                	addi	s0,sp,48
    80002d5a:	892a                	mv	s2,a0
    80002d5c:	84ae                	mv	s1,a1
    80002d5e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	d8e080e7          	jalr	-626(ra) # 80001aee <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d68:	86ce                	mv	a3,s3
    80002d6a:	864a                	mv	a2,s2
    80002d6c:	85a6                	mv	a1,s1
    80002d6e:	6928                	ld	a0,80(a0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	a54080e7          	jalr	-1452(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002d78:	00054763          	bltz	a0,80002d86 <fetchstr+0x3a>
  return strlen(buf);
    80002d7c:	8526                	mv	a0,s1
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	0fe080e7          	jalr	254(ra) # 80000e7c <strlen>
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret

0000000080002d94 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	1000                	addi	s0,sp,32
    80002d9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ef2080e7          	jalr	-270(ra) # 80002c92 <argraw>
    80002da8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002daa:	4501                	li	a0,0
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	64a2                	ld	s1,8(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret

0000000080002db6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002db6:	1101                	addi	sp,sp,-32
    80002db8:	ec06                	sd	ra,24(sp)
    80002dba:	e822                	sd	s0,16(sp)
    80002dbc:	e426                	sd	s1,8(sp)
    80002dbe:	1000                	addi	s0,sp,32
    80002dc0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	ed0080e7          	jalr	-304(ra) # 80002c92 <argraw>
    80002dca:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dcc:	4501                	li	a0,0
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6105                	addi	sp,sp,32
    80002dd6:	8082                	ret

0000000080002dd8 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	e04a                	sd	s2,0(sp)
    80002de2:	1000                	addi	s0,sp,32
    80002de4:	84ae                	mv	s1,a1
    80002de6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	eaa080e7          	jalr	-342(ra) # 80002c92 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002df0:	864a                	mv	a2,s2
    80002df2:	85a6                	mv	a1,s1
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	f58080e7          	jalr	-168(ra) # 80002d4c <fetchstr>
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6902                	ld	s2,0(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	e426                	sd	s1,8(sp)
    80002e10:	e04a                	sd	s2,0(sp)
    80002e12:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	cda080e7          	jalr	-806(ra) # 80001aee <myproc>
    80002e1c:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  printf("syscall at %d\n", ticks);
    80002e1e:	00006597          	auipc	a1,0x6
    80002e22:	2025a583          	lw	a1,514(a1) # 80009020 <ticks>
    80002e26:	00005517          	auipc	a0,0x5
    80002e2a:	62a50513          	addi	a0,a0,1578 # 80008450 <states.0+0x148>
    80002e2e:	ffffd097          	auipc	ra,0xffffd
    80002e32:	75c080e7          	jalr	1884(ra) # 8000058a <printf>
  if(p->priority != 2)
    80002e36:	1784a703          	lw	a4,376(s1)
    80002e3a:	4789                	li	a5,2
    80002e3c:	00f70563          	beq	a4,a5,80002e46 <syscall+0x3e>
    p->change    = 3;
    80002e40:	478d                	li	a5,3
    80002e42:	16f4a423          	sw	a5,360(s1)

  num = p->trapframe->a7;
    80002e46:	0584b903          	ld	s2,88(s1)
    80002e4a:	0a893783          	ld	a5,168(s2)
    80002e4e:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e52:	37fd                	addiw	a5,a5,-1
    80002e54:	4751                	li	a4,20
    80002e56:	00f76f63          	bltu	a4,a5,80002e74 <syscall+0x6c>
    80002e5a:	00369713          	slli	a4,a3,0x3
    80002e5e:	00005797          	auipc	a5,0x5
    80002e62:	63a78793          	addi	a5,a5,1594 # 80008498 <syscalls>
    80002e66:	97ba                	add	a5,a5,a4
    80002e68:	639c                	ld	a5,0(a5)
    80002e6a:	c789                	beqz	a5,80002e74 <syscall+0x6c>
  {
    p->trapframe->a0 = syscalls[num]();
    80002e6c:	9782                	jalr	a5
    80002e6e:	06a93823          	sd	a0,112(s2)
    80002e72:	a839                	j	80002e90 <syscall+0x88>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002e74:	15848613          	addi	a2,s1,344
    80002e78:	5c8c                	lw	a1,56(s1)
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	5e650513          	addi	a0,a0,1510 # 80008460 <states.0+0x158>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	708080e7          	jalr	1800(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e8a:	6cbc                	ld	a5,88(s1)
    80002e8c:	577d                	li	a4,-1
    80002e8e:	fbb8                	sd	a4,112(a5)
  }
}
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6902                	ld	s2,0(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ea4:	fec40593          	addi	a1,s0,-20
    80002ea8:	4501                	li	a0,0
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	eea080e7          	jalr	-278(ra) # 80002d94 <argint>
    return -1;
    80002eb2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eb4:	00054963          	bltz	a0,80002ec6 <sys_exit+0x2a>
  exit(n);
    80002eb8:	fec42503          	lw	a0,-20(s0)
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	47e080e7          	jalr	1150(ra) # 8000233a <exit>
  return 0;  // not reached
    80002ec4:	4781                	li	a5,0
}
    80002ec6:	853e                	mv	a0,a5
    80002ec8:	60e2                	ld	ra,24(sp)
    80002eca:	6442                	ld	s0,16(sp)
    80002ecc:	6105                	addi	sp,sp,32
    80002ece:	8082                	ret

0000000080002ed0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ed0:	1141                	addi	sp,sp,-16
    80002ed2:	e406                	sd	ra,8(sp)
    80002ed4:	e022                	sd	s0,0(sp)
    80002ed6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	c16080e7          	jalr	-1002(ra) # 80001aee <myproc>
}
    80002ee0:	5d08                	lw	a0,56(a0)
    80002ee2:	60a2                	ld	ra,8(sp)
    80002ee4:	6402                	ld	s0,0(sp)
    80002ee6:	0141                	addi	sp,sp,16
    80002ee8:	8082                	ret

0000000080002eea <sys_fork>:

uint64
sys_fork(void)
{
    80002eea:	1141                	addi	sp,sp,-16
    80002eec:	e406                	sd	ra,8(sp)
    80002eee:	e022                	sd	s0,0(sp)
    80002ef0:	0800                	addi	s0,sp,16
  return fork();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	024080e7          	jalr	36(ra) # 80001f16 <fork>
}
    80002efa:	60a2                	ld	ra,8(sp)
    80002efc:	6402                	ld	s0,0(sp)
    80002efe:	0141                	addi	sp,sp,16
    80002f00:	8082                	ret

0000000080002f02 <sys_wait>:

uint64
sys_wait(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f0a:	fe840593          	addi	a1,s0,-24
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	ea6080e7          	jalr	-346(ra) # 80002db6 <argaddr>
    80002f18:	87aa                	mv	a5,a0
    return -1;
    80002f1a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f1c:	0007c863          	bltz	a5,80002f2c <sys_wait+0x2a>
  return wait(p);
    80002f20:	fe843503          	ld	a0,-24(s0)
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	61e080e7          	jalr	1566(ra) # 80002542 <wait>
}
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret

0000000080002f34 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f34:	7179                	addi	sp,sp,-48
    80002f36:	f406                	sd	ra,40(sp)
    80002f38:	f022                	sd	s0,32(sp)
    80002f3a:	ec26                	sd	s1,24(sp)
    80002f3c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f3e:	fdc40593          	addi	a1,s0,-36
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	e50080e7          	jalr	-432(ra) # 80002d94 <argint>
    return -1;
    80002f4c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f4e:	00054f63          	bltz	a0,80002f6c <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	b9c080e7          	jalr	-1124(ra) # 80001aee <myproc>
    80002f5a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f5c:	fdc42503          	lw	a0,-36(s0)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	f42080e7          	jalr	-190(ra) # 80001ea2 <growproc>
    80002f68:	00054863          	bltz	a0,80002f78 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f6c:	8526                	mv	a0,s1
    80002f6e:	70a2                	ld	ra,40(sp)
    80002f70:	7402                	ld	s0,32(sp)
    80002f72:	64e2                	ld	s1,24(sp)
    80002f74:	6145                	addi	sp,sp,48
    80002f76:	8082                	ret
    return -1;
    80002f78:	54fd                	li	s1,-1
    80002f7a:	bfcd                	j	80002f6c <sys_sbrk+0x38>

0000000080002f7c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f7c:	7139                	addi	sp,sp,-64
    80002f7e:	fc06                	sd	ra,56(sp)
    80002f80:	f822                	sd	s0,48(sp)
    80002f82:	f426                	sd	s1,40(sp)
    80002f84:	f04a                	sd	s2,32(sp)
    80002f86:	ec4e                	sd	s3,24(sp)
    80002f88:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f8a:	fcc40593          	addi	a1,s0,-52
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	e04080e7          	jalr	-508(ra) # 80002d94 <argint>
    return -1;
    80002f98:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f9a:	06054563          	bltz	a0,80003004 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f9e:	00015517          	auipc	a0,0x15
    80002fa2:	3ca50513          	addi	a0,a0,970 # 80018368 <tickslock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	c56080e7          	jalr	-938(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80002fae:	00006917          	auipc	s2,0x6
    80002fb2:	07292903          	lw	s2,114(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fb6:	fcc42783          	lw	a5,-52(s0)
    80002fba:	cf85                	beqz	a5,80002ff2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fbc:	00015997          	auipc	s3,0x15
    80002fc0:	3ac98993          	addi	s3,s3,940 # 80018368 <tickslock>
    80002fc4:	00006497          	auipc	s1,0x6
    80002fc8:	05c48493          	addi	s1,s1,92 # 80009020 <ticks>
    if(myproc()->killed){
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	b22080e7          	jalr	-1246(ra) # 80001aee <myproc>
    80002fd4:	591c                	lw	a5,48(a0)
    80002fd6:	ef9d                	bnez	a5,80003014 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fd8:	85ce                	mv	a1,s3
    80002fda:	8526                	mv	a0,s1
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	4dc080e7          	jalr	1244(ra) # 800024b8 <sleep>
  while(ticks - ticks0 < n){
    80002fe4:	409c                	lw	a5,0(s1)
    80002fe6:	412787bb          	subw	a5,a5,s2
    80002fea:	fcc42703          	lw	a4,-52(s0)
    80002fee:	fce7efe3          	bltu	a5,a4,80002fcc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ff2:	00015517          	auipc	a0,0x15
    80002ff6:	37650513          	addi	a0,a0,886 # 80018368 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	cb6080e7          	jalr	-842(ra) # 80000cb0 <release>
  return 0;
    80003002:	4781                	li	a5,0
}
    80003004:	853e                	mv	a0,a5
    80003006:	70e2                	ld	ra,56(sp)
    80003008:	7442                	ld	s0,48(sp)
    8000300a:	74a2                	ld	s1,40(sp)
    8000300c:	7902                	ld	s2,32(sp)
    8000300e:	69e2                	ld	s3,24(sp)
    80003010:	6121                	addi	sp,sp,64
    80003012:	8082                	ret
      release(&tickslock);
    80003014:	00015517          	auipc	a0,0x15
    80003018:	35450513          	addi	a0,a0,852 # 80018368 <tickslock>
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	c94080e7          	jalr	-876(ra) # 80000cb0 <release>
      return -1;
    80003024:	57fd                	li	a5,-1
    80003026:	bff9                	j	80003004 <sys_sleep+0x88>

0000000080003028 <sys_kill>:

uint64
sys_kill(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003030:	fec40593          	addi	a1,s0,-20
    80003034:	4501                	li	a0,0
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	d5e080e7          	jalr	-674(ra) # 80002d94 <argint>
    8000303e:	87aa                	mv	a5,a0
    return -1;
    80003040:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003042:	0007c863          	bltz	a5,80003052 <sys_kill+0x2a>
  return kill(pid);
    80003046:	fec42503          	lw	a0,-20(s0)
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	66e080e7          	jalr	1646(ra) # 800026b8 <kill>
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret

000000008000305a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003064:	00015517          	auipc	a0,0x15
    80003068:	30450513          	addi	a0,a0,772 # 80018368 <tickslock>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	b90080e7          	jalr	-1136(ra) # 80000bfc <acquire>
  xticks = ticks;
    80003074:	00006497          	auipc	s1,0x6
    80003078:	fac4a483          	lw	s1,-84(s1) # 80009020 <ticks>
  release(&tickslock);
    8000307c:	00015517          	auipc	a0,0x15
    80003080:	2ec50513          	addi	a0,a0,748 # 80018368 <tickslock>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	c2c080e7          	jalr	-980(ra) # 80000cb0 <release>
  return xticks;
}
    8000308c:	02049513          	slli	a0,s1,0x20
    80003090:	9101                	srli	a0,a0,0x20
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000309c:	7179                	addi	sp,sp,-48
    8000309e:	f406                	sd	ra,40(sp)
    800030a0:	f022                	sd	s0,32(sp)
    800030a2:	ec26                	sd	s1,24(sp)
    800030a4:	e84a                	sd	s2,16(sp)
    800030a6:	e44e                	sd	s3,8(sp)
    800030a8:	e052                	sd	s4,0(sp)
    800030aa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ac:	00005597          	auipc	a1,0x5
    800030b0:	49c58593          	addi	a1,a1,1180 # 80008548 <syscalls+0xb0>
    800030b4:	00015517          	auipc	a0,0x15
    800030b8:	2cc50513          	addi	a0,a0,716 # 80018380 <bcache>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	ab0080e7          	jalr	-1360(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030c4:	0001d797          	auipc	a5,0x1d
    800030c8:	2bc78793          	addi	a5,a5,700 # 80020380 <bcache+0x8000>
    800030cc:	0001d717          	auipc	a4,0x1d
    800030d0:	51c70713          	addi	a4,a4,1308 # 800205e8 <bcache+0x8268>
    800030d4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030d8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030dc:	00015497          	auipc	s1,0x15
    800030e0:	2bc48493          	addi	s1,s1,700 # 80018398 <bcache+0x18>
    b->next = bcache.head.next;
    800030e4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030e6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030e8:	00005a17          	auipc	s4,0x5
    800030ec:	468a0a13          	addi	s4,s4,1128 # 80008550 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030f0:	2b893783          	ld	a5,696(s2)
    800030f4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030f6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030fa:	85d2                	mv	a1,s4
    800030fc:	01048513          	addi	a0,s1,16
    80003100:	00001097          	auipc	ra,0x1
    80003104:	4b2080e7          	jalr	1202(ra) # 800045b2 <initsleeplock>
    bcache.head.next->prev = b;
    80003108:	2b893783          	ld	a5,696(s2)
    8000310c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000310e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003112:	45848493          	addi	s1,s1,1112
    80003116:	fd349de3          	bne	s1,s3,800030f0 <binit+0x54>
  }
}
    8000311a:	70a2                	ld	ra,40(sp)
    8000311c:	7402                	ld	s0,32(sp)
    8000311e:	64e2                	ld	s1,24(sp)
    80003120:	6942                	ld	s2,16(sp)
    80003122:	69a2                	ld	s3,8(sp)
    80003124:	6a02                	ld	s4,0(sp)
    80003126:	6145                	addi	sp,sp,48
    80003128:	8082                	ret

000000008000312a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000312a:	7179                	addi	sp,sp,-48
    8000312c:	f406                	sd	ra,40(sp)
    8000312e:	f022                	sd	s0,32(sp)
    80003130:	ec26                	sd	s1,24(sp)
    80003132:	e84a                	sd	s2,16(sp)
    80003134:	e44e                	sd	s3,8(sp)
    80003136:	1800                	addi	s0,sp,48
    80003138:	892a                	mv	s2,a0
    8000313a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000313c:	00015517          	auipc	a0,0x15
    80003140:	24450513          	addi	a0,a0,580 # 80018380 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	ab8080e7          	jalr	-1352(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000314c:	0001d497          	auipc	s1,0x1d
    80003150:	4ec4b483          	ld	s1,1260(s1) # 80020638 <bcache+0x82b8>
    80003154:	0001d797          	auipc	a5,0x1d
    80003158:	49478793          	addi	a5,a5,1172 # 800205e8 <bcache+0x8268>
    8000315c:	02f48f63          	beq	s1,a5,8000319a <bread+0x70>
    80003160:	873e                	mv	a4,a5
    80003162:	a021                	j	8000316a <bread+0x40>
    80003164:	68a4                	ld	s1,80(s1)
    80003166:	02e48a63          	beq	s1,a4,8000319a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000316a:	449c                	lw	a5,8(s1)
    8000316c:	ff279ce3          	bne	a5,s2,80003164 <bread+0x3a>
    80003170:	44dc                	lw	a5,12(s1)
    80003172:	ff3799e3          	bne	a5,s3,80003164 <bread+0x3a>
      b->refcnt++;
    80003176:	40bc                	lw	a5,64(s1)
    80003178:	2785                	addiw	a5,a5,1
    8000317a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317c:	00015517          	auipc	a0,0x15
    80003180:	20450513          	addi	a0,a0,516 # 80018380 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b2c080e7          	jalr	-1236(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    8000318c:	01048513          	addi	a0,s1,16
    80003190:	00001097          	auipc	ra,0x1
    80003194:	45c080e7          	jalr	1116(ra) # 800045ec <acquiresleep>
      return b;
    80003198:	a8b9                	j	800031f6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000319a:	0001d497          	auipc	s1,0x1d
    8000319e:	4964b483          	ld	s1,1174(s1) # 80020630 <bcache+0x82b0>
    800031a2:	0001d797          	auipc	a5,0x1d
    800031a6:	44678793          	addi	a5,a5,1094 # 800205e8 <bcache+0x8268>
    800031aa:	00f48863          	beq	s1,a5,800031ba <bread+0x90>
    800031ae:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031b0:	40bc                	lw	a5,64(s1)
    800031b2:	cf81                	beqz	a5,800031ca <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031b4:	64a4                	ld	s1,72(s1)
    800031b6:	fee49de3          	bne	s1,a4,800031b0 <bread+0x86>
  panic("bget: no buffers");
    800031ba:	00005517          	auipc	a0,0x5
    800031be:	39e50513          	addi	a0,a0,926 # 80008558 <syscalls+0xc0>
    800031c2:	ffffd097          	auipc	ra,0xffffd
    800031c6:	37e080e7          	jalr	894(ra) # 80000540 <panic>
      b->dev = dev;
    800031ca:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031ce:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031d2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031d6:	4785                	li	a5,1
    800031d8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031da:	00015517          	auipc	a0,0x15
    800031de:	1a650513          	addi	a0,a0,422 # 80018380 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	ace080e7          	jalr	-1330(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031ea:	01048513          	addi	a0,s1,16
    800031ee:	00001097          	auipc	ra,0x1
    800031f2:	3fe080e7          	jalr	1022(ra) # 800045ec <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031f6:	409c                	lw	a5,0(s1)
    800031f8:	cb89                	beqz	a5,8000320a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031fa:	8526                	mv	a0,s1
    800031fc:	70a2                	ld	ra,40(sp)
    800031fe:	7402                	ld	s0,32(sp)
    80003200:	64e2                	ld	s1,24(sp)
    80003202:	6942                	ld	s2,16(sp)
    80003204:	69a2                	ld	s3,8(sp)
    80003206:	6145                	addi	sp,sp,48
    80003208:	8082                	ret
    virtio_disk_rw(b, 0);
    8000320a:	4581                	li	a1,0
    8000320c:	8526                	mv	a0,s1
    8000320e:	00003097          	auipc	ra,0x3
    80003212:	f2e080e7          	jalr	-210(ra) # 8000613c <virtio_disk_rw>
    b->valid = 1;
    80003216:	4785                	li	a5,1
    80003218:	c09c                	sw	a5,0(s1)
  return b;
    8000321a:	b7c5                	j	800031fa <bread+0xd0>

000000008000321c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
    80003226:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003228:	0541                	addi	a0,a0,16
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	45c080e7          	jalr	1116(ra) # 80004686 <holdingsleep>
    80003232:	cd01                	beqz	a0,8000324a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003234:	4585                	li	a1,1
    80003236:	8526                	mv	a0,s1
    80003238:	00003097          	auipc	ra,0x3
    8000323c:	f04080e7          	jalr	-252(ra) # 8000613c <virtio_disk_rw>
}
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	64a2                	ld	s1,8(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret
    panic("bwrite");
    8000324a:	00005517          	auipc	a0,0x5
    8000324e:	32650513          	addi	a0,a0,806 # 80008570 <syscalls+0xd8>
    80003252:	ffffd097          	auipc	ra,0xffffd
    80003256:	2ee080e7          	jalr	750(ra) # 80000540 <panic>

000000008000325a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	e04a                	sd	s2,0(sp)
    80003264:	1000                	addi	s0,sp,32
    80003266:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003268:	01050913          	addi	s2,a0,16
    8000326c:	854a                	mv	a0,s2
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	418080e7          	jalr	1048(ra) # 80004686 <holdingsleep>
    80003276:	c92d                	beqz	a0,800032e8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003278:	854a                	mv	a0,s2
    8000327a:	00001097          	auipc	ra,0x1
    8000327e:	3c8080e7          	jalr	968(ra) # 80004642 <releasesleep>

  acquire(&bcache.lock);
    80003282:	00015517          	auipc	a0,0x15
    80003286:	0fe50513          	addi	a0,a0,254 # 80018380 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	972080e7          	jalr	-1678(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003292:	40bc                	lw	a5,64(s1)
    80003294:	37fd                	addiw	a5,a5,-1
    80003296:	0007871b          	sext.w	a4,a5
    8000329a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000329c:	eb05                	bnez	a4,800032cc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000329e:	68bc                	ld	a5,80(s1)
    800032a0:	64b8                	ld	a4,72(s1)
    800032a2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032a4:	64bc                	ld	a5,72(s1)
    800032a6:	68b8                	ld	a4,80(s1)
    800032a8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032aa:	0001d797          	auipc	a5,0x1d
    800032ae:	0d678793          	addi	a5,a5,214 # 80020380 <bcache+0x8000>
    800032b2:	2b87b703          	ld	a4,696(a5)
    800032b6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032b8:	0001d717          	auipc	a4,0x1d
    800032bc:	33070713          	addi	a4,a4,816 # 800205e8 <bcache+0x8268>
    800032c0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032c2:	2b87b703          	ld	a4,696(a5)
    800032c6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032c8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032cc:	00015517          	auipc	a0,0x15
    800032d0:	0b450513          	addi	a0,a0,180 # 80018380 <bcache>
    800032d4:	ffffe097          	auipc	ra,0xffffe
    800032d8:	9dc080e7          	jalr	-1572(ra) # 80000cb0 <release>
}
    800032dc:	60e2                	ld	ra,24(sp)
    800032de:	6442                	ld	s0,16(sp)
    800032e0:	64a2                	ld	s1,8(sp)
    800032e2:	6902                	ld	s2,0(sp)
    800032e4:	6105                	addi	sp,sp,32
    800032e6:	8082                	ret
    panic("brelse");
    800032e8:	00005517          	auipc	a0,0x5
    800032ec:	29050513          	addi	a0,a0,656 # 80008578 <syscalls+0xe0>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	250080e7          	jalr	592(ra) # 80000540 <panic>

00000000800032f8 <bpin>:

void
bpin(struct buf *b) {
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	e426                	sd	s1,8(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003304:	00015517          	auipc	a0,0x15
    80003308:	07c50513          	addi	a0,a0,124 # 80018380 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	8f0080e7          	jalr	-1808(ra) # 80000bfc <acquire>
  b->refcnt++;
    80003314:	40bc                	lw	a5,64(s1)
    80003316:	2785                	addiw	a5,a5,1
    80003318:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000331a:	00015517          	auipc	a0,0x15
    8000331e:	06650513          	addi	a0,a0,102 # 80018380 <bcache>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	98e080e7          	jalr	-1650(ra) # 80000cb0 <release>
}
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret

0000000080003334 <bunpin>:

void
bunpin(struct buf *b) {
    80003334:	1101                	addi	sp,sp,-32
    80003336:	ec06                	sd	ra,24(sp)
    80003338:	e822                	sd	s0,16(sp)
    8000333a:	e426                	sd	s1,8(sp)
    8000333c:	1000                	addi	s0,sp,32
    8000333e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003340:	00015517          	auipc	a0,0x15
    80003344:	04050513          	addi	a0,a0,64 # 80018380 <bcache>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	8b4080e7          	jalr	-1868(ra) # 80000bfc <acquire>
  b->refcnt--;
    80003350:	40bc                	lw	a5,64(s1)
    80003352:	37fd                	addiw	a5,a5,-1
    80003354:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003356:	00015517          	auipc	a0,0x15
    8000335a:	02a50513          	addi	a0,a0,42 # 80018380 <bcache>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	952080e7          	jalr	-1710(ra) # 80000cb0 <release>
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003370:	1101                	addi	sp,sp,-32
    80003372:	ec06                	sd	ra,24(sp)
    80003374:	e822                	sd	s0,16(sp)
    80003376:	e426                	sd	s1,8(sp)
    80003378:	e04a                	sd	s2,0(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000337e:	00d5d59b          	srliw	a1,a1,0xd
    80003382:	0001d797          	auipc	a5,0x1d
    80003386:	6da7a783          	lw	a5,1754(a5) # 80020a5c <sb+0x1c>
    8000338a:	9dbd                	addw	a1,a1,a5
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	d9e080e7          	jalr	-610(ra) # 8000312a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003394:	0074f713          	andi	a4,s1,7
    80003398:	4785                	li	a5,1
    8000339a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000339e:	14ce                	slli	s1,s1,0x33
    800033a0:	90d9                	srli	s1,s1,0x36
    800033a2:	00950733          	add	a4,a0,s1
    800033a6:	05874703          	lbu	a4,88(a4)
    800033aa:	00e7f6b3          	and	a3,a5,a4
    800033ae:	c69d                	beqz	a3,800033dc <bfree+0x6c>
    800033b0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033b2:	94aa                	add	s1,s1,a0
    800033b4:	fff7c793          	not	a5,a5
    800033b8:	8ff9                	and	a5,a5,a4
    800033ba:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	106080e7          	jalr	262(ra) # 800044c4 <log_write>
  brelse(bp);
    800033c6:	854a                	mv	a0,s2
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	e92080e7          	jalr	-366(ra) # 8000325a <brelse>
}
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	64a2                	ld	s1,8(sp)
    800033d6:	6902                	ld	s2,0(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret
    panic("freeing free block");
    800033dc:	00005517          	auipc	a0,0x5
    800033e0:	1a450513          	addi	a0,a0,420 # 80008580 <syscalls+0xe8>
    800033e4:	ffffd097          	auipc	ra,0xffffd
    800033e8:	15c080e7          	jalr	348(ra) # 80000540 <panic>

00000000800033ec <balloc>:
{
    800033ec:	711d                	addi	sp,sp,-96
    800033ee:	ec86                	sd	ra,88(sp)
    800033f0:	e8a2                	sd	s0,80(sp)
    800033f2:	e4a6                	sd	s1,72(sp)
    800033f4:	e0ca                	sd	s2,64(sp)
    800033f6:	fc4e                	sd	s3,56(sp)
    800033f8:	f852                	sd	s4,48(sp)
    800033fa:	f456                	sd	s5,40(sp)
    800033fc:	f05a                	sd	s6,32(sp)
    800033fe:	ec5e                	sd	s7,24(sp)
    80003400:	e862                	sd	s8,16(sp)
    80003402:	e466                	sd	s9,8(sp)
    80003404:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003406:	0001d797          	auipc	a5,0x1d
    8000340a:	63e7a783          	lw	a5,1598(a5) # 80020a44 <sb+0x4>
    8000340e:	cbd1                	beqz	a5,800034a2 <balloc+0xb6>
    80003410:	8baa                	mv	s7,a0
    80003412:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003414:	0001db17          	auipc	s6,0x1d
    80003418:	62cb0b13          	addi	s6,s6,1580 # 80020a40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000341e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003420:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003422:	6c89                	lui	s9,0x2
    80003424:	a831                	j	80003440 <balloc+0x54>
    brelse(bp);
    80003426:	854a                	mv	a0,s2
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	e32080e7          	jalr	-462(ra) # 8000325a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003430:	015c87bb          	addw	a5,s9,s5
    80003434:	00078a9b          	sext.w	s5,a5
    80003438:	004b2703          	lw	a4,4(s6)
    8000343c:	06eaf363          	bgeu	s5,a4,800034a2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003440:	41fad79b          	sraiw	a5,s5,0x1f
    80003444:	0137d79b          	srliw	a5,a5,0x13
    80003448:	015787bb          	addw	a5,a5,s5
    8000344c:	40d7d79b          	sraiw	a5,a5,0xd
    80003450:	01cb2583          	lw	a1,28(s6)
    80003454:	9dbd                	addw	a1,a1,a5
    80003456:	855e                	mv	a0,s7
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	cd2080e7          	jalr	-814(ra) # 8000312a <bread>
    80003460:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003462:	004b2503          	lw	a0,4(s6)
    80003466:	000a849b          	sext.w	s1,s5
    8000346a:	8662                	mv	a2,s8
    8000346c:	faa4fde3          	bgeu	s1,a0,80003426 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003470:	41f6579b          	sraiw	a5,a2,0x1f
    80003474:	01d7d69b          	srliw	a3,a5,0x1d
    80003478:	00c6873b          	addw	a4,a3,a2
    8000347c:	00777793          	andi	a5,a4,7
    80003480:	9f95                	subw	a5,a5,a3
    80003482:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003486:	4037571b          	sraiw	a4,a4,0x3
    8000348a:	00e906b3          	add	a3,s2,a4
    8000348e:	0586c683          	lbu	a3,88(a3)
    80003492:	00d7f5b3          	and	a1,a5,a3
    80003496:	cd91                	beqz	a1,800034b2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003498:	2605                	addiw	a2,a2,1
    8000349a:	2485                	addiw	s1,s1,1
    8000349c:	fd4618e3          	bne	a2,s4,8000346c <balloc+0x80>
    800034a0:	b759                	j	80003426 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	0f650513          	addi	a0,a0,246 # 80008598 <syscalls+0x100>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034b2:	974a                	add	a4,a4,s2
    800034b4:	8fd5                	or	a5,a5,a3
    800034b6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034ba:	854a                	mv	a0,s2
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	008080e7          	jalr	8(ra) # 800044c4 <log_write>
        brelse(bp);
    800034c4:	854a                	mv	a0,s2
    800034c6:	00000097          	auipc	ra,0x0
    800034ca:	d94080e7          	jalr	-620(ra) # 8000325a <brelse>
  bp = bread(dev, bno);
    800034ce:	85a6                	mv	a1,s1
    800034d0:	855e                	mv	a0,s7
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	c58080e7          	jalr	-936(ra) # 8000312a <bread>
    800034da:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034dc:	40000613          	li	a2,1024
    800034e0:	4581                	li	a1,0
    800034e2:	05850513          	addi	a0,a0,88
    800034e6:	ffffe097          	auipc	ra,0xffffe
    800034ea:	812080e7          	jalr	-2030(ra) # 80000cf8 <memset>
  log_write(bp);
    800034ee:	854a                	mv	a0,s2
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	fd4080e7          	jalr	-44(ra) # 800044c4 <log_write>
  brelse(bp);
    800034f8:	854a                	mv	a0,s2
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	d60080e7          	jalr	-672(ra) # 8000325a <brelse>
}
    80003502:	8526                	mv	a0,s1
    80003504:	60e6                	ld	ra,88(sp)
    80003506:	6446                	ld	s0,80(sp)
    80003508:	64a6                	ld	s1,72(sp)
    8000350a:	6906                	ld	s2,64(sp)
    8000350c:	79e2                	ld	s3,56(sp)
    8000350e:	7a42                	ld	s4,48(sp)
    80003510:	7aa2                	ld	s5,40(sp)
    80003512:	7b02                	ld	s6,32(sp)
    80003514:	6be2                	ld	s7,24(sp)
    80003516:	6c42                	ld	s8,16(sp)
    80003518:	6ca2                	ld	s9,8(sp)
    8000351a:	6125                	addi	sp,sp,96
    8000351c:	8082                	ret

000000008000351e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	e052                	sd	s4,0(sp)
    8000352c:	1800                	addi	s0,sp,48
    8000352e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003530:	47ad                	li	a5,11
    80003532:	04b7fe63          	bgeu	a5,a1,8000358e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003536:	ff45849b          	addiw	s1,a1,-12
    8000353a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000353e:	0ff00793          	li	a5,255
    80003542:	0ae7e463          	bltu	a5,a4,800035ea <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003546:	08052583          	lw	a1,128(a0)
    8000354a:	c5b5                	beqz	a1,800035b6 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000354c:	00092503          	lw	a0,0(s2)
    80003550:	00000097          	auipc	ra,0x0
    80003554:	bda080e7          	jalr	-1062(ra) # 8000312a <bread>
    80003558:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000355a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000355e:	02049713          	slli	a4,s1,0x20
    80003562:	01e75593          	srli	a1,a4,0x1e
    80003566:	00b784b3          	add	s1,a5,a1
    8000356a:	0004a983          	lw	s3,0(s1)
    8000356e:	04098e63          	beqz	s3,800035ca <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003572:	8552                	mv	a0,s4
    80003574:	00000097          	auipc	ra,0x0
    80003578:	ce6080e7          	jalr	-794(ra) # 8000325a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000357c:	854e                	mv	a0,s3
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6a02                	ld	s4,0(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000358e:	02059793          	slli	a5,a1,0x20
    80003592:	01e7d593          	srli	a1,a5,0x1e
    80003596:	00b504b3          	add	s1,a0,a1
    8000359a:	0504a983          	lw	s3,80(s1)
    8000359e:	fc099fe3          	bnez	s3,8000357c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035a2:	4108                	lw	a0,0(a0)
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	e48080e7          	jalr	-440(ra) # 800033ec <balloc>
    800035ac:	0005099b          	sext.w	s3,a0
    800035b0:	0534a823          	sw	s3,80(s1)
    800035b4:	b7e1                	j	8000357c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035b6:	4108                	lw	a0,0(a0)
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	e34080e7          	jalr	-460(ra) # 800033ec <balloc>
    800035c0:	0005059b          	sext.w	a1,a0
    800035c4:	08b92023          	sw	a1,128(s2)
    800035c8:	b751                	j	8000354c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035ca:	00092503          	lw	a0,0(s2)
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	e1e080e7          	jalr	-482(ra) # 800033ec <balloc>
    800035d6:	0005099b          	sext.w	s3,a0
    800035da:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035de:	8552                	mv	a0,s4
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	ee4080e7          	jalr	-284(ra) # 800044c4 <log_write>
    800035e8:	b769                	j	80003572 <bmap+0x54>
  panic("bmap: out of range");
    800035ea:	00005517          	auipc	a0,0x5
    800035ee:	fc650513          	addi	a0,a0,-58 # 800085b0 <syscalls+0x118>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	f4e080e7          	jalr	-178(ra) # 80000540 <panic>

00000000800035fa <iget>:
{
    800035fa:	7179                	addi	sp,sp,-48
    800035fc:	f406                	sd	ra,40(sp)
    800035fe:	f022                	sd	s0,32(sp)
    80003600:	ec26                	sd	s1,24(sp)
    80003602:	e84a                	sd	s2,16(sp)
    80003604:	e44e                	sd	s3,8(sp)
    80003606:	e052                	sd	s4,0(sp)
    80003608:	1800                	addi	s0,sp,48
    8000360a:	89aa                	mv	s3,a0
    8000360c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000360e:	0001d517          	auipc	a0,0x1d
    80003612:	45250513          	addi	a0,a0,1106 # 80020a60 <icache>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	5e6080e7          	jalr	1510(ra) # 80000bfc <acquire>
  empty = 0;
    8000361e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003620:	0001d497          	auipc	s1,0x1d
    80003624:	45848493          	addi	s1,s1,1112 # 80020a78 <icache+0x18>
    80003628:	0001f697          	auipc	a3,0x1f
    8000362c:	ee068693          	addi	a3,a3,-288 # 80022508 <log>
    80003630:	a039                	j	8000363e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003632:	02090b63          	beqz	s2,80003668 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003636:	08848493          	addi	s1,s1,136
    8000363a:	02d48a63          	beq	s1,a3,8000366e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000363e:	449c                	lw	a5,8(s1)
    80003640:	fef059e3          	blez	a5,80003632 <iget+0x38>
    80003644:	4098                	lw	a4,0(s1)
    80003646:	ff3716e3          	bne	a4,s3,80003632 <iget+0x38>
    8000364a:	40d8                	lw	a4,4(s1)
    8000364c:	ff4713e3          	bne	a4,s4,80003632 <iget+0x38>
      ip->ref++;
    80003650:	2785                	addiw	a5,a5,1
    80003652:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003654:	0001d517          	auipc	a0,0x1d
    80003658:	40c50513          	addi	a0,a0,1036 # 80020a60 <icache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	654080e7          	jalr	1620(ra) # 80000cb0 <release>
      return ip;
    80003664:	8926                	mv	s2,s1
    80003666:	a03d                	j	80003694 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003668:	f7f9                	bnez	a5,80003636 <iget+0x3c>
    8000366a:	8926                	mv	s2,s1
    8000366c:	b7e9                	j	80003636 <iget+0x3c>
  if(empty == 0)
    8000366e:	02090c63          	beqz	s2,800036a6 <iget+0xac>
  ip->dev = dev;
    80003672:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003676:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000367a:	4785                	li	a5,1
    8000367c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003680:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003684:	0001d517          	auipc	a0,0x1d
    80003688:	3dc50513          	addi	a0,a0,988 # 80020a60 <icache>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	624080e7          	jalr	1572(ra) # 80000cb0 <release>
}
    80003694:	854a                	mv	a0,s2
    80003696:	70a2                	ld	ra,40(sp)
    80003698:	7402                	ld	s0,32(sp)
    8000369a:	64e2                	ld	s1,24(sp)
    8000369c:	6942                	ld	s2,16(sp)
    8000369e:	69a2                	ld	s3,8(sp)
    800036a0:	6a02                	ld	s4,0(sp)
    800036a2:	6145                	addi	sp,sp,48
    800036a4:	8082                	ret
    panic("iget: no inodes");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	f2250513          	addi	a0,a0,-222 # 800085c8 <syscalls+0x130>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e92080e7          	jalr	-366(ra) # 80000540 <panic>

00000000800036b6 <fsinit>:
fsinit(int dev) {
    800036b6:	7179                	addi	sp,sp,-48
    800036b8:	f406                	sd	ra,40(sp)
    800036ba:	f022                	sd	s0,32(sp)
    800036bc:	ec26                	sd	s1,24(sp)
    800036be:	e84a                	sd	s2,16(sp)
    800036c0:	e44e                	sd	s3,8(sp)
    800036c2:	1800                	addi	s0,sp,48
    800036c4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036c6:	4585                	li	a1,1
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	a62080e7          	jalr	-1438(ra) # 8000312a <bread>
    800036d0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036d2:	0001d997          	auipc	s3,0x1d
    800036d6:	36e98993          	addi	s3,s3,878 # 80020a40 <sb>
    800036da:	02000613          	li	a2,32
    800036de:	05850593          	addi	a1,a0,88
    800036e2:	854e                	mv	a0,s3
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	670080e7          	jalr	1648(ra) # 80000d54 <memmove>
  brelse(bp);
    800036ec:	8526                	mv	a0,s1
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	b6c080e7          	jalr	-1172(ra) # 8000325a <brelse>
  if(sb.magic != FSMAGIC)
    800036f6:	0009a703          	lw	a4,0(s3)
    800036fa:	102037b7          	lui	a5,0x10203
    800036fe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003702:	02f71263          	bne	a4,a5,80003726 <fsinit+0x70>
  initlog(dev, &sb);
    80003706:	0001d597          	auipc	a1,0x1d
    8000370a:	33a58593          	addi	a1,a1,826 # 80020a40 <sb>
    8000370e:	854a                	mv	a0,s2
    80003710:	00001097          	auipc	ra,0x1
    80003714:	b3a080e7          	jalr	-1222(ra) # 8000424a <initlog>
}
    80003718:	70a2                	ld	ra,40(sp)
    8000371a:	7402                	ld	s0,32(sp)
    8000371c:	64e2                	ld	s1,24(sp)
    8000371e:	6942                	ld	s2,16(sp)
    80003720:	69a2                	ld	s3,8(sp)
    80003722:	6145                	addi	sp,sp,48
    80003724:	8082                	ret
    panic("invalid file system");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	eb250513          	addi	a0,a0,-334 # 800085d8 <syscalls+0x140>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e12080e7          	jalr	-494(ra) # 80000540 <panic>

0000000080003736 <iinit>:
{
    80003736:	7179                	addi	sp,sp,-48
    80003738:	f406                	sd	ra,40(sp)
    8000373a:	f022                	sd	s0,32(sp)
    8000373c:	ec26                	sd	s1,24(sp)
    8000373e:	e84a                	sd	s2,16(sp)
    80003740:	e44e                	sd	s3,8(sp)
    80003742:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003744:	00005597          	auipc	a1,0x5
    80003748:	eac58593          	addi	a1,a1,-340 # 800085f0 <syscalls+0x158>
    8000374c:	0001d517          	auipc	a0,0x1d
    80003750:	31450513          	addi	a0,a0,788 # 80020a60 <icache>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	418080e7          	jalr	1048(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000375c:	0001d497          	auipc	s1,0x1d
    80003760:	32c48493          	addi	s1,s1,812 # 80020a88 <icache+0x28>
    80003764:	0001f997          	auipc	s3,0x1f
    80003768:	db498993          	addi	s3,s3,-588 # 80022518 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000376c:	00005917          	auipc	s2,0x5
    80003770:	e8c90913          	addi	s2,s2,-372 # 800085f8 <syscalls+0x160>
    80003774:	85ca                	mv	a1,s2
    80003776:	8526                	mv	a0,s1
    80003778:	00001097          	auipc	ra,0x1
    8000377c:	e3a080e7          	jalr	-454(ra) # 800045b2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003780:	08848493          	addi	s1,s1,136
    80003784:	ff3498e3          	bne	s1,s3,80003774 <iinit+0x3e>
}
    80003788:	70a2                	ld	ra,40(sp)
    8000378a:	7402                	ld	s0,32(sp)
    8000378c:	64e2                	ld	s1,24(sp)
    8000378e:	6942                	ld	s2,16(sp)
    80003790:	69a2                	ld	s3,8(sp)
    80003792:	6145                	addi	sp,sp,48
    80003794:	8082                	ret

0000000080003796 <ialloc>:
{
    80003796:	715d                	addi	sp,sp,-80
    80003798:	e486                	sd	ra,72(sp)
    8000379a:	e0a2                	sd	s0,64(sp)
    8000379c:	fc26                	sd	s1,56(sp)
    8000379e:	f84a                	sd	s2,48(sp)
    800037a0:	f44e                	sd	s3,40(sp)
    800037a2:	f052                	sd	s4,32(sp)
    800037a4:	ec56                	sd	s5,24(sp)
    800037a6:	e85a                	sd	s6,16(sp)
    800037a8:	e45e                	sd	s7,8(sp)
    800037aa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ac:	0001d717          	auipc	a4,0x1d
    800037b0:	2a072703          	lw	a4,672(a4) # 80020a4c <sb+0xc>
    800037b4:	4785                	li	a5,1
    800037b6:	04e7fa63          	bgeu	a5,a4,8000380a <ialloc+0x74>
    800037ba:	8aaa                	mv	s5,a0
    800037bc:	8bae                	mv	s7,a1
    800037be:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037c0:	0001da17          	auipc	s4,0x1d
    800037c4:	280a0a13          	addi	s4,s4,640 # 80020a40 <sb>
    800037c8:	00048b1b          	sext.w	s6,s1
    800037cc:	0044d793          	srli	a5,s1,0x4
    800037d0:	018a2583          	lw	a1,24(s4)
    800037d4:	9dbd                	addw	a1,a1,a5
    800037d6:	8556                	mv	a0,s5
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	952080e7          	jalr	-1710(ra) # 8000312a <bread>
    800037e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037e2:	05850993          	addi	s3,a0,88
    800037e6:	00f4f793          	andi	a5,s1,15
    800037ea:	079a                	slli	a5,a5,0x6
    800037ec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037ee:	00099783          	lh	a5,0(s3)
    800037f2:	c785                	beqz	a5,8000381a <ialloc+0x84>
    brelse(bp);
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	a66080e7          	jalr	-1434(ra) # 8000325a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fc:	0485                	addi	s1,s1,1
    800037fe:	00ca2703          	lw	a4,12(s4)
    80003802:	0004879b          	sext.w	a5,s1
    80003806:	fce7e1e3          	bltu	a5,a4,800037c8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000380a:	00005517          	auipc	a0,0x5
    8000380e:	df650513          	addi	a0,a0,-522 # 80008600 <syscalls+0x168>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	d2e080e7          	jalr	-722(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    8000381a:	04000613          	li	a2,64
    8000381e:	4581                	li	a1,0
    80003820:	854e                	mv	a0,s3
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	4d6080e7          	jalr	1238(ra) # 80000cf8 <memset>
      dip->type = type;
    8000382a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	c94080e7          	jalr	-876(ra) # 800044c4 <log_write>
      brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	a20080e7          	jalr	-1504(ra) # 8000325a <brelse>
      return iget(dev, inum);
    80003842:	85da                	mv	a1,s6
    80003844:	8556                	mv	a0,s5
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	db4080e7          	jalr	-588(ra) # 800035fa <iget>
}
    8000384e:	60a6                	ld	ra,72(sp)
    80003850:	6406                	ld	s0,64(sp)
    80003852:	74e2                	ld	s1,56(sp)
    80003854:	7942                	ld	s2,48(sp)
    80003856:	79a2                	ld	s3,40(sp)
    80003858:	7a02                	ld	s4,32(sp)
    8000385a:	6ae2                	ld	s5,24(sp)
    8000385c:	6b42                	ld	s6,16(sp)
    8000385e:	6ba2                	ld	s7,8(sp)
    80003860:	6161                	addi	sp,sp,80
    80003862:	8082                	ret

0000000080003864 <iupdate>:
{
    80003864:	1101                	addi	sp,sp,-32
    80003866:	ec06                	sd	ra,24(sp)
    80003868:	e822                	sd	s0,16(sp)
    8000386a:	e426                	sd	s1,8(sp)
    8000386c:	e04a                	sd	s2,0(sp)
    8000386e:	1000                	addi	s0,sp,32
    80003870:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003872:	415c                	lw	a5,4(a0)
    80003874:	0047d79b          	srliw	a5,a5,0x4
    80003878:	0001d597          	auipc	a1,0x1d
    8000387c:	1e05a583          	lw	a1,480(a1) # 80020a58 <sb+0x18>
    80003880:	9dbd                	addw	a1,a1,a5
    80003882:	4108                	lw	a0,0(a0)
    80003884:	00000097          	auipc	ra,0x0
    80003888:	8a6080e7          	jalr	-1882(ra) # 8000312a <bread>
    8000388c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000388e:	05850793          	addi	a5,a0,88
    80003892:	40c8                	lw	a0,4(s1)
    80003894:	893d                	andi	a0,a0,15
    80003896:	051a                	slli	a0,a0,0x6
    80003898:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000389a:	04449703          	lh	a4,68(s1)
    8000389e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038a2:	04649703          	lh	a4,70(s1)
    800038a6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038aa:	04849703          	lh	a4,72(s1)
    800038ae:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038b2:	04a49703          	lh	a4,74(s1)
    800038b6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038ba:	44f8                	lw	a4,76(s1)
    800038bc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038be:	03400613          	li	a2,52
    800038c2:	05048593          	addi	a1,s1,80
    800038c6:	0531                	addi	a0,a0,12
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	48c080e7          	jalr	1164(ra) # 80000d54 <memmove>
  log_write(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	bf2080e7          	jalr	-1038(ra) # 800044c4 <log_write>
  brelse(bp);
    800038da:	854a                	mv	a0,s2
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	97e080e7          	jalr	-1666(ra) # 8000325a <brelse>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6902                	ld	s2,0(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret

00000000800038f0 <idup>:
{
    800038f0:	1101                	addi	sp,sp,-32
    800038f2:	ec06                	sd	ra,24(sp)
    800038f4:	e822                	sd	s0,16(sp)
    800038f6:	e426                	sd	s1,8(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038fc:	0001d517          	auipc	a0,0x1d
    80003900:	16450513          	addi	a0,a0,356 # 80020a60 <icache>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	2f8080e7          	jalr	760(ra) # 80000bfc <acquire>
  ip->ref++;
    8000390c:	449c                	lw	a5,8(s1)
    8000390e:	2785                	addiw	a5,a5,1
    80003910:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003912:	0001d517          	auipc	a0,0x1d
    80003916:	14e50513          	addi	a0,a0,334 # 80020a60 <icache>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	396080e7          	jalr	918(ra) # 80000cb0 <release>
}
    80003922:	8526                	mv	a0,s1
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6105                	addi	sp,sp,32
    8000392c:	8082                	ret

000000008000392e <ilock>:
{
    8000392e:	1101                	addi	sp,sp,-32
    80003930:	ec06                	sd	ra,24(sp)
    80003932:	e822                	sd	s0,16(sp)
    80003934:	e426                	sd	s1,8(sp)
    80003936:	e04a                	sd	s2,0(sp)
    80003938:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000393a:	c115                	beqz	a0,8000395e <ilock+0x30>
    8000393c:	84aa                	mv	s1,a0
    8000393e:	451c                	lw	a5,8(a0)
    80003940:	00f05f63          	blez	a5,8000395e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003944:	0541                	addi	a0,a0,16
    80003946:	00001097          	auipc	ra,0x1
    8000394a:	ca6080e7          	jalr	-858(ra) # 800045ec <acquiresleep>
  if(ip->valid == 0){
    8000394e:	40bc                	lw	a5,64(s1)
    80003950:	cf99                	beqz	a5,8000396e <ilock+0x40>
}
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6902                	ld	s2,0(sp)
    8000395a:	6105                	addi	sp,sp,32
    8000395c:	8082                	ret
    panic("ilock");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	cba50513          	addi	a0,a0,-838 # 80008618 <syscalls+0x180>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bda080e7          	jalr	-1062(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000396e:	40dc                	lw	a5,4(s1)
    80003970:	0047d79b          	srliw	a5,a5,0x4
    80003974:	0001d597          	auipc	a1,0x1d
    80003978:	0e45a583          	lw	a1,228(a1) # 80020a58 <sb+0x18>
    8000397c:	9dbd                	addw	a1,a1,a5
    8000397e:	4088                	lw	a0,0(s1)
    80003980:	fffff097          	auipc	ra,0xfffff
    80003984:	7aa080e7          	jalr	1962(ra) # 8000312a <bread>
    80003988:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000398a:	05850593          	addi	a1,a0,88
    8000398e:	40dc                	lw	a5,4(s1)
    80003990:	8bbd                	andi	a5,a5,15
    80003992:	079a                	slli	a5,a5,0x6
    80003994:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003996:	00059783          	lh	a5,0(a1)
    8000399a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000399e:	00259783          	lh	a5,2(a1)
    800039a2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039a6:	00459783          	lh	a5,4(a1)
    800039aa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039ae:	00659783          	lh	a5,6(a1)
    800039b2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039b6:	459c                	lw	a5,8(a1)
    800039b8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039ba:	03400613          	li	a2,52
    800039be:	05b1                	addi	a1,a1,12
    800039c0:	05048513          	addi	a0,s1,80
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	390080e7          	jalr	912(ra) # 80000d54 <memmove>
    brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	88c080e7          	jalr	-1908(ra) # 8000325a <brelse>
    ip->valid = 1;
    800039d6:	4785                	li	a5,1
    800039d8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039da:	04449783          	lh	a5,68(s1)
    800039de:	fbb5                	bnez	a5,80003952 <ilock+0x24>
      panic("ilock: no type");
    800039e0:	00005517          	auipc	a0,0x5
    800039e4:	c4050513          	addi	a0,a0,-960 # 80008620 <syscalls+0x188>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	b58080e7          	jalr	-1192(ra) # 80000540 <panic>

00000000800039f0 <iunlock>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039fc:	c905                	beqz	a0,80003a2c <iunlock+0x3c>
    800039fe:	84aa                	mv	s1,a0
    80003a00:	01050913          	addi	s2,a0,16
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	c80080e7          	jalr	-896(ra) # 80004686 <holdingsleep>
    80003a0e:	cd19                	beqz	a0,80003a2c <iunlock+0x3c>
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	00f05d63          	blez	a5,80003a2c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	c2a080e7          	jalr	-982(ra) # 80004642 <releasesleep>
}
    80003a20:	60e2                	ld	ra,24(sp)
    80003a22:	6442                	ld	s0,16(sp)
    80003a24:	64a2                	ld	s1,8(sp)
    80003a26:	6902                	ld	s2,0(sp)
    80003a28:	6105                	addi	sp,sp,32
    80003a2a:	8082                	ret
    panic("iunlock");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	c0450513          	addi	a0,a0,-1020 # 80008630 <syscalls+0x198>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b0c080e7          	jalr	-1268(ra) # 80000540 <panic>

0000000080003a3c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	e052                	sd	s4,0(sp)
    80003a4a:	1800                	addi	s0,sp,48
    80003a4c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a4e:	05050493          	addi	s1,a0,80
    80003a52:	08050913          	addi	s2,a0,128
    80003a56:	a021                	j	80003a5e <itrunc+0x22>
    80003a58:	0491                	addi	s1,s1,4
    80003a5a:	01248d63          	beq	s1,s2,80003a74 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a5e:	408c                	lw	a1,0(s1)
    80003a60:	dde5                	beqz	a1,80003a58 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a62:	0009a503          	lw	a0,0(s3)
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	90a080e7          	jalr	-1782(ra) # 80003370 <bfree>
      ip->addrs[i] = 0;
    80003a6e:	0004a023          	sw	zero,0(s1)
    80003a72:	b7dd                	j	80003a58 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a74:	0809a583          	lw	a1,128(s3)
    80003a78:	e185                	bnez	a1,80003a98 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a7a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a7e:	854e                	mv	a0,s3
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	de4080e7          	jalr	-540(ra) # 80003864 <iupdate>
}
    80003a88:	70a2                	ld	ra,40(sp)
    80003a8a:	7402                	ld	s0,32(sp)
    80003a8c:	64e2                	ld	s1,24(sp)
    80003a8e:	6942                	ld	s2,16(sp)
    80003a90:	69a2                	ld	s3,8(sp)
    80003a92:	6a02                	ld	s4,0(sp)
    80003a94:	6145                	addi	sp,sp,48
    80003a96:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a98:	0009a503          	lw	a0,0(s3)
    80003a9c:	fffff097          	auipc	ra,0xfffff
    80003aa0:	68e080e7          	jalr	1678(ra) # 8000312a <bread>
    80003aa4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aa6:	05850493          	addi	s1,a0,88
    80003aaa:	45850913          	addi	s2,a0,1112
    80003aae:	a021                	j	80003ab6 <itrunc+0x7a>
    80003ab0:	0491                	addi	s1,s1,4
    80003ab2:	01248b63          	beq	s1,s2,80003ac8 <itrunc+0x8c>
      if(a[j])
    80003ab6:	408c                	lw	a1,0(s1)
    80003ab8:	dde5                	beqz	a1,80003ab0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	8b2080e7          	jalr	-1870(ra) # 80003370 <bfree>
    80003ac6:	b7ed                	j	80003ab0 <itrunc+0x74>
    brelse(bp);
    80003ac8:	8552                	mv	a0,s4
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	790080e7          	jalr	1936(ra) # 8000325a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ad2:	0809a583          	lw	a1,128(s3)
    80003ad6:	0009a503          	lw	a0,0(s3)
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	896080e7          	jalr	-1898(ra) # 80003370 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ae2:	0809a023          	sw	zero,128(s3)
    80003ae6:	bf51                	j	80003a7a <itrunc+0x3e>

0000000080003ae8 <iput>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	e04a                	sd	s2,0(sp)
    80003af2:	1000                	addi	s0,sp,32
    80003af4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003af6:	0001d517          	auipc	a0,0x1d
    80003afa:	f6a50513          	addi	a0,a0,-150 # 80020a60 <icache>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	0fe080e7          	jalr	254(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b06:	4498                	lw	a4,8(s1)
    80003b08:	4785                	li	a5,1
    80003b0a:	02f70363          	beq	a4,a5,80003b30 <iput+0x48>
  ip->ref--;
    80003b0e:	449c                	lw	a5,8(s1)
    80003b10:	37fd                	addiw	a5,a5,-1
    80003b12:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b14:	0001d517          	auipc	a0,0x1d
    80003b18:	f4c50513          	addi	a0,a0,-180 # 80020a60 <icache>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	194080e7          	jalr	404(ra) # 80000cb0 <release>
}
    80003b24:	60e2                	ld	ra,24(sp)
    80003b26:	6442                	ld	s0,16(sp)
    80003b28:	64a2                	ld	s1,8(sp)
    80003b2a:	6902                	ld	s2,0(sp)
    80003b2c:	6105                	addi	sp,sp,32
    80003b2e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b30:	40bc                	lw	a5,64(s1)
    80003b32:	dff1                	beqz	a5,80003b0e <iput+0x26>
    80003b34:	04a49783          	lh	a5,74(s1)
    80003b38:	fbf9                	bnez	a5,80003b0e <iput+0x26>
    acquiresleep(&ip->lock);
    80003b3a:	01048913          	addi	s2,s1,16
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00001097          	auipc	ra,0x1
    80003b44:	aac080e7          	jalr	-1364(ra) # 800045ec <acquiresleep>
    release(&icache.lock);
    80003b48:	0001d517          	auipc	a0,0x1d
    80003b4c:	f1850513          	addi	a0,a0,-232 # 80020a60 <icache>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	160080e7          	jalr	352(ra) # 80000cb0 <release>
    itrunc(ip);
    80003b58:	8526                	mv	a0,s1
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	ee2080e7          	jalr	-286(ra) # 80003a3c <itrunc>
    ip->type = 0;
    80003b62:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b66:	8526                	mv	a0,s1
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	cfc080e7          	jalr	-772(ra) # 80003864 <iupdate>
    ip->valid = 0;
    80003b70:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00001097          	auipc	ra,0x1
    80003b7a:	acc080e7          	jalr	-1332(ra) # 80004642 <releasesleep>
    acquire(&icache.lock);
    80003b7e:	0001d517          	auipc	a0,0x1d
    80003b82:	ee250513          	addi	a0,a0,-286 # 80020a60 <icache>
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	076080e7          	jalr	118(ra) # 80000bfc <acquire>
    80003b8e:	b741                	j	80003b0e <iput+0x26>

0000000080003b90 <iunlockput>:
{
    80003b90:	1101                	addi	sp,sp,-32
    80003b92:	ec06                	sd	ra,24(sp)
    80003b94:	e822                	sd	s0,16(sp)
    80003b96:	e426                	sd	s1,8(sp)
    80003b98:	1000                	addi	s0,sp,32
    80003b9a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	e54080e7          	jalr	-428(ra) # 800039f0 <iunlock>
  iput(ip);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	f42080e7          	jalr	-190(ra) # 80003ae8 <iput>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6105                	addi	sp,sp,32
    80003bb6:	8082                	ret

0000000080003bb8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bb8:	1141                	addi	sp,sp,-16
    80003bba:	e422                	sd	s0,8(sp)
    80003bbc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bbe:	411c                	lw	a5,0(a0)
    80003bc0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bc2:	415c                	lw	a5,4(a0)
    80003bc4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bc6:	04451783          	lh	a5,68(a0)
    80003bca:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bce:	04a51783          	lh	a5,74(a0)
    80003bd2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bd6:	04c56783          	lwu	a5,76(a0)
    80003bda:	e99c                	sd	a5,16(a1)
}
    80003bdc:	6422                	ld	s0,8(sp)
    80003bde:	0141                	addi	sp,sp,16
    80003be0:	8082                	ret

0000000080003be2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be2:	457c                	lw	a5,76(a0)
    80003be4:	0ed7e863          	bltu	a5,a3,80003cd4 <readi+0xf2>
{
    80003be8:	7159                	addi	sp,sp,-112
    80003bea:	f486                	sd	ra,104(sp)
    80003bec:	f0a2                	sd	s0,96(sp)
    80003bee:	eca6                	sd	s1,88(sp)
    80003bf0:	e8ca                	sd	s2,80(sp)
    80003bf2:	e4ce                	sd	s3,72(sp)
    80003bf4:	e0d2                	sd	s4,64(sp)
    80003bf6:	fc56                	sd	s5,56(sp)
    80003bf8:	f85a                	sd	s6,48(sp)
    80003bfa:	f45e                	sd	s7,40(sp)
    80003bfc:	f062                	sd	s8,32(sp)
    80003bfe:	ec66                	sd	s9,24(sp)
    80003c00:	e86a                	sd	s10,16(sp)
    80003c02:	e46e                	sd	s11,8(sp)
    80003c04:	1880                	addi	s0,sp,112
    80003c06:	8baa                	mv	s7,a0
    80003c08:	8c2e                	mv	s8,a1
    80003c0a:	8ab2                	mv	s5,a2
    80003c0c:	84b6                	mv	s1,a3
    80003c0e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c10:	9f35                	addw	a4,a4,a3
    return 0;
    80003c12:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c14:	08d76f63          	bltu	a4,a3,80003cb2 <readi+0xd0>
  if(off + n > ip->size)
    80003c18:	00e7f463          	bgeu	a5,a4,80003c20 <readi+0x3e>
    n = ip->size - off;
    80003c1c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c20:	0a0b0863          	beqz	s6,80003cd0 <readi+0xee>
    80003c24:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c26:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c2a:	5cfd                	li	s9,-1
    80003c2c:	a82d                	j	80003c66 <readi+0x84>
    80003c2e:	020a1d93          	slli	s11,s4,0x20
    80003c32:	020ddd93          	srli	s11,s11,0x20
    80003c36:	05890793          	addi	a5,s2,88
    80003c3a:	86ee                	mv	a3,s11
    80003c3c:	963e                	add	a2,a2,a5
    80003c3e:	85d6                	mv	a1,s5
    80003c40:	8562                	mv	a0,s8
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	aec080e7          	jalr	-1300(ra) # 8000272e <either_copyout>
    80003c4a:	05950d63          	beq	a0,s9,80003ca4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c4e:	854a                	mv	a0,s2
    80003c50:	fffff097          	auipc	ra,0xfffff
    80003c54:	60a080e7          	jalr	1546(ra) # 8000325a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c58:	013a09bb          	addw	s3,s4,s3
    80003c5c:	009a04bb          	addw	s1,s4,s1
    80003c60:	9aee                	add	s5,s5,s11
    80003c62:	0569f663          	bgeu	s3,s6,80003cae <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c66:	000ba903          	lw	s2,0(s7)
    80003c6a:	00a4d59b          	srliw	a1,s1,0xa
    80003c6e:	855e                	mv	a0,s7
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	8ae080e7          	jalr	-1874(ra) # 8000351e <bmap>
    80003c78:	0005059b          	sext.w	a1,a0
    80003c7c:	854a                	mv	a0,s2
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	4ac080e7          	jalr	1196(ra) # 8000312a <bread>
    80003c86:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c88:	3ff4f613          	andi	a2,s1,1023
    80003c8c:	40cd07bb          	subw	a5,s10,a2
    80003c90:	413b073b          	subw	a4,s6,s3
    80003c94:	8a3e                	mv	s4,a5
    80003c96:	2781                	sext.w	a5,a5
    80003c98:	0007069b          	sext.w	a3,a4
    80003c9c:	f8f6f9e3          	bgeu	a3,a5,80003c2e <readi+0x4c>
    80003ca0:	8a3a                	mv	s4,a4
    80003ca2:	b771                	j	80003c2e <readi+0x4c>
      brelse(bp);
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	5b4080e7          	jalr	1460(ra) # 8000325a <brelse>
  }
  return tot;
    80003cae:	0009851b          	sext.w	a0,s3
}
    80003cb2:	70a6                	ld	ra,104(sp)
    80003cb4:	7406                	ld	s0,96(sp)
    80003cb6:	64e6                	ld	s1,88(sp)
    80003cb8:	6946                	ld	s2,80(sp)
    80003cba:	69a6                	ld	s3,72(sp)
    80003cbc:	6a06                	ld	s4,64(sp)
    80003cbe:	7ae2                	ld	s5,56(sp)
    80003cc0:	7b42                	ld	s6,48(sp)
    80003cc2:	7ba2                	ld	s7,40(sp)
    80003cc4:	7c02                	ld	s8,32(sp)
    80003cc6:	6ce2                	ld	s9,24(sp)
    80003cc8:	6d42                	ld	s10,16(sp)
    80003cca:	6da2                	ld	s11,8(sp)
    80003ccc:	6165                	addi	sp,sp,112
    80003cce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd0:	89da                	mv	s3,s6
    80003cd2:	bff1                	j	80003cae <readi+0xcc>
    return 0;
    80003cd4:	4501                	li	a0,0
}
    80003cd6:	8082                	ret

0000000080003cd8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cd8:	457c                	lw	a5,76(a0)
    80003cda:	10d7e663          	bltu	a5,a3,80003de6 <writei+0x10e>
{
    80003cde:	7159                	addi	sp,sp,-112
    80003ce0:	f486                	sd	ra,104(sp)
    80003ce2:	f0a2                	sd	s0,96(sp)
    80003ce4:	eca6                	sd	s1,88(sp)
    80003ce6:	e8ca                	sd	s2,80(sp)
    80003ce8:	e4ce                	sd	s3,72(sp)
    80003cea:	e0d2                	sd	s4,64(sp)
    80003cec:	fc56                	sd	s5,56(sp)
    80003cee:	f85a                	sd	s6,48(sp)
    80003cf0:	f45e                	sd	s7,40(sp)
    80003cf2:	f062                	sd	s8,32(sp)
    80003cf4:	ec66                	sd	s9,24(sp)
    80003cf6:	e86a                	sd	s10,16(sp)
    80003cf8:	e46e                	sd	s11,8(sp)
    80003cfa:	1880                	addi	s0,sp,112
    80003cfc:	8baa                	mv	s7,a0
    80003cfe:	8c2e                	mv	s8,a1
    80003d00:	8ab2                	mv	s5,a2
    80003d02:	8936                	mv	s2,a3
    80003d04:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d06:	00e687bb          	addw	a5,a3,a4
    80003d0a:	0ed7e063          	bltu	a5,a3,80003dea <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d0e:	00043737          	lui	a4,0x43
    80003d12:	0cf76e63          	bltu	a4,a5,80003dee <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d16:	0a0b0763          	beqz	s6,80003dc4 <writei+0xec>
    80003d1a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d20:	5cfd                	li	s9,-1
    80003d22:	a091                	j	80003d66 <writei+0x8e>
    80003d24:	02099d93          	slli	s11,s3,0x20
    80003d28:	020ddd93          	srli	s11,s11,0x20
    80003d2c:	05848793          	addi	a5,s1,88
    80003d30:	86ee                	mv	a3,s11
    80003d32:	8656                	mv	a2,s5
    80003d34:	85e2                	mv	a1,s8
    80003d36:	953e                	add	a0,a0,a5
    80003d38:	fffff097          	auipc	ra,0xfffff
    80003d3c:	a4c080e7          	jalr	-1460(ra) # 80002784 <either_copyin>
    80003d40:	07950263          	beq	a0,s9,80003da4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d44:	8526                	mv	a0,s1
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	77e080e7          	jalr	1918(ra) # 800044c4 <log_write>
    brelse(bp);
    80003d4e:	8526                	mv	a0,s1
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	50a080e7          	jalr	1290(ra) # 8000325a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d58:	01498a3b          	addw	s4,s3,s4
    80003d5c:	0129893b          	addw	s2,s3,s2
    80003d60:	9aee                	add	s5,s5,s11
    80003d62:	056a7663          	bgeu	s4,s6,80003dae <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d66:	000ba483          	lw	s1,0(s7)
    80003d6a:	00a9559b          	srliw	a1,s2,0xa
    80003d6e:	855e                	mv	a0,s7
    80003d70:	fffff097          	auipc	ra,0xfffff
    80003d74:	7ae080e7          	jalr	1966(ra) # 8000351e <bmap>
    80003d78:	0005059b          	sext.w	a1,a0
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	3ac080e7          	jalr	940(ra) # 8000312a <bread>
    80003d86:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d88:	3ff97513          	andi	a0,s2,1023
    80003d8c:	40ad07bb          	subw	a5,s10,a0
    80003d90:	414b073b          	subw	a4,s6,s4
    80003d94:	89be                	mv	s3,a5
    80003d96:	2781                	sext.w	a5,a5
    80003d98:	0007069b          	sext.w	a3,a4
    80003d9c:	f8f6f4e3          	bgeu	a3,a5,80003d24 <writei+0x4c>
    80003da0:	89ba                	mv	s3,a4
    80003da2:	b749                	j	80003d24 <writei+0x4c>
      brelse(bp);
    80003da4:	8526                	mv	a0,s1
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	4b4080e7          	jalr	1204(ra) # 8000325a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003dae:	04cba783          	lw	a5,76(s7)
    80003db2:	0127f463          	bgeu	a5,s2,80003dba <writei+0xe2>
      ip->size = off;
    80003db6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003dba:	855e                	mv	a0,s7
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	aa8080e7          	jalr	-1368(ra) # 80003864 <iupdate>
  }

  return n;
    80003dc4:	000b051b          	sext.w	a0,s6
}
    80003dc8:	70a6                	ld	ra,104(sp)
    80003dca:	7406                	ld	s0,96(sp)
    80003dcc:	64e6                	ld	s1,88(sp)
    80003dce:	6946                	ld	s2,80(sp)
    80003dd0:	69a6                	ld	s3,72(sp)
    80003dd2:	6a06                	ld	s4,64(sp)
    80003dd4:	7ae2                	ld	s5,56(sp)
    80003dd6:	7b42                	ld	s6,48(sp)
    80003dd8:	7ba2                	ld	s7,40(sp)
    80003dda:	7c02                	ld	s8,32(sp)
    80003ddc:	6ce2                	ld	s9,24(sp)
    80003dde:	6d42                	ld	s10,16(sp)
    80003de0:	6da2                	ld	s11,8(sp)
    80003de2:	6165                	addi	sp,sp,112
    80003de4:	8082                	ret
    return -1;
    80003de6:	557d                	li	a0,-1
}
    80003de8:	8082                	ret
    return -1;
    80003dea:	557d                	li	a0,-1
    80003dec:	bff1                	j	80003dc8 <writei+0xf0>
    return -1;
    80003dee:	557d                	li	a0,-1
    80003df0:	bfe1                	j	80003dc8 <writei+0xf0>

0000000080003df2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003df2:	1141                	addi	sp,sp,-16
    80003df4:	e406                	sd	ra,8(sp)
    80003df6:	e022                	sd	s0,0(sp)
    80003df8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dfa:	4639                	li	a2,14
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	fd4080e7          	jalr	-44(ra) # 80000dd0 <strncmp>
}
    80003e04:	60a2                	ld	ra,8(sp)
    80003e06:	6402                	ld	s0,0(sp)
    80003e08:	0141                	addi	sp,sp,16
    80003e0a:	8082                	ret

0000000080003e0c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e0c:	7139                	addi	sp,sp,-64
    80003e0e:	fc06                	sd	ra,56(sp)
    80003e10:	f822                	sd	s0,48(sp)
    80003e12:	f426                	sd	s1,40(sp)
    80003e14:	f04a                	sd	s2,32(sp)
    80003e16:	ec4e                	sd	s3,24(sp)
    80003e18:	e852                	sd	s4,16(sp)
    80003e1a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e1c:	04451703          	lh	a4,68(a0)
    80003e20:	4785                	li	a5,1
    80003e22:	00f71a63          	bne	a4,a5,80003e36 <dirlookup+0x2a>
    80003e26:	892a                	mv	s2,a0
    80003e28:	89ae                	mv	s3,a1
    80003e2a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2c:	457c                	lw	a5,76(a0)
    80003e2e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e30:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e32:	e79d                	bnez	a5,80003e60 <dirlookup+0x54>
    80003e34:	a8a5                	j	80003eac <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e36:	00005517          	auipc	a0,0x5
    80003e3a:	80250513          	addi	a0,a0,-2046 # 80008638 <syscalls+0x1a0>
    80003e3e:	ffffc097          	auipc	ra,0xffffc
    80003e42:	702080e7          	jalr	1794(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e46:	00005517          	auipc	a0,0x5
    80003e4a:	80a50513          	addi	a0,a0,-2038 # 80008650 <syscalls+0x1b8>
    80003e4e:	ffffc097          	auipc	ra,0xffffc
    80003e52:	6f2080e7          	jalr	1778(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e56:	24c1                	addiw	s1,s1,16
    80003e58:	04c92783          	lw	a5,76(s2)
    80003e5c:	04f4f763          	bgeu	s1,a5,80003eaa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e60:	4741                	li	a4,16
    80003e62:	86a6                	mv	a3,s1
    80003e64:	fc040613          	addi	a2,s0,-64
    80003e68:	4581                	li	a1,0
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	d76080e7          	jalr	-650(ra) # 80003be2 <readi>
    80003e74:	47c1                	li	a5,16
    80003e76:	fcf518e3          	bne	a0,a5,80003e46 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e7a:	fc045783          	lhu	a5,-64(s0)
    80003e7e:	dfe1                	beqz	a5,80003e56 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e80:	fc240593          	addi	a1,s0,-62
    80003e84:	854e                	mv	a0,s3
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	f6c080e7          	jalr	-148(ra) # 80003df2 <namecmp>
    80003e8e:	f561                	bnez	a0,80003e56 <dirlookup+0x4a>
      if(poff)
    80003e90:	000a0463          	beqz	s4,80003e98 <dirlookup+0x8c>
        *poff = off;
    80003e94:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e98:	fc045583          	lhu	a1,-64(s0)
    80003e9c:	00092503          	lw	a0,0(s2)
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	75a080e7          	jalr	1882(ra) # 800035fa <iget>
    80003ea8:	a011                	j	80003eac <dirlookup+0xa0>
  return 0;
    80003eaa:	4501                	li	a0,0
}
    80003eac:	70e2                	ld	ra,56(sp)
    80003eae:	7442                	ld	s0,48(sp)
    80003eb0:	74a2                	ld	s1,40(sp)
    80003eb2:	7902                	ld	s2,32(sp)
    80003eb4:	69e2                	ld	s3,24(sp)
    80003eb6:	6a42                	ld	s4,16(sp)
    80003eb8:	6121                	addi	sp,sp,64
    80003eba:	8082                	ret

0000000080003ebc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ebc:	711d                	addi	sp,sp,-96
    80003ebe:	ec86                	sd	ra,88(sp)
    80003ec0:	e8a2                	sd	s0,80(sp)
    80003ec2:	e4a6                	sd	s1,72(sp)
    80003ec4:	e0ca                	sd	s2,64(sp)
    80003ec6:	fc4e                	sd	s3,56(sp)
    80003ec8:	f852                	sd	s4,48(sp)
    80003eca:	f456                	sd	s5,40(sp)
    80003ecc:	f05a                	sd	s6,32(sp)
    80003ece:	ec5e                	sd	s7,24(sp)
    80003ed0:	e862                	sd	s8,16(sp)
    80003ed2:	e466                	sd	s9,8(sp)
    80003ed4:	1080                	addi	s0,sp,96
    80003ed6:	84aa                	mv	s1,a0
    80003ed8:	8aae                	mv	s5,a1
    80003eda:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003edc:	00054703          	lbu	a4,0(a0)
    80003ee0:	02f00793          	li	a5,47
    80003ee4:	02f70363          	beq	a4,a5,80003f0a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ee8:	ffffe097          	auipc	ra,0xffffe
    80003eec:	c06080e7          	jalr	-1018(ra) # 80001aee <myproc>
    80003ef0:	15053503          	ld	a0,336(a0)
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	9fc080e7          	jalr	-1540(ra) # 800038f0 <idup>
    80003efc:	89aa                	mv	s3,a0
  while(*path == '/')
    80003efe:	02f00913          	li	s2,47
  len = path - s;
    80003f02:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f04:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f06:	4b85                	li	s7,1
    80003f08:	a865                	j	80003fc0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f0a:	4585                	li	a1,1
    80003f0c:	4505                	li	a0,1
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	6ec080e7          	jalr	1772(ra) # 800035fa <iget>
    80003f16:	89aa                	mv	s3,a0
    80003f18:	b7dd                	j	80003efe <namex+0x42>
      iunlockput(ip);
    80003f1a:	854e                	mv	a0,s3
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	c74080e7          	jalr	-908(ra) # 80003b90 <iunlockput>
      return 0;
    80003f24:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f26:	854e                	mv	a0,s3
    80003f28:	60e6                	ld	ra,88(sp)
    80003f2a:	6446                	ld	s0,80(sp)
    80003f2c:	64a6                	ld	s1,72(sp)
    80003f2e:	6906                	ld	s2,64(sp)
    80003f30:	79e2                	ld	s3,56(sp)
    80003f32:	7a42                	ld	s4,48(sp)
    80003f34:	7aa2                	ld	s5,40(sp)
    80003f36:	7b02                	ld	s6,32(sp)
    80003f38:	6be2                	ld	s7,24(sp)
    80003f3a:	6c42                	ld	s8,16(sp)
    80003f3c:	6ca2                	ld	s9,8(sp)
    80003f3e:	6125                	addi	sp,sp,96
    80003f40:	8082                	ret
      iunlock(ip);
    80003f42:	854e                	mv	a0,s3
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	aac080e7          	jalr	-1364(ra) # 800039f0 <iunlock>
      return ip;
    80003f4c:	bfe9                	j	80003f26 <namex+0x6a>
      iunlockput(ip);
    80003f4e:	854e                	mv	a0,s3
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	c40080e7          	jalr	-960(ra) # 80003b90 <iunlockput>
      return 0;
    80003f58:	89e6                	mv	s3,s9
    80003f5a:	b7f1                	j	80003f26 <namex+0x6a>
  len = path - s;
    80003f5c:	40b48633          	sub	a2,s1,a1
    80003f60:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003f64:	099c5463          	bge	s8,s9,80003fec <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f68:	4639                	li	a2,14
    80003f6a:	8552                	mv	a0,s4
    80003f6c:	ffffd097          	auipc	ra,0xffffd
    80003f70:	de8080e7          	jalr	-536(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003f74:	0004c783          	lbu	a5,0(s1)
    80003f78:	01279763          	bne	a5,s2,80003f86 <namex+0xca>
    path++;
    80003f7c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f7e:	0004c783          	lbu	a5,0(s1)
    80003f82:	ff278de3          	beq	a5,s2,80003f7c <namex+0xc0>
    ilock(ip);
    80003f86:	854e                	mv	a0,s3
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	9a6080e7          	jalr	-1626(ra) # 8000392e <ilock>
    if(ip->type != T_DIR){
    80003f90:	04499783          	lh	a5,68(s3)
    80003f94:	f97793e3          	bne	a5,s7,80003f1a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f98:	000a8563          	beqz	s5,80003fa2 <namex+0xe6>
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	d3cd                	beqz	a5,80003f42 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fa2:	865a                	mv	a2,s6
    80003fa4:	85d2                	mv	a1,s4
    80003fa6:	854e                	mv	a0,s3
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	e64080e7          	jalr	-412(ra) # 80003e0c <dirlookup>
    80003fb0:	8caa                	mv	s9,a0
    80003fb2:	dd51                	beqz	a0,80003f4e <namex+0x92>
    iunlockput(ip);
    80003fb4:	854e                	mv	a0,s3
    80003fb6:	00000097          	auipc	ra,0x0
    80003fba:	bda080e7          	jalr	-1062(ra) # 80003b90 <iunlockput>
    ip = next;
    80003fbe:	89e6                	mv	s3,s9
  while(*path == '/')
    80003fc0:	0004c783          	lbu	a5,0(s1)
    80003fc4:	05279763          	bne	a5,s2,80004012 <namex+0x156>
    path++;
    80003fc8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fca:	0004c783          	lbu	a5,0(s1)
    80003fce:	ff278de3          	beq	a5,s2,80003fc8 <namex+0x10c>
  if(*path == 0)
    80003fd2:	c79d                	beqz	a5,80004000 <namex+0x144>
    path++;
    80003fd4:	85a6                	mv	a1,s1
  len = path - s;
    80003fd6:	8cda                	mv	s9,s6
    80003fd8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003fda:	01278963          	beq	a5,s2,80003fec <namex+0x130>
    80003fde:	dfbd                	beqz	a5,80003f5c <namex+0xa0>
    path++;
    80003fe0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fe2:	0004c783          	lbu	a5,0(s1)
    80003fe6:	ff279ce3          	bne	a5,s2,80003fde <namex+0x122>
    80003fea:	bf8d                	j	80003f5c <namex+0xa0>
    memmove(name, s, len);
    80003fec:	2601                	sext.w	a2,a2
    80003fee:	8552                	mv	a0,s4
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	d64080e7          	jalr	-668(ra) # 80000d54 <memmove>
    name[len] = 0;
    80003ff8:	9cd2                	add	s9,s9,s4
    80003ffa:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ffe:	bf9d                	j	80003f74 <namex+0xb8>
  if(nameiparent){
    80004000:	f20a83e3          	beqz	s5,80003f26 <namex+0x6a>
    iput(ip);
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	ae2080e7          	jalr	-1310(ra) # 80003ae8 <iput>
    return 0;
    8000400e:	4981                	li	s3,0
    80004010:	bf19                	j	80003f26 <namex+0x6a>
  if(*path == 0)
    80004012:	d7fd                	beqz	a5,80004000 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004014:	0004c783          	lbu	a5,0(s1)
    80004018:	85a6                	mv	a1,s1
    8000401a:	b7d1                	j	80003fde <namex+0x122>

000000008000401c <dirlink>:
{
    8000401c:	7139                	addi	sp,sp,-64
    8000401e:	fc06                	sd	ra,56(sp)
    80004020:	f822                	sd	s0,48(sp)
    80004022:	f426                	sd	s1,40(sp)
    80004024:	f04a                	sd	s2,32(sp)
    80004026:	ec4e                	sd	s3,24(sp)
    80004028:	e852                	sd	s4,16(sp)
    8000402a:	0080                	addi	s0,sp,64
    8000402c:	892a                	mv	s2,a0
    8000402e:	8a2e                	mv	s4,a1
    80004030:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004032:	4601                	li	a2,0
    80004034:	00000097          	auipc	ra,0x0
    80004038:	dd8080e7          	jalr	-552(ra) # 80003e0c <dirlookup>
    8000403c:	e93d                	bnez	a0,800040b2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403e:	04c92483          	lw	s1,76(s2)
    80004042:	c49d                	beqz	s1,80004070 <dirlink+0x54>
    80004044:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004046:	4741                	li	a4,16
    80004048:	86a6                	mv	a3,s1
    8000404a:	fc040613          	addi	a2,s0,-64
    8000404e:	4581                	li	a1,0
    80004050:	854a                	mv	a0,s2
    80004052:	00000097          	auipc	ra,0x0
    80004056:	b90080e7          	jalr	-1136(ra) # 80003be2 <readi>
    8000405a:	47c1                	li	a5,16
    8000405c:	06f51163          	bne	a0,a5,800040be <dirlink+0xa2>
    if(de.inum == 0)
    80004060:	fc045783          	lhu	a5,-64(s0)
    80004064:	c791                	beqz	a5,80004070 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004066:	24c1                	addiw	s1,s1,16
    80004068:	04c92783          	lw	a5,76(s2)
    8000406c:	fcf4ede3          	bltu	s1,a5,80004046 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004070:	4639                	li	a2,14
    80004072:	85d2                	mv	a1,s4
    80004074:	fc240513          	addi	a0,s0,-62
    80004078:	ffffd097          	auipc	ra,0xffffd
    8000407c:	d94080e7          	jalr	-620(ra) # 80000e0c <strncpy>
  de.inum = inum;
    80004080:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004084:	4741                	li	a4,16
    80004086:	86a6                	mv	a3,s1
    80004088:	fc040613          	addi	a2,s0,-64
    8000408c:	4581                	li	a1,0
    8000408e:	854a                	mv	a0,s2
    80004090:	00000097          	auipc	ra,0x0
    80004094:	c48080e7          	jalr	-952(ra) # 80003cd8 <writei>
    80004098:	872a                	mv	a4,a0
    8000409a:	47c1                	li	a5,16
  return 0;
    8000409c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409e:	02f71863          	bne	a4,a5,800040ce <dirlink+0xb2>
}
    800040a2:	70e2                	ld	ra,56(sp)
    800040a4:	7442                	ld	s0,48(sp)
    800040a6:	74a2                	ld	s1,40(sp)
    800040a8:	7902                	ld	s2,32(sp)
    800040aa:	69e2                	ld	s3,24(sp)
    800040ac:	6a42                	ld	s4,16(sp)
    800040ae:	6121                	addi	sp,sp,64
    800040b0:	8082                	ret
    iput(ip);
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	a36080e7          	jalr	-1482(ra) # 80003ae8 <iput>
    return -1;
    800040ba:	557d                	li	a0,-1
    800040bc:	b7dd                	j	800040a2 <dirlink+0x86>
      panic("dirlink read");
    800040be:	00004517          	auipc	a0,0x4
    800040c2:	5a250513          	addi	a0,a0,1442 # 80008660 <syscalls+0x1c8>
    800040c6:	ffffc097          	auipc	ra,0xffffc
    800040ca:	47a080e7          	jalr	1146(ra) # 80000540 <panic>
    panic("dirlink");
    800040ce:	00004517          	auipc	a0,0x4
    800040d2:	6b250513          	addi	a0,a0,1714 # 80008780 <syscalls+0x2e8>
    800040d6:	ffffc097          	auipc	ra,0xffffc
    800040da:	46a080e7          	jalr	1130(ra) # 80000540 <panic>

00000000800040de <namei>:

struct inode*
namei(char *path)
{
    800040de:	1101                	addi	sp,sp,-32
    800040e0:	ec06                	sd	ra,24(sp)
    800040e2:	e822                	sd	s0,16(sp)
    800040e4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040e6:	fe040613          	addi	a2,s0,-32
    800040ea:	4581                	li	a1,0
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	dd0080e7          	jalr	-560(ra) # 80003ebc <namex>
}
    800040f4:	60e2                	ld	ra,24(sp)
    800040f6:	6442                	ld	s0,16(sp)
    800040f8:	6105                	addi	sp,sp,32
    800040fa:	8082                	ret

00000000800040fc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040fc:	1141                	addi	sp,sp,-16
    800040fe:	e406                	sd	ra,8(sp)
    80004100:	e022                	sd	s0,0(sp)
    80004102:	0800                	addi	s0,sp,16
    80004104:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004106:	4585                	li	a1,1
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	db4080e7          	jalr	-588(ra) # 80003ebc <namex>
}
    80004110:	60a2                	ld	ra,8(sp)
    80004112:	6402                	ld	s0,0(sp)
    80004114:	0141                	addi	sp,sp,16
    80004116:	8082                	ret

0000000080004118 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004118:	1101                	addi	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	e426                	sd	s1,8(sp)
    80004120:	e04a                	sd	s2,0(sp)
    80004122:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004124:	0001e917          	auipc	s2,0x1e
    80004128:	3e490913          	addi	s2,s2,996 # 80022508 <log>
    8000412c:	01892583          	lw	a1,24(s2)
    80004130:	02892503          	lw	a0,40(s2)
    80004134:	fffff097          	auipc	ra,0xfffff
    80004138:	ff6080e7          	jalr	-10(ra) # 8000312a <bread>
    8000413c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000413e:	02c92683          	lw	a3,44(s2)
    80004142:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004144:	02d05863          	blez	a3,80004174 <write_head+0x5c>
    80004148:	0001e797          	auipc	a5,0x1e
    8000414c:	3f078793          	addi	a5,a5,1008 # 80022538 <log+0x30>
    80004150:	05c50713          	addi	a4,a0,92
    80004154:	36fd                	addiw	a3,a3,-1
    80004156:	02069613          	slli	a2,a3,0x20
    8000415a:	01e65693          	srli	a3,a2,0x1e
    8000415e:	0001e617          	auipc	a2,0x1e
    80004162:	3de60613          	addi	a2,a2,990 # 8002253c <log+0x34>
    80004166:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004168:	4390                	lw	a2,0(a5)
    8000416a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000416c:	0791                	addi	a5,a5,4
    8000416e:	0711                	addi	a4,a4,4
    80004170:	fed79ce3          	bne	a5,a3,80004168 <write_head+0x50>
  }
  bwrite(buf);
    80004174:	8526                	mv	a0,s1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	0a6080e7          	jalr	166(ra) # 8000321c <bwrite>
  brelse(buf);
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	0da080e7          	jalr	218(ra) # 8000325a <brelse>
}
    80004188:	60e2                	ld	ra,24(sp)
    8000418a:	6442                	ld	s0,16(sp)
    8000418c:	64a2                	ld	s1,8(sp)
    8000418e:	6902                	ld	s2,0(sp)
    80004190:	6105                	addi	sp,sp,32
    80004192:	8082                	ret

0000000080004194 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004194:	0001e797          	auipc	a5,0x1e
    80004198:	3a07a783          	lw	a5,928(a5) # 80022534 <log+0x2c>
    8000419c:	0af05663          	blez	a5,80004248 <install_trans+0xb4>
{
    800041a0:	7139                	addi	sp,sp,-64
    800041a2:	fc06                	sd	ra,56(sp)
    800041a4:	f822                	sd	s0,48(sp)
    800041a6:	f426                	sd	s1,40(sp)
    800041a8:	f04a                	sd	s2,32(sp)
    800041aa:	ec4e                	sd	s3,24(sp)
    800041ac:	e852                	sd	s4,16(sp)
    800041ae:	e456                	sd	s5,8(sp)
    800041b0:	0080                	addi	s0,sp,64
    800041b2:	0001ea97          	auipc	s5,0x1e
    800041b6:	386a8a93          	addi	s5,s5,902 # 80022538 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041bc:	0001e997          	auipc	s3,0x1e
    800041c0:	34c98993          	addi	s3,s3,844 # 80022508 <log>
    800041c4:	0189a583          	lw	a1,24(s3)
    800041c8:	014585bb          	addw	a1,a1,s4
    800041cc:	2585                	addiw	a1,a1,1
    800041ce:	0289a503          	lw	a0,40(s3)
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	f58080e7          	jalr	-168(ra) # 8000312a <bread>
    800041da:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041dc:	000aa583          	lw	a1,0(s5)
    800041e0:	0289a503          	lw	a0,40(s3)
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	f46080e7          	jalr	-186(ra) # 8000312a <bread>
    800041ec:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ee:	40000613          	li	a2,1024
    800041f2:	05890593          	addi	a1,s2,88
    800041f6:	05850513          	addi	a0,a0,88
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	b5a080e7          	jalr	-1190(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	018080e7          	jalr	24(ra) # 8000321c <bwrite>
    bunpin(dbuf);
    8000420c:	8526                	mv	a0,s1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	126080e7          	jalr	294(ra) # 80003334 <bunpin>
    brelse(lbuf);
    80004216:	854a                	mv	a0,s2
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	042080e7          	jalr	66(ra) # 8000325a <brelse>
    brelse(dbuf);
    80004220:	8526                	mv	a0,s1
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	038080e7          	jalr	56(ra) # 8000325a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422a:	2a05                	addiw	s4,s4,1
    8000422c:	0a91                	addi	s5,s5,4
    8000422e:	02c9a783          	lw	a5,44(s3)
    80004232:	f8fa49e3          	blt	s4,a5,800041c4 <install_trans+0x30>
}
    80004236:	70e2                	ld	ra,56(sp)
    80004238:	7442                	ld	s0,48(sp)
    8000423a:	74a2                	ld	s1,40(sp)
    8000423c:	7902                	ld	s2,32(sp)
    8000423e:	69e2                	ld	s3,24(sp)
    80004240:	6a42                	ld	s4,16(sp)
    80004242:	6aa2                	ld	s5,8(sp)
    80004244:	6121                	addi	sp,sp,64
    80004246:	8082                	ret
    80004248:	8082                	ret

000000008000424a <initlog>:
{
    8000424a:	7179                	addi	sp,sp,-48
    8000424c:	f406                	sd	ra,40(sp)
    8000424e:	f022                	sd	s0,32(sp)
    80004250:	ec26                	sd	s1,24(sp)
    80004252:	e84a                	sd	s2,16(sp)
    80004254:	e44e                	sd	s3,8(sp)
    80004256:	1800                	addi	s0,sp,48
    80004258:	892a                	mv	s2,a0
    8000425a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000425c:	0001e497          	auipc	s1,0x1e
    80004260:	2ac48493          	addi	s1,s1,684 # 80022508 <log>
    80004264:	00004597          	auipc	a1,0x4
    80004268:	40c58593          	addi	a1,a1,1036 # 80008670 <syscalls+0x1d8>
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	8fe080e7          	jalr	-1794(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    80004276:	0149a583          	lw	a1,20(s3)
    8000427a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000427c:	0109a783          	lw	a5,16(s3)
    80004280:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004282:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004286:	854a                	mv	a0,s2
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	ea2080e7          	jalr	-350(ra) # 8000312a <bread>
  log.lh.n = lh->n;
    80004290:	4d34                	lw	a3,88(a0)
    80004292:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004294:	02d05663          	blez	a3,800042c0 <initlog+0x76>
    80004298:	05c50793          	addi	a5,a0,92
    8000429c:	0001e717          	auipc	a4,0x1e
    800042a0:	29c70713          	addi	a4,a4,668 # 80022538 <log+0x30>
    800042a4:	36fd                	addiw	a3,a3,-1
    800042a6:	02069613          	slli	a2,a3,0x20
    800042aa:	01e65693          	srli	a3,a2,0x1e
    800042ae:	06050613          	addi	a2,a0,96
    800042b2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042b4:	4390                	lw	a2,0(a5)
    800042b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042b8:	0791                	addi	a5,a5,4
    800042ba:	0711                	addi	a4,a4,4
    800042bc:	fed79ce3          	bne	a5,a3,800042b4 <initlog+0x6a>
  brelse(buf);
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	f9a080e7          	jalr	-102(ra) # 8000325a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800042c8:	00000097          	auipc	ra,0x0
    800042cc:	ecc080e7          	jalr	-308(ra) # 80004194 <install_trans>
  log.lh.n = 0;
    800042d0:	0001e797          	auipc	a5,0x1e
    800042d4:	2607a223          	sw	zero,612(a5) # 80022534 <log+0x2c>
  write_head(); // clear the log
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	e40080e7          	jalr	-448(ra) # 80004118 <write_head>
}
    800042e0:	70a2                	ld	ra,40(sp)
    800042e2:	7402                	ld	s0,32(sp)
    800042e4:	64e2                	ld	s1,24(sp)
    800042e6:	6942                	ld	s2,16(sp)
    800042e8:	69a2                	ld	s3,8(sp)
    800042ea:	6145                	addi	sp,sp,48
    800042ec:	8082                	ret

00000000800042ee <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042ee:	1101                	addi	sp,sp,-32
    800042f0:	ec06                	sd	ra,24(sp)
    800042f2:	e822                	sd	s0,16(sp)
    800042f4:	e426                	sd	s1,8(sp)
    800042f6:	e04a                	sd	s2,0(sp)
    800042f8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042fa:	0001e517          	auipc	a0,0x1e
    800042fe:	20e50513          	addi	a0,a0,526 # 80022508 <log>
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	8fa080e7          	jalr	-1798(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    8000430a:	0001e497          	auipc	s1,0x1e
    8000430e:	1fe48493          	addi	s1,s1,510 # 80022508 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004312:	4979                	li	s2,30
    80004314:	a039                	j	80004322 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004316:	85a6                	mv	a1,s1
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	19e080e7          	jalr	414(ra) # 800024b8 <sleep>
    if(log.committing){
    80004322:	50dc                	lw	a5,36(s1)
    80004324:	fbed                	bnez	a5,80004316 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004326:	509c                	lw	a5,32(s1)
    80004328:	0017871b          	addiw	a4,a5,1
    8000432c:	0007069b          	sext.w	a3,a4
    80004330:	0027179b          	slliw	a5,a4,0x2
    80004334:	9fb9                	addw	a5,a5,a4
    80004336:	0017979b          	slliw	a5,a5,0x1
    8000433a:	54d8                	lw	a4,44(s1)
    8000433c:	9fb9                	addw	a5,a5,a4
    8000433e:	00f95963          	bge	s2,a5,80004350 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004342:	85a6                	mv	a1,s1
    80004344:	8526                	mv	a0,s1
    80004346:	ffffe097          	auipc	ra,0xffffe
    8000434a:	172080e7          	jalr	370(ra) # 800024b8 <sleep>
    8000434e:	bfd1                	j	80004322 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004350:	0001e517          	auipc	a0,0x1e
    80004354:	1b850513          	addi	a0,a0,440 # 80022508 <log>
    80004358:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	956080e7          	jalr	-1706(ra) # 80000cb0 <release>
      break;
    }
  }
}
    80004362:	60e2                	ld	ra,24(sp)
    80004364:	6442                	ld	s0,16(sp)
    80004366:	64a2                	ld	s1,8(sp)
    80004368:	6902                	ld	s2,0(sp)
    8000436a:	6105                	addi	sp,sp,32
    8000436c:	8082                	ret

000000008000436e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000436e:	7139                	addi	sp,sp,-64
    80004370:	fc06                	sd	ra,56(sp)
    80004372:	f822                	sd	s0,48(sp)
    80004374:	f426                	sd	s1,40(sp)
    80004376:	f04a                	sd	s2,32(sp)
    80004378:	ec4e                	sd	s3,24(sp)
    8000437a:	e852                	sd	s4,16(sp)
    8000437c:	e456                	sd	s5,8(sp)
    8000437e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004380:	0001e497          	auipc	s1,0x1e
    80004384:	18848493          	addi	s1,s1,392 # 80022508 <log>
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	872080e7          	jalr	-1934(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    80004392:	509c                	lw	a5,32(s1)
    80004394:	37fd                	addiw	a5,a5,-1
    80004396:	0007891b          	sext.w	s2,a5
    8000439a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000439c:	50dc                	lw	a5,36(s1)
    8000439e:	e7b9                	bnez	a5,800043ec <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043a0:	04091e63          	bnez	s2,800043fc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043a4:	0001e497          	auipc	s1,0x1e
    800043a8:	16448493          	addi	s1,s1,356 # 80022508 <log>
    800043ac:	4785                	li	a5,1
    800043ae:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	8fe080e7          	jalr	-1794(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043ba:	54dc                	lw	a5,44(s1)
    800043bc:	06f04763          	bgtz	a5,8000442a <end_op+0xbc>
    acquire(&log.lock);
    800043c0:	0001e497          	auipc	s1,0x1e
    800043c4:	14848493          	addi	s1,s1,328 # 80022508 <log>
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	832080e7          	jalr	-1998(ra) # 80000bfc <acquire>
    log.committing = 0;
    800043d2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	26c080e7          	jalr	620(ra) # 80002644 <wakeup>
    release(&log.lock);
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8ce080e7          	jalr	-1842(ra) # 80000cb0 <release>
}
    800043ea:	a03d                	j	80004418 <end_op+0xaa>
    panic("log.committing");
    800043ec:	00004517          	auipc	a0,0x4
    800043f0:	28c50513          	addi	a0,a0,652 # 80008678 <syscalls+0x1e0>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	14c080e7          	jalr	332(ra) # 80000540 <panic>
    wakeup(&log);
    800043fc:	0001e497          	auipc	s1,0x1e
    80004400:	10c48493          	addi	s1,s1,268 # 80022508 <log>
    80004404:	8526                	mv	a0,s1
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	23e080e7          	jalr	574(ra) # 80002644 <wakeup>
  release(&log.lock);
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	8a0080e7          	jalr	-1888(ra) # 80000cb0 <release>
}
    80004418:	70e2                	ld	ra,56(sp)
    8000441a:	7442                	ld	s0,48(sp)
    8000441c:	74a2                	ld	s1,40(sp)
    8000441e:	7902                	ld	s2,32(sp)
    80004420:	69e2                	ld	s3,24(sp)
    80004422:	6a42                	ld	s4,16(sp)
    80004424:	6aa2                	ld	s5,8(sp)
    80004426:	6121                	addi	sp,sp,64
    80004428:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000442a:	0001ea97          	auipc	s5,0x1e
    8000442e:	10ea8a93          	addi	s5,s5,270 # 80022538 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004432:	0001ea17          	auipc	s4,0x1e
    80004436:	0d6a0a13          	addi	s4,s4,214 # 80022508 <log>
    8000443a:	018a2583          	lw	a1,24(s4)
    8000443e:	012585bb          	addw	a1,a1,s2
    80004442:	2585                	addiw	a1,a1,1
    80004444:	028a2503          	lw	a0,40(s4)
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	ce2080e7          	jalr	-798(ra) # 8000312a <bread>
    80004450:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004452:	000aa583          	lw	a1,0(s5)
    80004456:	028a2503          	lw	a0,40(s4)
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	cd0080e7          	jalr	-816(ra) # 8000312a <bread>
    80004462:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004464:	40000613          	li	a2,1024
    80004468:	05850593          	addi	a1,a0,88
    8000446c:	05848513          	addi	a0,s1,88
    80004470:	ffffd097          	auipc	ra,0xffffd
    80004474:	8e4080e7          	jalr	-1820(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    80004478:	8526                	mv	a0,s1
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	da2080e7          	jalr	-606(ra) # 8000321c <bwrite>
    brelse(from);
    80004482:	854e                	mv	a0,s3
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	dd6080e7          	jalr	-554(ra) # 8000325a <brelse>
    brelse(to);
    8000448c:	8526                	mv	a0,s1
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	dcc080e7          	jalr	-564(ra) # 8000325a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004496:	2905                	addiw	s2,s2,1
    80004498:	0a91                	addi	s5,s5,4
    8000449a:	02ca2783          	lw	a5,44(s4)
    8000449e:	f8f94ee3          	blt	s2,a5,8000443a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	c76080e7          	jalr	-906(ra) # 80004118 <write_head>
    install_trans(); // Now install writes to home locations
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	cea080e7          	jalr	-790(ra) # 80004194 <install_trans>
    log.lh.n = 0;
    800044b2:	0001e797          	auipc	a5,0x1e
    800044b6:	0807a123          	sw	zero,130(a5) # 80022534 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	c5e080e7          	jalr	-930(ra) # 80004118 <write_head>
    800044c2:	bdfd                	j	800043c0 <end_op+0x52>

00000000800044c4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044d0:	0001e717          	auipc	a4,0x1e
    800044d4:	06472703          	lw	a4,100(a4) # 80022534 <log+0x2c>
    800044d8:	47f5                	li	a5,29
    800044da:	08e7c063          	blt	a5,a4,8000455a <log_write+0x96>
    800044de:	84aa                	mv	s1,a0
    800044e0:	0001e797          	auipc	a5,0x1e
    800044e4:	0447a783          	lw	a5,68(a5) # 80022524 <log+0x1c>
    800044e8:	37fd                	addiw	a5,a5,-1
    800044ea:	06f75863          	bge	a4,a5,8000455a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044ee:	0001e797          	auipc	a5,0x1e
    800044f2:	03a7a783          	lw	a5,58(a5) # 80022528 <log+0x20>
    800044f6:	06f05a63          	blez	a5,8000456a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044fa:	0001e917          	auipc	s2,0x1e
    800044fe:	00e90913          	addi	s2,s2,14 # 80022508 <log>
    80004502:	854a                	mv	a0,s2
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6f8080e7          	jalr	1784(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000450c:	02c92603          	lw	a2,44(s2)
    80004510:	06c05563          	blez	a2,8000457a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004514:	44cc                	lw	a1,12(s1)
    80004516:	0001e717          	auipc	a4,0x1e
    8000451a:	02270713          	addi	a4,a4,34 # 80022538 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000451e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004520:	4314                	lw	a3,0(a4)
    80004522:	04b68d63          	beq	a3,a1,8000457c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004526:	2785                	addiw	a5,a5,1
    80004528:	0711                	addi	a4,a4,4
    8000452a:	fec79be3          	bne	a5,a2,80004520 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000452e:	0621                	addi	a2,a2,8
    80004530:	060a                	slli	a2,a2,0x2
    80004532:	0001e797          	auipc	a5,0x1e
    80004536:	fd678793          	addi	a5,a5,-42 # 80022508 <log>
    8000453a:	963e                	add	a2,a2,a5
    8000453c:	44dc                	lw	a5,12(s1)
    8000453e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004540:	8526                	mv	a0,s1
    80004542:	fffff097          	auipc	ra,0xfffff
    80004546:	db6080e7          	jalr	-586(ra) # 800032f8 <bpin>
    log.lh.n++;
    8000454a:	0001e717          	auipc	a4,0x1e
    8000454e:	fbe70713          	addi	a4,a4,-66 # 80022508 <log>
    80004552:	575c                	lw	a5,44(a4)
    80004554:	2785                	addiw	a5,a5,1
    80004556:	d75c                	sw	a5,44(a4)
    80004558:	a83d                	j	80004596 <log_write+0xd2>
    panic("too big a transaction");
    8000455a:	00004517          	auipc	a0,0x4
    8000455e:	12e50513          	addi	a0,a0,302 # 80008688 <syscalls+0x1f0>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	fde080e7          	jalr	-34(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000456a:	00004517          	auipc	a0,0x4
    8000456e:	13650513          	addi	a0,a0,310 # 800086a0 <syscalls+0x208>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	fce080e7          	jalr	-50(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000457c:	00878713          	addi	a4,a5,8
    80004580:	00271693          	slli	a3,a4,0x2
    80004584:	0001e717          	auipc	a4,0x1e
    80004588:	f8470713          	addi	a4,a4,-124 # 80022508 <log>
    8000458c:	9736                	add	a4,a4,a3
    8000458e:	44d4                	lw	a3,12(s1)
    80004590:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004592:	faf607e3          	beq	a2,a5,80004540 <log_write+0x7c>
  }
  release(&log.lock);
    80004596:	0001e517          	auipc	a0,0x1e
    8000459a:	f7250513          	addi	a0,a0,-142 # 80022508 <log>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	712080e7          	jalr	1810(ra) # 80000cb0 <release>
}
    800045a6:	60e2                	ld	ra,24(sp)
    800045a8:	6442                	ld	s0,16(sp)
    800045aa:	64a2                	ld	s1,8(sp)
    800045ac:	6902                	ld	s2,0(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	e04a                	sd	s2,0(sp)
    800045bc:	1000                	addi	s0,sp,32
    800045be:	84aa                	mv	s1,a0
    800045c0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045c2:	00004597          	auipc	a1,0x4
    800045c6:	0fe58593          	addi	a1,a1,254 # 800086c0 <syscalls+0x228>
    800045ca:	0521                	addi	a0,a0,8
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	5a0080e7          	jalr	1440(ra) # 80000b6c <initlock>
  lk->name = name;
    800045d4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045d8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045dc:	0204a423          	sw	zero,40(s1)
}
    800045e0:	60e2                	ld	ra,24(sp)
    800045e2:	6442                	ld	s0,16(sp)
    800045e4:	64a2                	ld	s1,8(sp)
    800045e6:	6902                	ld	s2,0(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	e426                	sd	s1,8(sp)
    800045f4:	e04a                	sd	s2,0(sp)
    800045f6:	1000                	addi	s0,sp,32
    800045f8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045fa:	00850913          	addi	s2,a0,8
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5fc080e7          	jalr	1532(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004608:	409c                	lw	a5,0(s1)
    8000460a:	cb89                	beqz	a5,8000461c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000460c:	85ca                	mv	a1,s2
    8000460e:	8526                	mv	a0,s1
    80004610:	ffffe097          	auipc	ra,0xffffe
    80004614:	ea8080e7          	jalr	-344(ra) # 800024b8 <sleep>
  while (lk->locked) {
    80004618:	409c                	lw	a5,0(s1)
    8000461a:	fbed                	bnez	a5,8000460c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000461c:	4785                	li	a5,1
    8000461e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004620:	ffffd097          	auipc	ra,0xffffd
    80004624:	4ce080e7          	jalr	1230(ra) # 80001aee <myproc>
    80004628:	5d1c                	lw	a5,56(a0)
    8000462a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	682080e7          	jalr	1666(ra) # 80000cb0 <release>
}
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6902                	ld	s2,0(sp)
    8000463e:	6105                	addi	sp,sp,32
    80004640:	8082                	ret

0000000080004642 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
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
  lk->locked = 0;
    8000465e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004662:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	fdc080e7          	jalr	-36(ra) # 80002644 <wakeup>
  release(&lk->lk);
    80004670:	854a                	mv	a0,s2
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	63e080e7          	jalr	1598(ra) # 80000cb0 <release>
}
    8000467a:	60e2                	ld	ra,24(sp)
    8000467c:	6442                	ld	s0,16(sp)
    8000467e:	64a2                	ld	s1,8(sp)
    80004680:	6902                	ld	s2,0(sp)
    80004682:	6105                	addi	sp,sp,32
    80004684:	8082                	ret

0000000080004686 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004686:	7179                	addi	sp,sp,-48
    80004688:	f406                	sd	ra,40(sp)
    8000468a:	f022                	sd	s0,32(sp)
    8000468c:	ec26                	sd	s1,24(sp)
    8000468e:	e84a                	sd	s2,16(sp)
    80004690:	e44e                	sd	s3,8(sp)
    80004692:	1800                	addi	s0,sp,48
    80004694:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004696:	00850913          	addi	s2,a0,8
    8000469a:	854a                	mv	a0,s2
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	560080e7          	jalr	1376(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046a4:	409c                	lw	a5,0(s1)
    800046a6:	ef99                	bnez	a5,800046c4 <holdingsleep+0x3e>
    800046a8:	4481                	li	s1,0
  release(&lk->lk);
    800046aa:	854a                	mv	a0,s2
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	604080e7          	jalr	1540(ra) # 80000cb0 <release>
  return r;
}
    800046b4:	8526                	mv	a0,s1
    800046b6:	70a2                	ld	ra,40(sp)
    800046b8:	7402                	ld	s0,32(sp)
    800046ba:	64e2                	ld	s1,24(sp)
    800046bc:	6942                	ld	s2,16(sp)
    800046be:	69a2                	ld	s3,8(sp)
    800046c0:	6145                	addi	sp,sp,48
    800046c2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c4:	0284a983          	lw	s3,40(s1)
    800046c8:	ffffd097          	auipc	ra,0xffffd
    800046cc:	426080e7          	jalr	1062(ra) # 80001aee <myproc>
    800046d0:	5d04                	lw	s1,56(a0)
    800046d2:	413484b3          	sub	s1,s1,s3
    800046d6:	0014b493          	seqz	s1,s1
    800046da:	bfc1                	j	800046aa <holdingsleep+0x24>

00000000800046dc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046dc:	1141                	addi	sp,sp,-16
    800046de:	e406                	sd	ra,8(sp)
    800046e0:	e022                	sd	s0,0(sp)
    800046e2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046e4:	00004597          	auipc	a1,0x4
    800046e8:	fec58593          	addi	a1,a1,-20 # 800086d0 <syscalls+0x238>
    800046ec:	0001e517          	auipc	a0,0x1e
    800046f0:	f6450513          	addi	a0,a0,-156 # 80022650 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	478080e7          	jalr	1144(ra) # 80000b6c <initlock>
}
    800046fc:	60a2                	ld	ra,8(sp)
    800046fe:	6402                	ld	s0,0(sp)
    80004700:	0141                	addi	sp,sp,16
    80004702:	8082                	ret

0000000080004704 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004704:	1101                	addi	sp,sp,-32
    80004706:	ec06                	sd	ra,24(sp)
    80004708:	e822                	sd	s0,16(sp)
    8000470a:	e426                	sd	s1,8(sp)
    8000470c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000470e:	0001e517          	auipc	a0,0x1e
    80004712:	f4250513          	addi	a0,a0,-190 # 80022650 <ftable>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	4e6080e7          	jalr	1254(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000471e:	0001e497          	auipc	s1,0x1e
    80004722:	f4a48493          	addi	s1,s1,-182 # 80022668 <ftable+0x18>
    80004726:	0001f717          	auipc	a4,0x1f
    8000472a:	ee270713          	addi	a4,a4,-286 # 80023608 <ftable+0xfb8>
    if(f->ref == 0){
    8000472e:	40dc                	lw	a5,4(s1)
    80004730:	cf99                	beqz	a5,8000474e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004732:	02848493          	addi	s1,s1,40
    80004736:	fee49ce3          	bne	s1,a4,8000472e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000473a:	0001e517          	auipc	a0,0x1e
    8000473e:	f1650513          	addi	a0,a0,-234 # 80022650 <ftable>
    80004742:	ffffc097          	auipc	ra,0xffffc
    80004746:	56e080e7          	jalr	1390(ra) # 80000cb0 <release>
  return 0;
    8000474a:	4481                	li	s1,0
    8000474c:	a819                	j	80004762 <filealloc+0x5e>
      f->ref = 1;
    8000474e:	4785                	li	a5,1
    80004750:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004752:	0001e517          	auipc	a0,0x1e
    80004756:	efe50513          	addi	a0,a0,-258 # 80022650 <ftable>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	556080e7          	jalr	1366(ra) # 80000cb0 <release>
}
    80004762:	8526                	mv	a0,s1
    80004764:	60e2                	ld	ra,24(sp)
    80004766:	6442                	ld	s0,16(sp)
    80004768:	64a2                	ld	s1,8(sp)
    8000476a:	6105                	addi	sp,sp,32
    8000476c:	8082                	ret

000000008000476e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000476e:	1101                	addi	sp,sp,-32
    80004770:	ec06                	sd	ra,24(sp)
    80004772:	e822                	sd	s0,16(sp)
    80004774:	e426                	sd	s1,8(sp)
    80004776:	1000                	addi	s0,sp,32
    80004778:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000477a:	0001e517          	auipc	a0,0x1e
    8000477e:	ed650513          	addi	a0,a0,-298 # 80022650 <ftable>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	47a080e7          	jalr	1146(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000478a:	40dc                	lw	a5,4(s1)
    8000478c:	02f05263          	blez	a5,800047b0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004790:	2785                	addiw	a5,a5,1
    80004792:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004794:	0001e517          	auipc	a0,0x1e
    80004798:	ebc50513          	addi	a0,a0,-324 # 80022650 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	514080e7          	jalr	1300(ra) # 80000cb0 <release>
  return f;
}
    800047a4:	8526                	mv	a0,s1
    800047a6:	60e2                	ld	ra,24(sp)
    800047a8:	6442                	ld	s0,16(sp)
    800047aa:	64a2                	ld	s1,8(sp)
    800047ac:	6105                	addi	sp,sp,32
    800047ae:	8082                	ret
    panic("filedup");
    800047b0:	00004517          	auipc	a0,0x4
    800047b4:	f2850513          	addi	a0,a0,-216 # 800086d8 <syscalls+0x240>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	d88080e7          	jalr	-632(ra) # 80000540 <panic>

00000000800047c0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047c0:	7139                	addi	sp,sp,-64
    800047c2:	fc06                	sd	ra,56(sp)
    800047c4:	f822                	sd	s0,48(sp)
    800047c6:	f426                	sd	s1,40(sp)
    800047c8:	f04a                	sd	s2,32(sp)
    800047ca:	ec4e                	sd	s3,24(sp)
    800047cc:	e852                	sd	s4,16(sp)
    800047ce:	e456                	sd	s5,8(sp)
    800047d0:	0080                	addi	s0,sp,64
    800047d2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047d4:	0001e517          	auipc	a0,0x1e
    800047d8:	e7c50513          	addi	a0,a0,-388 # 80022650 <ftable>
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	420080e7          	jalr	1056(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047e4:	40dc                	lw	a5,4(s1)
    800047e6:	06f05163          	blez	a5,80004848 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ea:	37fd                	addiw	a5,a5,-1
    800047ec:	0007871b          	sext.w	a4,a5
    800047f0:	c0dc                	sw	a5,4(s1)
    800047f2:	06e04363          	bgtz	a4,80004858 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047f6:	0004a903          	lw	s2,0(s1)
    800047fa:	0094ca83          	lbu	s5,9(s1)
    800047fe:	0104ba03          	ld	s4,16(s1)
    80004802:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004806:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000480a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000480e:	0001e517          	auipc	a0,0x1e
    80004812:	e4250513          	addi	a0,a0,-446 # 80022650 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	49a080e7          	jalr	1178(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    8000481e:	4785                	li	a5,1
    80004820:	04f90d63          	beq	s2,a5,8000487a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004824:	3979                	addiw	s2,s2,-2
    80004826:	4785                	li	a5,1
    80004828:	0527e063          	bltu	a5,s2,80004868 <fileclose+0xa8>
    begin_op();
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	ac2080e7          	jalr	-1342(ra) # 800042ee <begin_op>
    iput(ff.ip);
    80004834:	854e                	mv	a0,s3
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	2b2080e7          	jalr	690(ra) # 80003ae8 <iput>
    end_op();
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	b30080e7          	jalr	-1232(ra) # 8000436e <end_op>
    80004846:	a00d                	j	80004868 <fileclose+0xa8>
    panic("fileclose");
    80004848:	00004517          	auipc	a0,0x4
    8000484c:	e9850513          	addi	a0,a0,-360 # 800086e0 <syscalls+0x248>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	cf0080e7          	jalr	-784(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004858:	0001e517          	auipc	a0,0x1e
    8000485c:	df850513          	addi	a0,a0,-520 # 80022650 <ftable>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	450080e7          	jalr	1104(ra) # 80000cb0 <release>
  }
}
    80004868:	70e2                	ld	ra,56(sp)
    8000486a:	7442                	ld	s0,48(sp)
    8000486c:	74a2                	ld	s1,40(sp)
    8000486e:	7902                	ld	s2,32(sp)
    80004870:	69e2                	ld	s3,24(sp)
    80004872:	6a42                	ld	s4,16(sp)
    80004874:	6aa2                	ld	s5,8(sp)
    80004876:	6121                	addi	sp,sp,64
    80004878:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000487a:	85d6                	mv	a1,s5
    8000487c:	8552                	mv	a0,s4
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	372080e7          	jalr	882(ra) # 80004bf0 <pipeclose>
    80004886:	b7cd                	j	80004868 <fileclose+0xa8>

0000000080004888 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004888:	715d                	addi	sp,sp,-80
    8000488a:	e486                	sd	ra,72(sp)
    8000488c:	e0a2                	sd	s0,64(sp)
    8000488e:	fc26                	sd	s1,56(sp)
    80004890:	f84a                	sd	s2,48(sp)
    80004892:	f44e                	sd	s3,40(sp)
    80004894:	0880                	addi	s0,sp,80
    80004896:	84aa                	mv	s1,a0
    80004898:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000489a:	ffffd097          	auipc	ra,0xffffd
    8000489e:	254080e7          	jalr	596(ra) # 80001aee <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048a2:	409c                	lw	a5,0(s1)
    800048a4:	37f9                	addiw	a5,a5,-2
    800048a6:	4705                	li	a4,1
    800048a8:	04f76763          	bltu	a4,a5,800048f6 <filestat+0x6e>
    800048ac:	892a                	mv	s2,a0
    ilock(f->ip);
    800048ae:	6c88                	ld	a0,24(s1)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	07e080e7          	jalr	126(ra) # 8000392e <ilock>
    stati(f->ip, &st);
    800048b8:	fb840593          	addi	a1,s0,-72
    800048bc:	6c88                	ld	a0,24(s1)
    800048be:	fffff097          	auipc	ra,0xfffff
    800048c2:	2fa080e7          	jalr	762(ra) # 80003bb8 <stati>
    iunlock(f->ip);
    800048c6:	6c88                	ld	a0,24(s1)
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	128080e7          	jalr	296(ra) # 800039f0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048d0:	46e1                	li	a3,24
    800048d2:	fb840613          	addi	a2,s0,-72
    800048d6:	85ce                	mv	a1,s3
    800048d8:	05093503          	ld	a0,80(s2)
    800048dc:	ffffd097          	auipc	ra,0xffffd
    800048e0:	dce080e7          	jalr	-562(ra) # 800016aa <copyout>
    800048e4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048e8:	60a6                	ld	ra,72(sp)
    800048ea:	6406                	ld	s0,64(sp)
    800048ec:	74e2                	ld	s1,56(sp)
    800048ee:	7942                	ld	s2,48(sp)
    800048f0:	79a2                	ld	s3,40(sp)
    800048f2:	6161                	addi	sp,sp,80
    800048f4:	8082                	ret
  return -1;
    800048f6:	557d                	li	a0,-1
    800048f8:	bfc5                	j	800048e8 <filestat+0x60>

00000000800048fa <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048fa:	7179                	addi	sp,sp,-48
    800048fc:	f406                	sd	ra,40(sp)
    800048fe:	f022                	sd	s0,32(sp)
    80004900:	ec26                	sd	s1,24(sp)
    80004902:	e84a                	sd	s2,16(sp)
    80004904:	e44e                	sd	s3,8(sp)
    80004906:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004908:	00854783          	lbu	a5,8(a0)
    8000490c:	c3d5                	beqz	a5,800049b0 <fileread+0xb6>
    8000490e:	84aa                	mv	s1,a0
    80004910:	89ae                	mv	s3,a1
    80004912:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004914:	411c                	lw	a5,0(a0)
    80004916:	4705                	li	a4,1
    80004918:	04e78963          	beq	a5,a4,8000496a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000491c:	470d                	li	a4,3
    8000491e:	04e78d63          	beq	a5,a4,80004978 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004922:	4709                	li	a4,2
    80004924:	06e79e63          	bne	a5,a4,800049a0 <fileread+0xa6>
    ilock(f->ip);
    80004928:	6d08                	ld	a0,24(a0)
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	004080e7          	jalr	4(ra) # 8000392e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004932:	874a                	mv	a4,s2
    80004934:	5094                	lw	a3,32(s1)
    80004936:	864e                	mv	a2,s3
    80004938:	4585                	li	a1,1
    8000493a:	6c88                	ld	a0,24(s1)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	2a6080e7          	jalr	678(ra) # 80003be2 <readi>
    80004944:	892a                	mv	s2,a0
    80004946:	00a05563          	blez	a0,80004950 <fileread+0x56>
      f->off += r;
    8000494a:	509c                	lw	a5,32(s1)
    8000494c:	9fa9                	addw	a5,a5,a0
    8000494e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004950:	6c88                	ld	a0,24(s1)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	09e080e7          	jalr	158(ra) # 800039f0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000495a:	854a                	mv	a0,s2
    8000495c:	70a2                	ld	ra,40(sp)
    8000495e:	7402                	ld	s0,32(sp)
    80004960:	64e2                	ld	s1,24(sp)
    80004962:	6942                	ld	s2,16(sp)
    80004964:	69a2                	ld	s3,8(sp)
    80004966:	6145                	addi	sp,sp,48
    80004968:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000496a:	6908                	ld	a0,16(a0)
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	3f4080e7          	jalr	1012(ra) # 80004d60 <piperead>
    80004974:	892a                	mv	s2,a0
    80004976:	b7d5                	j	8000495a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004978:	02451783          	lh	a5,36(a0)
    8000497c:	03079693          	slli	a3,a5,0x30
    80004980:	92c1                	srli	a3,a3,0x30
    80004982:	4725                	li	a4,9
    80004984:	02d76863          	bltu	a4,a3,800049b4 <fileread+0xba>
    80004988:	0792                	slli	a5,a5,0x4
    8000498a:	0001e717          	auipc	a4,0x1e
    8000498e:	c2670713          	addi	a4,a4,-986 # 800225b0 <devsw>
    80004992:	97ba                	add	a5,a5,a4
    80004994:	639c                	ld	a5,0(a5)
    80004996:	c38d                	beqz	a5,800049b8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004998:	4505                	li	a0,1
    8000499a:	9782                	jalr	a5
    8000499c:	892a                	mv	s2,a0
    8000499e:	bf75                	j	8000495a <fileread+0x60>
    panic("fileread");
    800049a0:	00004517          	auipc	a0,0x4
    800049a4:	d5050513          	addi	a0,a0,-688 # 800086f0 <syscalls+0x258>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	b98080e7          	jalr	-1128(ra) # 80000540 <panic>
    return -1;
    800049b0:	597d                	li	s2,-1
    800049b2:	b765                	j	8000495a <fileread+0x60>
      return -1;
    800049b4:	597d                	li	s2,-1
    800049b6:	b755                	j	8000495a <fileread+0x60>
    800049b8:	597d                	li	s2,-1
    800049ba:	b745                	j	8000495a <fileread+0x60>

00000000800049bc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049bc:	00954783          	lbu	a5,9(a0)
    800049c0:	14078563          	beqz	a5,80004b0a <filewrite+0x14e>
{
    800049c4:	715d                	addi	sp,sp,-80
    800049c6:	e486                	sd	ra,72(sp)
    800049c8:	e0a2                	sd	s0,64(sp)
    800049ca:	fc26                	sd	s1,56(sp)
    800049cc:	f84a                	sd	s2,48(sp)
    800049ce:	f44e                	sd	s3,40(sp)
    800049d0:	f052                	sd	s4,32(sp)
    800049d2:	ec56                	sd	s5,24(sp)
    800049d4:	e85a                	sd	s6,16(sp)
    800049d6:	e45e                	sd	s7,8(sp)
    800049d8:	e062                	sd	s8,0(sp)
    800049da:	0880                	addi	s0,sp,80
    800049dc:	892a                	mv	s2,a0
    800049de:	8aae                	mv	s5,a1
    800049e0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049e2:	411c                	lw	a5,0(a0)
    800049e4:	4705                	li	a4,1
    800049e6:	02e78263          	beq	a5,a4,80004a0a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ea:	470d                	li	a4,3
    800049ec:	02e78563          	beq	a5,a4,80004a16 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049f0:	4709                	li	a4,2
    800049f2:	10e79463          	bne	a5,a4,80004afa <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049f6:	0ec05e63          	blez	a2,80004af2 <filewrite+0x136>
    int i = 0;
    800049fa:	4981                	li	s3,0
    800049fc:	6b05                	lui	s6,0x1
    800049fe:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a02:	6b85                	lui	s7,0x1
    80004a04:	c00b8b9b          	addiw	s7,s7,-1024
    80004a08:	a851                	j	80004a9c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a0a:	6908                	ld	a0,16(a0)
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	254080e7          	jalr	596(ra) # 80004c60 <pipewrite>
    80004a14:	a85d                	j	80004aca <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a16:	02451783          	lh	a5,36(a0)
    80004a1a:	03079693          	slli	a3,a5,0x30
    80004a1e:	92c1                	srli	a3,a3,0x30
    80004a20:	4725                	li	a4,9
    80004a22:	0ed76663          	bltu	a4,a3,80004b0e <filewrite+0x152>
    80004a26:	0792                	slli	a5,a5,0x4
    80004a28:	0001e717          	auipc	a4,0x1e
    80004a2c:	b8870713          	addi	a4,a4,-1144 # 800225b0 <devsw>
    80004a30:	97ba                	add	a5,a5,a4
    80004a32:	679c                	ld	a5,8(a5)
    80004a34:	cff9                	beqz	a5,80004b12 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a36:	4505                	li	a0,1
    80004a38:	9782                	jalr	a5
    80004a3a:	a841                	j	80004aca <filewrite+0x10e>
    80004a3c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	8ae080e7          	jalr	-1874(ra) # 800042ee <begin_op>
      ilock(f->ip);
    80004a48:	01893503          	ld	a0,24(s2)
    80004a4c:	fffff097          	auipc	ra,0xfffff
    80004a50:	ee2080e7          	jalr	-286(ra) # 8000392e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a54:	8762                	mv	a4,s8
    80004a56:	02092683          	lw	a3,32(s2)
    80004a5a:	01598633          	add	a2,s3,s5
    80004a5e:	4585                	li	a1,1
    80004a60:	01893503          	ld	a0,24(s2)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	274080e7          	jalr	628(ra) # 80003cd8 <writei>
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	02a05f63          	blez	a0,80004aac <filewrite+0xf0>
        f->off += r;
    80004a72:	02092783          	lw	a5,32(s2)
    80004a76:	9fa9                	addw	a5,a5,a0
    80004a78:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a7c:	01893503          	ld	a0,24(s2)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	f70080e7          	jalr	-144(ra) # 800039f0 <iunlock>
      end_op();
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	8e6080e7          	jalr	-1818(ra) # 8000436e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a90:	049c1963          	bne	s8,s1,80004ae2 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a94:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a98:	0349d663          	bge	s3,s4,80004ac4 <filewrite+0x108>
      int n1 = n - i;
    80004a9c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aa0:	84be                	mv	s1,a5
    80004aa2:	2781                	sext.w	a5,a5
    80004aa4:	f8fb5ce3          	bge	s6,a5,80004a3c <filewrite+0x80>
    80004aa8:	84de                	mv	s1,s7
    80004aaa:	bf49                	j	80004a3c <filewrite+0x80>
      iunlock(f->ip);
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	f40080e7          	jalr	-192(ra) # 800039f0 <iunlock>
      end_op();
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	8b6080e7          	jalr	-1866(ra) # 8000436e <end_op>
      if(r < 0)
    80004ac0:	fc04d8e3          	bgez	s1,80004a90 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ac4:	8552                	mv	a0,s4
    80004ac6:	033a1863          	bne	s4,s3,80004af6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aca:	60a6                	ld	ra,72(sp)
    80004acc:	6406                	ld	s0,64(sp)
    80004ace:	74e2                	ld	s1,56(sp)
    80004ad0:	7942                	ld	s2,48(sp)
    80004ad2:	79a2                	ld	s3,40(sp)
    80004ad4:	7a02                	ld	s4,32(sp)
    80004ad6:	6ae2                	ld	s5,24(sp)
    80004ad8:	6b42                	ld	s6,16(sp)
    80004ada:	6ba2                	ld	s7,8(sp)
    80004adc:	6c02                	ld	s8,0(sp)
    80004ade:	6161                	addi	sp,sp,80
    80004ae0:	8082                	ret
        panic("short filewrite");
    80004ae2:	00004517          	auipc	a0,0x4
    80004ae6:	c1e50513          	addi	a0,a0,-994 # 80008700 <syscalls+0x268>
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	a56080e7          	jalr	-1450(ra) # 80000540 <panic>
    int i = 0;
    80004af2:	4981                	li	s3,0
    80004af4:	bfc1                	j	80004ac4 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004af6:	557d                	li	a0,-1
    80004af8:	bfc9                	j	80004aca <filewrite+0x10e>
    panic("filewrite");
    80004afa:	00004517          	auipc	a0,0x4
    80004afe:	c1650513          	addi	a0,a0,-1002 # 80008710 <syscalls+0x278>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	a3e080e7          	jalr	-1474(ra) # 80000540 <panic>
    return -1;
    80004b0a:	557d                	li	a0,-1
}
    80004b0c:	8082                	ret
      return -1;
    80004b0e:	557d                	li	a0,-1
    80004b10:	bf6d                	j	80004aca <filewrite+0x10e>
    80004b12:	557d                	li	a0,-1
    80004b14:	bf5d                	j	80004aca <filewrite+0x10e>

0000000080004b16 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b16:	7179                	addi	sp,sp,-48
    80004b18:	f406                	sd	ra,40(sp)
    80004b1a:	f022                	sd	s0,32(sp)
    80004b1c:	ec26                	sd	s1,24(sp)
    80004b1e:	e84a                	sd	s2,16(sp)
    80004b20:	e44e                	sd	s3,8(sp)
    80004b22:	e052                	sd	s4,0(sp)
    80004b24:	1800                	addi	s0,sp,48
    80004b26:	84aa                	mv	s1,a0
    80004b28:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b2a:	0005b023          	sd	zero,0(a1)
    80004b2e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	bd2080e7          	jalr	-1070(ra) # 80004704 <filealloc>
    80004b3a:	e088                	sd	a0,0(s1)
    80004b3c:	c551                	beqz	a0,80004bc8 <pipealloc+0xb2>
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	bc6080e7          	jalr	-1082(ra) # 80004704 <filealloc>
    80004b46:	00aa3023          	sd	a0,0(s4)
    80004b4a:	c92d                	beqz	a0,80004bbc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	fc0080e7          	jalr	-64(ra) # 80000b0c <kalloc>
    80004b54:	892a                	mv	s2,a0
    80004b56:	c125                	beqz	a0,80004bb6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b58:	4985                	li	s3,1
    80004b5a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b5e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b62:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b66:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b6a:	00004597          	auipc	a1,0x4
    80004b6e:	bb658593          	addi	a1,a1,-1098 # 80008720 <syscalls+0x288>
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	ffa080e7          	jalr	-6(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004b7a:	609c                	ld	a5,0(s1)
    80004b7c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b80:	609c                	ld	a5,0(s1)
    80004b82:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b86:	609c                	ld	a5,0(s1)
    80004b88:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b8c:	609c                	ld	a5,0(s1)
    80004b8e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b92:	000a3783          	ld	a5,0(s4)
    80004b96:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b9a:	000a3783          	ld	a5,0(s4)
    80004b9e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ba2:	000a3783          	ld	a5,0(s4)
    80004ba6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004baa:	000a3783          	ld	a5,0(s4)
    80004bae:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bb2:	4501                	li	a0,0
    80004bb4:	a025                	j	80004bdc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bb6:	6088                	ld	a0,0(s1)
    80004bb8:	e501                	bnez	a0,80004bc0 <pipealloc+0xaa>
    80004bba:	a039                	j	80004bc8 <pipealloc+0xb2>
    80004bbc:	6088                	ld	a0,0(s1)
    80004bbe:	c51d                	beqz	a0,80004bec <pipealloc+0xd6>
    fileclose(*f0);
    80004bc0:	00000097          	auipc	ra,0x0
    80004bc4:	c00080e7          	jalr	-1024(ra) # 800047c0 <fileclose>
  if(*f1)
    80004bc8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bcc:	557d                	li	a0,-1
  if(*f1)
    80004bce:	c799                	beqz	a5,80004bdc <pipealloc+0xc6>
    fileclose(*f1);
    80004bd0:	853e                	mv	a0,a5
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	bee080e7          	jalr	-1042(ra) # 800047c0 <fileclose>
  return -1;
    80004bda:	557d                	li	a0,-1
}
    80004bdc:	70a2                	ld	ra,40(sp)
    80004bde:	7402                	ld	s0,32(sp)
    80004be0:	64e2                	ld	s1,24(sp)
    80004be2:	6942                	ld	s2,16(sp)
    80004be4:	69a2                	ld	s3,8(sp)
    80004be6:	6a02                	ld	s4,0(sp)
    80004be8:	6145                	addi	sp,sp,48
    80004bea:	8082                	ret
  return -1;
    80004bec:	557d                	li	a0,-1
    80004bee:	b7fd                	j	80004bdc <pipealloc+0xc6>

0000000080004bf0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bf0:	1101                	addi	sp,sp,-32
    80004bf2:	ec06                	sd	ra,24(sp)
    80004bf4:	e822                	sd	s0,16(sp)
    80004bf6:	e426                	sd	s1,8(sp)
    80004bf8:	e04a                	sd	s2,0(sp)
    80004bfa:	1000                	addi	s0,sp,32
    80004bfc:	84aa                	mv	s1,a0
    80004bfe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	ffc080e7          	jalr	-4(ra) # 80000bfc <acquire>
  if(writable){
    80004c08:	02090d63          	beqz	s2,80004c42 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c0c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c10:	21848513          	addi	a0,s1,536
    80004c14:	ffffe097          	auipc	ra,0xffffe
    80004c18:	a30080e7          	jalr	-1488(ra) # 80002644 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c1c:	2204b783          	ld	a5,544(s1)
    80004c20:	eb95                	bnez	a5,80004c54 <pipeclose+0x64>
    release(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	08c080e7          	jalr	140(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c2c:	8526                	mv	a0,s1
    80004c2e:	ffffc097          	auipc	ra,0xffffc
    80004c32:	de2080e7          	jalr	-542(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c36:	60e2                	ld	ra,24(sp)
    80004c38:	6442                	ld	s0,16(sp)
    80004c3a:	64a2                	ld	s1,8(sp)
    80004c3c:	6902                	ld	s2,0(sp)
    80004c3e:	6105                	addi	sp,sp,32
    80004c40:	8082                	ret
    pi->readopen = 0;
    80004c42:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c46:	21c48513          	addi	a0,s1,540
    80004c4a:	ffffe097          	auipc	ra,0xffffe
    80004c4e:	9fa080e7          	jalr	-1542(ra) # 80002644 <wakeup>
    80004c52:	b7e9                	j	80004c1c <pipeclose+0x2c>
    release(&pi->lock);
    80004c54:	8526                	mv	a0,s1
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	05a080e7          	jalr	90(ra) # 80000cb0 <release>
}
    80004c5e:	bfe1                	j	80004c36 <pipeclose+0x46>

0000000080004c60 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c60:	711d                	addi	sp,sp,-96
    80004c62:	ec86                	sd	ra,88(sp)
    80004c64:	e8a2                	sd	s0,80(sp)
    80004c66:	e4a6                	sd	s1,72(sp)
    80004c68:	e0ca                	sd	s2,64(sp)
    80004c6a:	fc4e                	sd	s3,56(sp)
    80004c6c:	f852                	sd	s4,48(sp)
    80004c6e:	f456                	sd	s5,40(sp)
    80004c70:	f05a                	sd	s6,32(sp)
    80004c72:	ec5e                	sd	s7,24(sp)
    80004c74:	e862                	sd	s8,16(sp)
    80004c76:	1080                	addi	s0,sp,96
    80004c78:	84aa                	mv	s1,a0
    80004c7a:	8b2e                	mv	s6,a1
    80004c7c:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	e70080e7          	jalr	-400(ra) # 80001aee <myproc>
    80004c86:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	f72080e7          	jalr	-142(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004c92:	09505763          	blez	s5,80004d20 <pipewrite+0xc0>
    80004c96:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c98:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c9c:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca0:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ca2:	2184a783          	lw	a5,536(s1)
    80004ca6:	21c4a703          	lw	a4,540(s1)
    80004caa:	2007879b          	addiw	a5,a5,512
    80004cae:	02f71b63          	bne	a4,a5,80004ce4 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004cb2:	2204a783          	lw	a5,544(s1)
    80004cb6:	c3d1                	beqz	a5,80004d3a <pipewrite+0xda>
    80004cb8:	03092783          	lw	a5,48(s2)
    80004cbc:	efbd                	bnez	a5,80004d3a <pipewrite+0xda>
      wakeup(&pi->nread);
    80004cbe:	8552                	mv	a0,s4
    80004cc0:	ffffe097          	auipc	ra,0xffffe
    80004cc4:	984080e7          	jalr	-1660(ra) # 80002644 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cc8:	85a6                	mv	a1,s1
    80004cca:	854e                	mv	a0,s3
    80004ccc:	ffffd097          	auipc	ra,0xffffd
    80004cd0:	7ec080e7          	jalr	2028(ra) # 800024b8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cd4:	2184a783          	lw	a5,536(s1)
    80004cd8:	21c4a703          	lw	a4,540(s1)
    80004cdc:	2007879b          	addiw	a5,a5,512
    80004ce0:	fcf709e3          	beq	a4,a5,80004cb2 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce4:	4685                	li	a3,1
    80004ce6:	865a                	mv	a2,s6
    80004ce8:	faf40593          	addi	a1,s0,-81
    80004cec:	05093503          	ld	a0,80(s2)
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	a46080e7          	jalr	-1466(ra) # 80001736 <copyin>
    80004cf8:	03850563          	beq	a0,s8,80004d22 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cfc:	21c4a783          	lw	a5,540(s1)
    80004d00:	0017871b          	addiw	a4,a5,1
    80004d04:	20e4ae23          	sw	a4,540(s1)
    80004d08:	1ff7f793          	andi	a5,a5,511
    80004d0c:	97a6                	add	a5,a5,s1
    80004d0e:	faf44703          	lbu	a4,-81(s0)
    80004d12:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d16:	2b85                	addiw	s7,s7,1
    80004d18:	0b05                	addi	s6,s6,1
    80004d1a:	f97a94e3          	bne	s5,s7,80004ca2 <pipewrite+0x42>
    80004d1e:	a011                	j	80004d22 <pipewrite+0xc2>
    80004d20:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d22:	21848513          	addi	a0,s1,536
    80004d26:	ffffe097          	auipc	ra,0xffffe
    80004d2a:	91e080e7          	jalr	-1762(ra) # 80002644 <wakeup>
  release(&pi->lock);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	f80080e7          	jalr	-128(ra) # 80000cb0 <release>
  return i;
    80004d38:	a039                	j	80004d46 <pipewrite+0xe6>
        release(&pi->lock);
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f74080e7          	jalr	-140(ra) # 80000cb0 <release>
        return -1;
    80004d44:	5bfd                	li	s7,-1
}
    80004d46:	855e                	mv	a0,s7
    80004d48:	60e6                	ld	ra,88(sp)
    80004d4a:	6446                	ld	s0,80(sp)
    80004d4c:	64a6                	ld	s1,72(sp)
    80004d4e:	6906                	ld	s2,64(sp)
    80004d50:	79e2                	ld	s3,56(sp)
    80004d52:	7a42                	ld	s4,48(sp)
    80004d54:	7aa2                	ld	s5,40(sp)
    80004d56:	7b02                	ld	s6,32(sp)
    80004d58:	6be2                	ld	s7,24(sp)
    80004d5a:	6c42                	ld	s8,16(sp)
    80004d5c:	6125                	addi	sp,sp,96
    80004d5e:	8082                	ret

0000000080004d60 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d60:	715d                	addi	sp,sp,-80
    80004d62:	e486                	sd	ra,72(sp)
    80004d64:	e0a2                	sd	s0,64(sp)
    80004d66:	fc26                	sd	s1,56(sp)
    80004d68:	f84a                	sd	s2,48(sp)
    80004d6a:	f44e                	sd	s3,40(sp)
    80004d6c:	f052                	sd	s4,32(sp)
    80004d6e:	ec56                	sd	s5,24(sp)
    80004d70:	e85a                	sd	s6,16(sp)
    80004d72:	0880                	addi	s0,sp,80
    80004d74:	84aa                	mv	s1,a0
    80004d76:	892e                	mv	s2,a1
    80004d78:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	d74080e7          	jalr	-652(ra) # 80001aee <myproc>
    80004d82:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	e76080e7          	jalr	-394(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d8e:	2184a703          	lw	a4,536(s1)
    80004d92:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d96:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9a:	02f71463          	bne	a4,a5,80004dc2 <piperead+0x62>
    80004d9e:	2244a783          	lw	a5,548(s1)
    80004da2:	c385                	beqz	a5,80004dc2 <piperead+0x62>
    if(pr->killed){
    80004da4:	030a2783          	lw	a5,48(s4)
    80004da8:	ebc1                	bnez	a5,80004e38 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004daa:	85a6                	mv	a1,s1
    80004dac:	854e                	mv	a0,s3
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	70a080e7          	jalr	1802(ra) # 800024b8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db6:	2184a703          	lw	a4,536(s1)
    80004dba:	21c4a783          	lw	a5,540(s1)
    80004dbe:	fef700e3          	beq	a4,a5,80004d9e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc6:	05505363          	blez	s5,80004e0c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004dca:	2184a783          	lw	a5,536(s1)
    80004dce:	21c4a703          	lw	a4,540(s1)
    80004dd2:	02f70d63          	beq	a4,a5,80004e0c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dd6:	0017871b          	addiw	a4,a5,1
    80004dda:	20e4ac23          	sw	a4,536(s1)
    80004dde:	1ff7f793          	andi	a5,a5,511
    80004de2:	97a6                	add	a5,a5,s1
    80004de4:	0187c783          	lbu	a5,24(a5)
    80004de8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dec:	4685                	li	a3,1
    80004dee:	fbf40613          	addi	a2,s0,-65
    80004df2:	85ca                	mv	a1,s2
    80004df4:	050a3503          	ld	a0,80(s4)
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	8b2080e7          	jalr	-1870(ra) # 800016aa <copyout>
    80004e00:	01650663          	beq	a0,s6,80004e0c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e04:	2985                	addiw	s3,s3,1
    80004e06:	0905                	addi	s2,s2,1
    80004e08:	fd3a91e3          	bne	s5,s3,80004dca <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e0c:	21c48513          	addi	a0,s1,540
    80004e10:	ffffe097          	auipc	ra,0xffffe
    80004e14:	834080e7          	jalr	-1996(ra) # 80002644 <wakeup>
  release(&pi->lock);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	e96080e7          	jalr	-362(ra) # 80000cb0 <release>
  return i;
}
    80004e22:	854e                	mv	a0,s3
    80004e24:	60a6                	ld	ra,72(sp)
    80004e26:	6406                	ld	s0,64(sp)
    80004e28:	74e2                	ld	s1,56(sp)
    80004e2a:	7942                	ld	s2,48(sp)
    80004e2c:	79a2                	ld	s3,40(sp)
    80004e2e:	7a02                	ld	s4,32(sp)
    80004e30:	6ae2                	ld	s5,24(sp)
    80004e32:	6b42                	ld	s6,16(sp)
    80004e34:	6161                	addi	sp,sp,80
    80004e36:	8082                	ret
      release(&pi->lock);
    80004e38:	8526                	mv	a0,s1
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	e76080e7          	jalr	-394(ra) # 80000cb0 <release>
      return -1;
    80004e42:	59fd                	li	s3,-1
    80004e44:	bff9                	j	80004e22 <piperead+0xc2>

0000000080004e46 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e46:	de010113          	addi	sp,sp,-544
    80004e4a:	20113c23          	sd	ra,536(sp)
    80004e4e:	20813823          	sd	s0,528(sp)
    80004e52:	20913423          	sd	s1,520(sp)
    80004e56:	21213023          	sd	s2,512(sp)
    80004e5a:	ffce                	sd	s3,504(sp)
    80004e5c:	fbd2                	sd	s4,496(sp)
    80004e5e:	f7d6                	sd	s5,488(sp)
    80004e60:	f3da                	sd	s6,480(sp)
    80004e62:	efde                	sd	s7,472(sp)
    80004e64:	ebe2                	sd	s8,464(sp)
    80004e66:	e7e6                	sd	s9,456(sp)
    80004e68:	e3ea                	sd	s10,448(sp)
    80004e6a:	ff6e                	sd	s11,440(sp)
    80004e6c:	1400                	addi	s0,sp,544
    80004e6e:	892a                	mv	s2,a0
    80004e70:	dea43423          	sd	a0,-536(s0)
    80004e74:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	c76080e7          	jalr	-906(ra) # 80001aee <myproc>
    80004e80:	84aa                	mv	s1,a0

  begin_op();
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	46c080e7          	jalr	1132(ra) # 800042ee <begin_op>

  if((ip = namei(path)) == 0){
    80004e8a:	854a                	mv	a0,s2
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	252080e7          	jalr	594(ra) # 800040de <namei>
    80004e94:	c93d                	beqz	a0,80004f0a <exec+0xc4>
    80004e96:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	a96080e7          	jalr	-1386(ra) # 8000392e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea0:	04000713          	li	a4,64
    80004ea4:	4681                	li	a3,0
    80004ea6:	e4840613          	addi	a2,s0,-440
    80004eaa:	4581                	li	a1,0
    80004eac:	8556                	mv	a0,s5
    80004eae:	fffff097          	auipc	ra,0xfffff
    80004eb2:	d34080e7          	jalr	-716(ra) # 80003be2 <readi>
    80004eb6:	04000793          	li	a5,64
    80004eba:	00f51a63          	bne	a0,a5,80004ece <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ebe:	e4842703          	lw	a4,-440(s0)
    80004ec2:	464c47b7          	lui	a5,0x464c4
    80004ec6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eca:	04f70663          	beq	a4,a5,80004f16 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ece:	8556                	mv	a0,s5
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	cc0080e7          	jalr	-832(ra) # 80003b90 <iunlockput>
    end_op();
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	496080e7          	jalr	1174(ra) # 8000436e <end_op>
  }
  return -1;
    80004ee0:	557d                	li	a0,-1
}
    80004ee2:	21813083          	ld	ra,536(sp)
    80004ee6:	21013403          	ld	s0,528(sp)
    80004eea:	20813483          	ld	s1,520(sp)
    80004eee:	20013903          	ld	s2,512(sp)
    80004ef2:	79fe                	ld	s3,504(sp)
    80004ef4:	7a5e                	ld	s4,496(sp)
    80004ef6:	7abe                	ld	s5,488(sp)
    80004ef8:	7b1e                	ld	s6,480(sp)
    80004efa:	6bfe                	ld	s7,472(sp)
    80004efc:	6c5e                	ld	s8,464(sp)
    80004efe:	6cbe                	ld	s9,456(sp)
    80004f00:	6d1e                	ld	s10,448(sp)
    80004f02:	7dfa                	ld	s11,440(sp)
    80004f04:	22010113          	addi	sp,sp,544
    80004f08:	8082                	ret
    end_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	464080e7          	jalr	1124(ra) # 8000436e <end_op>
    return -1;
    80004f12:	557d                	li	a0,-1
    80004f14:	b7f9                	j	80004ee2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f16:	8526                	mv	a0,s1
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	c9c080e7          	jalr	-868(ra) # 80001bb4 <proc_pagetable>
    80004f20:	8b2a                	mv	s6,a0
    80004f22:	d555                	beqz	a0,80004ece <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f24:	e6842783          	lw	a5,-408(s0)
    80004f28:	e8045703          	lhu	a4,-384(s0)
    80004f2c:	c735                	beqz	a4,80004f98 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f2e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f30:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f34:	6a05                	lui	s4,0x1
    80004f36:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f3a:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f3e:	6d85                	lui	s11,0x1
    80004f40:	7d7d                	lui	s10,0xfffff
    80004f42:	ac1d                	j	80005178 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f44:	00003517          	auipc	a0,0x3
    80004f48:	7e450513          	addi	a0,a0,2020 # 80008728 <syscalls+0x290>
    80004f4c:	ffffb097          	auipc	ra,0xffffb
    80004f50:	5f4080e7          	jalr	1524(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f54:	874a                	mv	a4,s2
    80004f56:	009c86bb          	addw	a3,s9,s1
    80004f5a:	4581                	li	a1,0
    80004f5c:	8556                	mv	a0,s5
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	c84080e7          	jalr	-892(ra) # 80003be2 <readi>
    80004f66:	2501                	sext.w	a0,a0
    80004f68:	1aa91863          	bne	s2,a0,80005118 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f6c:	009d84bb          	addw	s1,s11,s1
    80004f70:	013d09bb          	addw	s3,s10,s3
    80004f74:	1f74f263          	bgeu	s1,s7,80005158 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004f78:	02049593          	slli	a1,s1,0x20
    80004f7c:	9181                	srli	a1,a1,0x20
    80004f7e:	95e2                	add	a1,a1,s8
    80004f80:	855a                	mv	a0,s6
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	0f4080e7          	jalr	244(ra) # 80001076 <walkaddr>
    80004f8a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f8c:	dd45                	beqz	a0,80004f44 <exec+0xfe>
      n = PGSIZE;
    80004f8e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f90:	fd49f2e3          	bgeu	s3,s4,80004f54 <exec+0x10e>
      n = sz - i;
    80004f94:	894e                	mv	s2,s3
    80004f96:	bf7d                	j	80004f54 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f98:	4481                	li	s1,0
  iunlockput(ip);
    80004f9a:	8556                	mv	a0,s5
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	bf4080e7          	jalr	-1036(ra) # 80003b90 <iunlockput>
  end_op();
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	3ca080e7          	jalr	970(ra) # 8000436e <end_op>
  p = myproc();
    80004fac:	ffffd097          	auipc	ra,0xffffd
    80004fb0:	b42080e7          	jalr	-1214(ra) # 80001aee <myproc>
    80004fb4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fb6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fba:	6785                	lui	a5,0x1
    80004fbc:	17fd                	addi	a5,a5,-1
    80004fbe:	94be                	add	s1,s1,a5
    80004fc0:	77fd                	lui	a5,0xfffff
    80004fc2:	8fe5                	and	a5,a5,s1
    80004fc4:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fc8:	6609                	lui	a2,0x2
    80004fca:	963e                	add	a2,a2,a5
    80004fcc:	85be                	mv	a1,a5
    80004fce:	855a                	mv	a0,s6
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	48a080e7          	jalr	1162(ra) # 8000145a <uvmalloc>
    80004fd8:	8c2a                	mv	s8,a0
  ip = 0;
    80004fda:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fdc:	12050e63          	beqz	a0,80005118 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe0:	75f9                	lui	a1,0xffffe
    80004fe2:	95aa                	add	a1,a1,a0
    80004fe4:	855a                	mv	a0,s6
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	692080e7          	jalr	1682(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fee:	7afd                	lui	s5,0xfffff
    80004ff0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ff2:	df043783          	ld	a5,-528(s0)
    80004ff6:	6388                	ld	a0,0(a5)
    80004ff8:	c925                	beqz	a0,80005068 <exec+0x222>
    80004ffa:	e8840993          	addi	s3,s0,-376
    80004ffe:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005002:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005004:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	e76080e7          	jalr	-394(ra) # 80000e7c <strlen>
    8000500e:	0015079b          	addiw	a5,a0,1
    80005012:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005016:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000501a:	13596363          	bltu	s2,s5,80005140 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000501e:	df043d83          	ld	s11,-528(s0)
    80005022:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005026:	8552                	mv	a0,s4
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	e54080e7          	jalr	-428(ra) # 80000e7c <strlen>
    80005030:	0015069b          	addiw	a3,a0,1
    80005034:	8652                	mv	a2,s4
    80005036:	85ca                	mv	a1,s2
    80005038:	855a                	mv	a0,s6
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	670080e7          	jalr	1648(ra) # 800016aa <copyout>
    80005042:	10054363          	bltz	a0,80005148 <exec+0x302>
    ustack[argc] = sp;
    80005046:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	0485                	addi	s1,s1,1
    8000504c:	008d8793          	addi	a5,s11,8
    80005050:	def43823          	sd	a5,-528(s0)
    80005054:	008db503          	ld	a0,8(s11)
    80005058:	c911                	beqz	a0,8000506c <exec+0x226>
    if(argc >= MAXARG)
    8000505a:	09a1                	addi	s3,s3,8
    8000505c:	fb3c95e3          	bne	s9,s3,80005006 <exec+0x1c0>
  sz = sz1;
    80005060:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005064:	4a81                	li	s5,0
    80005066:	a84d                	j	80005118 <exec+0x2d2>
  sp = sz;
    80005068:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000506a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000506c:	00349793          	slli	a5,s1,0x3
    80005070:	f9040713          	addi	a4,s0,-112
    80005074:	97ba                	add	a5,a5,a4
    80005076:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000507a:	00148693          	addi	a3,s1,1
    8000507e:	068e                	slli	a3,a3,0x3
    80005080:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005084:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005088:	01597663          	bgeu	s2,s5,80005094 <exec+0x24e>
  sz = sz1;
    8000508c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005090:	4a81                	li	s5,0
    80005092:	a059                	j	80005118 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005094:	e8840613          	addi	a2,s0,-376
    80005098:	85ca                	mv	a1,s2
    8000509a:	855a                	mv	a0,s6
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	60e080e7          	jalr	1550(ra) # 800016aa <copyout>
    800050a4:	0a054663          	bltz	a0,80005150 <exec+0x30a>
  p->trapframe->a1 = sp;
    800050a8:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800050ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b0:	de843783          	ld	a5,-536(s0)
    800050b4:	0007c703          	lbu	a4,0(a5)
    800050b8:	cf11                	beqz	a4,800050d4 <exec+0x28e>
    800050ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050bc:	02f00693          	li	a3,47
    800050c0:	a039                	j	800050ce <exec+0x288>
      last = s+1;
    800050c2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050c6:	0785                	addi	a5,a5,1
    800050c8:	fff7c703          	lbu	a4,-1(a5)
    800050cc:	c701                	beqz	a4,800050d4 <exec+0x28e>
    if(*s == '/')
    800050ce:	fed71ce3          	bne	a4,a3,800050c6 <exec+0x280>
    800050d2:	bfc5                	j	800050c2 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d4:	4641                	li	a2,16
    800050d6:	de843583          	ld	a1,-536(s0)
    800050da:	158b8513          	addi	a0,s7,344
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	d6c080e7          	jalr	-660(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    800050e6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800050ea:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800050ee:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f2:	058bb783          	ld	a5,88(s7)
    800050f6:	e6043703          	ld	a4,-416(s0)
    800050fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050fc:	058bb783          	ld	a5,88(s7)
    80005100:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005104:	85ea                	mv	a1,s10
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	b4a080e7          	jalr	-1206(ra) # 80001c50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000510e:	0004851b          	sext.w	a0,s1
    80005112:	bbc1                	j	80004ee2 <exec+0x9c>
    80005114:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005118:	df843583          	ld	a1,-520(s0)
    8000511c:	855a                	mv	a0,s6
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	b32080e7          	jalr	-1230(ra) # 80001c50 <proc_freepagetable>
  if(ip){
    80005126:	da0a94e3          	bnez	s5,80004ece <exec+0x88>
  return -1;
    8000512a:	557d                	li	a0,-1
    8000512c:	bb5d                	j	80004ee2 <exec+0x9c>
    8000512e:	de943c23          	sd	s1,-520(s0)
    80005132:	b7dd                	j	80005118 <exec+0x2d2>
    80005134:	de943c23          	sd	s1,-520(s0)
    80005138:	b7c5                	j	80005118 <exec+0x2d2>
    8000513a:	de943c23          	sd	s1,-520(s0)
    8000513e:	bfe9                	j	80005118 <exec+0x2d2>
  sz = sz1;
    80005140:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005144:	4a81                	li	s5,0
    80005146:	bfc9                	j	80005118 <exec+0x2d2>
  sz = sz1;
    80005148:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000514c:	4a81                	li	s5,0
    8000514e:	b7e9                	j	80005118 <exec+0x2d2>
  sz = sz1;
    80005150:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005154:	4a81                	li	s5,0
    80005156:	b7c9                	j	80005118 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005158:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000515c:	e0843783          	ld	a5,-504(s0)
    80005160:	0017869b          	addiw	a3,a5,1
    80005164:	e0d43423          	sd	a3,-504(s0)
    80005168:	e0043783          	ld	a5,-512(s0)
    8000516c:	0387879b          	addiw	a5,a5,56
    80005170:	e8045703          	lhu	a4,-384(s0)
    80005174:	e2e6d3e3          	bge	a3,a4,80004f9a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005178:	2781                	sext.w	a5,a5
    8000517a:	e0f43023          	sd	a5,-512(s0)
    8000517e:	03800713          	li	a4,56
    80005182:	86be                	mv	a3,a5
    80005184:	e1040613          	addi	a2,s0,-496
    80005188:	4581                	li	a1,0
    8000518a:	8556                	mv	a0,s5
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	a56080e7          	jalr	-1450(ra) # 80003be2 <readi>
    80005194:	03800793          	li	a5,56
    80005198:	f6f51ee3          	bne	a0,a5,80005114 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000519c:	e1042783          	lw	a5,-496(s0)
    800051a0:	4705                	li	a4,1
    800051a2:	fae79de3          	bne	a5,a4,8000515c <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051a6:	e3843603          	ld	a2,-456(s0)
    800051aa:	e3043783          	ld	a5,-464(s0)
    800051ae:	f8f660e3          	bltu	a2,a5,8000512e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b2:	e2043783          	ld	a5,-480(s0)
    800051b6:	963e                	add	a2,a2,a5
    800051b8:	f6f66ee3          	bltu	a2,a5,80005134 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051bc:	85a6                	mv	a1,s1
    800051be:	855a                	mv	a0,s6
    800051c0:	ffffc097          	auipc	ra,0xffffc
    800051c4:	29a080e7          	jalr	666(ra) # 8000145a <uvmalloc>
    800051c8:	dea43c23          	sd	a0,-520(s0)
    800051cc:	d53d                	beqz	a0,8000513a <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800051ce:	e2043c03          	ld	s8,-480(s0)
    800051d2:	de043783          	ld	a5,-544(s0)
    800051d6:	00fc77b3          	and	a5,s8,a5
    800051da:	ff9d                	bnez	a5,80005118 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051dc:	e1842c83          	lw	s9,-488(s0)
    800051e0:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051e4:	f60b8ae3          	beqz	s7,80005158 <exec+0x312>
    800051e8:	89de                	mv	s3,s7
    800051ea:	4481                	li	s1,0
    800051ec:	b371                	j	80004f78 <exec+0x132>

00000000800051ee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051ee:	7179                	addi	sp,sp,-48
    800051f0:	f406                	sd	ra,40(sp)
    800051f2:	f022                	sd	s0,32(sp)
    800051f4:	ec26                	sd	s1,24(sp)
    800051f6:	e84a                	sd	s2,16(sp)
    800051f8:	1800                	addi	s0,sp,48
    800051fa:	892e                	mv	s2,a1
    800051fc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051fe:	fdc40593          	addi	a1,s0,-36
    80005202:	ffffe097          	auipc	ra,0xffffe
    80005206:	b92080e7          	jalr	-1134(ra) # 80002d94 <argint>
    8000520a:	04054063          	bltz	a0,8000524a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000520e:	fdc42703          	lw	a4,-36(s0)
    80005212:	47bd                	li	a5,15
    80005214:	02e7ed63          	bltu	a5,a4,8000524e <argfd+0x60>
    80005218:	ffffd097          	auipc	ra,0xffffd
    8000521c:	8d6080e7          	jalr	-1834(ra) # 80001aee <myproc>
    80005220:	fdc42703          	lw	a4,-36(s0)
    80005224:	01a70793          	addi	a5,a4,26
    80005228:	078e                	slli	a5,a5,0x3
    8000522a:	953e                	add	a0,a0,a5
    8000522c:	611c                	ld	a5,0(a0)
    8000522e:	c395                	beqz	a5,80005252 <argfd+0x64>
    return -1;
  if(pfd)
    80005230:	00090463          	beqz	s2,80005238 <argfd+0x4a>
    *pfd = fd;
    80005234:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005238:	4501                	li	a0,0
  if(pf)
    8000523a:	c091                	beqz	s1,8000523e <argfd+0x50>
    *pf = f;
    8000523c:	e09c                	sd	a5,0(s1)
}
    8000523e:	70a2                	ld	ra,40(sp)
    80005240:	7402                	ld	s0,32(sp)
    80005242:	64e2                	ld	s1,24(sp)
    80005244:	6942                	ld	s2,16(sp)
    80005246:	6145                	addi	sp,sp,48
    80005248:	8082                	ret
    return -1;
    8000524a:	557d                	li	a0,-1
    8000524c:	bfcd                	j	8000523e <argfd+0x50>
    return -1;
    8000524e:	557d                	li	a0,-1
    80005250:	b7fd                	j	8000523e <argfd+0x50>
    80005252:	557d                	li	a0,-1
    80005254:	b7ed                	j	8000523e <argfd+0x50>

0000000080005256 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005256:	1101                	addi	sp,sp,-32
    80005258:	ec06                	sd	ra,24(sp)
    8000525a:	e822                	sd	s0,16(sp)
    8000525c:	e426                	sd	s1,8(sp)
    8000525e:	1000                	addi	s0,sp,32
    80005260:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005262:	ffffd097          	auipc	ra,0xffffd
    80005266:	88c080e7          	jalr	-1908(ra) # 80001aee <myproc>
    8000526a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000526c:	0d050793          	addi	a5,a0,208
    80005270:	4501                	li	a0,0
    80005272:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005274:	6398                	ld	a4,0(a5)
    80005276:	cb19                	beqz	a4,8000528c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005278:	2505                	addiw	a0,a0,1
    8000527a:	07a1                	addi	a5,a5,8
    8000527c:	fed51ce3          	bne	a0,a3,80005274 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005280:	557d                	li	a0,-1
}
    80005282:	60e2                	ld	ra,24(sp)
    80005284:	6442                	ld	s0,16(sp)
    80005286:	64a2                	ld	s1,8(sp)
    80005288:	6105                	addi	sp,sp,32
    8000528a:	8082                	ret
      p->ofile[fd] = f;
    8000528c:	01a50793          	addi	a5,a0,26
    80005290:	078e                	slli	a5,a5,0x3
    80005292:	963e                	add	a2,a2,a5
    80005294:	e204                	sd	s1,0(a2)
      return fd;
    80005296:	b7f5                	j	80005282 <fdalloc+0x2c>

0000000080005298 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005298:	715d                	addi	sp,sp,-80
    8000529a:	e486                	sd	ra,72(sp)
    8000529c:	e0a2                	sd	s0,64(sp)
    8000529e:	fc26                	sd	s1,56(sp)
    800052a0:	f84a                	sd	s2,48(sp)
    800052a2:	f44e                	sd	s3,40(sp)
    800052a4:	f052                	sd	s4,32(sp)
    800052a6:	ec56                	sd	s5,24(sp)
    800052a8:	0880                	addi	s0,sp,80
    800052aa:	89ae                	mv	s3,a1
    800052ac:	8ab2                	mv	s5,a2
    800052ae:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b0:	fb040593          	addi	a1,s0,-80
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	e48080e7          	jalr	-440(ra) # 800040fc <nameiparent>
    800052bc:	892a                	mv	s2,a0
    800052be:	12050e63          	beqz	a0,800053fa <create+0x162>
    return 0;

  ilock(dp);
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	66c080e7          	jalr	1644(ra) # 8000392e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052ca:	4601                	li	a2,0
    800052cc:	fb040593          	addi	a1,s0,-80
    800052d0:	854a                	mv	a0,s2
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	b3a080e7          	jalr	-1222(ra) # 80003e0c <dirlookup>
    800052da:	84aa                	mv	s1,a0
    800052dc:	c921                	beqz	a0,8000532c <create+0x94>
    iunlockput(dp);
    800052de:	854a                	mv	a0,s2
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	8b0080e7          	jalr	-1872(ra) # 80003b90 <iunlockput>
    ilock(ip);
    800052e8:	8526                	mv	a0,s1
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	644080e7          	jalr	1604(ra) # 8000392e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f2:	2981                	sext.w	s3,s3
    800052f4:	4789                	li	a5,2
    800052f6:	02f99463          	bne	s3,a5,8000531e <create+0x86>
    800052fa:	0444d783          	lhu	a5,68(s1)
    800052fe:	37f9                	addiw	a5,a5,-2
    80005300:	17c2                	slli	a5,a5,0x30
    80005302:	93c1                	srli	a5,a5,0x30
    80005304:	4705                	li	a4,1
    80005306:	00f76c63          	bltu	a4,a5,8000531e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000530a:	8526                	mv	a0,s1
    8000530c:	60a6                	ld	ra,72(sp)
    8000530e:	6406                	ld	s0,64(sp)
    80005310:	74e2                	ld	s1,56(sp)
    80005312:	7942                	ld	s2,48(sp)
    80005314:	79a2                	ld	s3,40(sp)
    80005316:	7a02                	ld	s4,32(sp)
    80005318:	6ae2                	ld	s5,24(sp)
    8000531a:	6161                	addi	sp,sp,80
    8000531c:	8082                	ret
    iunlockput(ip);
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	870080e7          	jalr	-1936(ra) # 80003b90 <iunlockput>
    return 0;
    80005328:	4481                	li	s1,0
    8000532a:	b7c5                	j	8000530a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000532c:	85ce                	mv	a1,s3
    8000532e:	00092503          	lw	a0,0(s2)
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	464080e7          	jalr	1124(ra) # 80003796 <ialloc>
    8000533a:	84aa                	mv	s1,a0
    8000533c:	c521                	beqz	a0,80005384 <create+0xec>
  ilock(ip);
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	5f0080e7          	jalr	1520(ra) # 8000392e <ilock>
  ip->major = major;
    80005346:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000534a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000534e:	4a05                	li	s4,1
    80005350:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005354:	8526                	mv	a0,s1
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	50e080e7          	jalr	1294(ra) # 80003864 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000535e:	2981                	sext.w	s3,s3
    80005360:	03498a63          	beq	s3,s4,80005394 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005364:	40d0                	lw	a2,4(s1)
    80005366:	fb040593          	addi	a1,s0,-80
    8000536a:	854a                	mv	a0,s2
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	cb0080e7          	jalr	-848(ra) # 8000401c <dirlink>
    80005374:	06054b63          	bltz	a0,800053ea <create+0x152>
  iunlockput(dp);
    80005378:	854a                	mv	a0,s2
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	816080e7          	jalr	-2026(ra) # 80003b90 <iunlockput>
  return ip;
    80005382:	b761                	j	8000530a <create+0x72>
    panic("create: ialloc");
    80005384:	00003517          	auipc	a0,0x3
    80005388:	3c450513          	addi	a0,a0,964 # 80008748 <syscalls+0x2b0>
    8000538c:	ffffb097          	auipc	ra,0xffffb
    80005390:	1b4080e7          	jalr	436(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    80005394:	04a95783          	lhu	a5,74(s2)
    80005398:	2785                	addiw	a5,a5,1
    8000539a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000539e:	854a                	mv	a0,s2
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	4c4080e7          	jalr	1220(ra) # 80003864 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053a8:	40d0                	lw	a2,4(s1)
    800053aa:	00003597          	auipc	a1,0x3
    800053ae:	3ae58593          	addi	a1,a1,942 # 80008758 <syscalls+0x2c0>
    800053b2:	8526                	mv	a0,s1
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	c68080e7          	jalr	-920(ra) # 8000401c <dirlink>
    800053bc:	00054f63          	bltz	a0,800053da <create+0x142>
    800053c0:	00492603          	lw	a2,4(s2)
    800053c4:	00003597          	auipc	a1,0x3
    800053c8:	39c58593          	addi	a1,a1,924 # 80008760 <syscalls+0x2c8>
    800053cc:	8526                	mv	a0,s1
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	c4e080e7          	jalr	-946(ra) # 8000401c <dirlink>
    800053d6:	f80557e3          	bgez	a0,80005364 <create+0xcc>
      panic("create dots");
    800053da:	00003517          	auipc	a0,0x3
    800053de:	38e50513          	addi	a0,a0,910 # 80008768 <syscalls+0x2d0>
    800053e2:	ffffb097          	auipc	ra,0xffffb
    800053e6:	15e080e7          	jalr	350(ra) # 80000540 <panic>
    panic("create: dirlink");
    800053ea:	00003517          	auipc	a0,0x3
    800053ee:	38e50513          	addi	a0,a0,910 # 80008778 <syscalls+0x2e0>
    800053f2:	ffffb097          	auipc	ra,0xffffb
    800053f6:	14e080e7          	jalr	334(ra) # 80000540 <panic>
    return 0;
    800053fa:	84aa                	mv	s1,a0
    800053fc:	b739                	j	8000530a <create+0x72>

00000000800053fe <sys_dup>:
{
    800053fe:	7179                	addi	sp,sp,-48
    80005400:	f406                	sd	ra,40(sp)
    80005402:	f022                	sd	s0,32(sp)
    80005404:	ec26                	sd	s1,24(sp)
    80005406:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005408:	fd840613          	addi	a2,s0,-40
    8000540c:	4581                	li	a1,0
    8000540e:	4501                	li	a0,0
    80005410:	00000097          	auipc	ra,0x0
    80005414:	dde080e7          	jalr	-546(ra) # 800051ee <argfd>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000541a:	02054363          	bltz	a0,80005440 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000541e:	fd843503          	ld	a0,-40(s0)
    80005422:	00000097          	auipc	ra,0x0
    80005426:	e34080e7          	jalr	-460(ra) # 80005256 <fdalloc>
    8000542a:	84aa                	mv	s1,a0
    return -1;
    8000542c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000542e:	00054963          	bltz	a0,80005440 <sys_dup+0x42>
  filedup(f);
    80005432:	fd843503          	ld	a0,-40(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	338080e7          	jalr	824(ra) # 8000476e <filedup>
  return fd;
    8000543e:	87a6                	mv	a5,s1
}
    80005440:	853e                	mv	a0,a5
    80005442:	70a2                	ld	ra,40(sp)
    80005444:	7402                	ld	s0,32(sp)
    80005446:	64e2                	ld	s1,24(sp)
    80005448:	6145                	addi	sp,sp,48
    8000544a:	8082                	ret

000000008000544c <sys_read>:
{
    8000544c:	7179                	addi	sp,sp,-48
    8000544e:	f406                	sd	ra,40(sp)
    80005450:	f022                	sd	s0,32(sp)
    80005452:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005454:	fe840613          	addi	a2,s0,-24
    80005458:	4581                	li	a1,0
    8000545a:	4501                	li	a0,0
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	d92080e7          	jalr	-622(ra) # 800051ee <argfd>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005466:	04054163          	bltz	a0,800054a8 <sys_read+0x5c>
    8000546a:	fe440593          	addi	a1,s0,-28
    8000546e:	4509                	li	a0,2
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	924080e7          	jalr	-1756(ra) # 80002d94 <argint>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547a:	02054763          	bltz	a0,800054a8 <sys_read+0x5c>
    8000547e:	fd840593          	addi	a1,s0,-40
    80005482:	4505                	li	a0,1
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	932080e7          	jalr	-1742(ra) # 80002db6 <argaddr>
    return -1;
    8000548c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000548e:	00054d63          	bltz	a0,800054a8 <sys_read+0x5c>
  return fileread(f, p, n);
    80005492:	fe442603          	lw	a2,-28(s0)
    80005496:	fd843583          	ld	a1,-40(s0)
    8000549a:	fe843503          	ld	a0,-24(s0)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	45c080e7          	jalr	1116(ra) # 800048fa <fileread>
    800054a6:	87aa                	mv	a5,a0
}
    800054a8:	853e                	mv	a0,a5
    800054aa:	70a2                	ld	ra,40(sp)
    800054ac:	7402                	ld	s0,32(sp)
    800054ae:	6145                	addi	sp,sp,48
    800054b0:	8082                	ret

00000000800054b2 <sys_write>:
{
    800054b2:	7179                	addi	sp,sp,-48
    800054b4:	f406                	sd	ra,40(sp)
    800054b6:	f022                	sd	s0,32(sp)
    800054b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ba:	fe840613          	addi	a2,s0,-24
    800054be:	4581                	li	a1,0
    800054c0:	4501                	li	a0,0
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	d2c080e7          	jalr	-724(ra) # 800051ee <argfd>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054cc:	04054163          	bltz	a0,8000550e <sys_write+0x5c>
    800054d0:	fe440593          	addi	a1,s0,-28
    800054d4:	4509                	li	a0,2
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	8be080e7          	jalr	-1858(ra) # 80002d94 <argint>
    return -1;
    800054de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e0:	02054763          	bltz	a0,8000550e <sys_write+0x5c>
    800054e4:	fd840593          	addi	a1,s0,-40
    800054e8:	4505                	li	a0,1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	8cc080e7          	jalr	-1844(ra) # 80002db6 <argaddr>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f4:	00054d63          	bltz	a0,8000550e <sys_write+0x5c>
  return filewrite(f, p, n);
    800054f8:	fe442603          	lw	a2,-28(s0)
    800054fc:	fd843583          	ld	a1,-40(s0)
    80005500:	fe843503          	ld	a0,-24(s0)
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	4b8080e7          	jalr	1208(ra) # 800049bc <filewrite>
    8000550c:	87aa                	mv	a5,a0
}
    8000550e:	853e                	mv	a0,a5
    80005510:	70a2                	ld	ra,40(sp)
    80005512:	7402                	ld	s0,32(sp)
    80005514:	6145                	addi	sp,sp,48
    80005516:	8082                	ret

0000000080005518 <sys_close>:
{
    80005518:	1101                	addi	sp,sp,-32
    8000551a:	ec06                	sd	ra,24(sp)
    8000551c:	e822                	sd	s0,16(sp)
    8000551e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005520:	fe040613          	addi	a2,s0,-32
    80005524:	fec40593          	addi	a1,s0,-20
    80005528:	4501                	li	a0,0
    8000552a:	00000097          	auipc	ra,0x0
    8000552e:	cc4080e7          	jalr	-828(ra) # 800051ee <argfd>
    return -1;
    80005532:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005534:	02054463          	bltz	a0,8000555c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005538:	ffffc097          	auipc	ra,0xffffc
    8000553c:	5b6080e7          	jalr	1462(ra) # 80001aee <myproc>
    80005540:	fec42783          	lw	a5,-20(s0)
    80005544:	07e9                	addi	a5,a5,26
    80005546:	078e                	slli	a5,a5,0x3
    80005548:	97aa                	add	a5,a5,a0
    8000554a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000554e:	fe043503          	ld	a0,-32(s0)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	26e080e7          	jalr	622(ra) # 800047c0 <fileclose>
  return 0;
    8000555a:	4781                	li	a5,0
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	60e2                	ld	ra,24(sp)
    80005560:	6442                	ld	s0,16(sp)
    80005562:	6105                	addi	sp,sp,32
    80005564:	8082                	ret

0000000080005566 <sys_fstat>:
{
    80005566:	1101                	addi	sp,sp,-32
    80005568:	ec06                	sd	ra,24(sp)
    8000556a:	e822                	sd	s0,16(sp)
    8000556c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000556e:	fe840613          	addi	a2,s0,-24
    80005572:	4581                	li	a1,0
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	c78080e7          	jalr	-904(ra) # 800051ee <argfd>
    return -1;
    8000557e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005580:	02054563          	bltz	a0,800055aa <sys_fstat+0x44>
    80005584:	fe040593          	addi	a1,s0,-32
    80005588:	4505                	li	a0,1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	82c080e7          	jalr	-2004(ra) # 80002db6 <argaddr>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005594:	00054b63          	bltz	a0,800055aa <sys_fstat+0x44>
  return filestat(f, st);
    80005598:	fe043583          	ld	a1,-32(s0)
    8000559c:	fe843503          	ld	a0,-24(s0)
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	2e8080e7          	jalr	744(ra) # 80004888 <filestat>
    800055a8:	87aa                	mv	a5,a0
}
    800055aa:	853e                	mv	a0,a5
    800055ac:	60e2                	ld	ra,24(sp)
    800055ae:	6442                	ld	s0,16(sp)
    800055b0:	6105                	addi	sp,sp,32
    800055b2:	8082                	ret

00000000800055b4 <sys_link>:
{
    800055b4:	7169                	addi	sp,sp,-304
    800055b6:	f606                	sd	ra,296(sp)
    800055b8:	f222                	sd	s0,288(sp)
    800055ba:	ee26                	sd	s1,280(sp)
    800055bc:	ea4a                	sd	s2,272(sp)
    800055be:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c0:	08000613          	li	a2,128
    800055c4:	ed040593          	addi	a1,s0,-304
    800055c8:	4501                	li	a0,0
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	80e080e7          	jalr	-2034(ra) # 80002dd8 <argstr>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d4:	10054e63          	bltz	a0,800056f0 <sys_link+0x13c>
    800055d8:	08000613          	li	a2,128
    800055dc:	f5040593          	addi	a1,s0,-176
    800055e0:	4505                	li	a0,1
    800055e2:	ffffd097          	auipc	ra,0xffffd
    800055e6:	7f6080e7          	jalr	2038(ra) # 80002dd8 <argstr>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ec:	10054263          	bltz	a0,800056f0 <sys_link+0x13c>
  begin_op();
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	cfe080e7          	jalr	-770(ra) # 800042ee <begin_op>
  if((ip = namei(old)) == 0){
    800055f8:	ed040513          	addi	a0,s0,-304
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	ae2080e7          	jalr	-1310(ra) # 800040de <namei>
    80005604:	84aa                	mv	s1,a0
    80005606:	c551                	beqz	a0,80005692 <sys_link+0xde>
  ilock(ip);
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	326080e7          	jalr	806(ra) # 8000392e <ilock>
  if(ip->type == T_DIR){
    80005610:	04449703          	lh	a4,68(s1)
    80005614:	4785                	li	a5,1
    80005616:	08f70463          	beq	a4,a5,8000569e <sys_link+0xea>
  ip->nlink++;
    8000561a:	04a4d783          	lhu	a5,74(s1)
    8000561e:	2785                	addiw	a5,a5,1
    80005620:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	23e080e7          	jalr	574(ra) # 80003864 <iupdate>
  iunlock(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	3c0080e7          	jalr	960(ra) # 800039f0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005638:	fd040593          	addi	a1,s0,-48
    8000563c:	f5040513          	addi	a0,s0,-176
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	abc080e7          	jalr	-1348(ra) # 800040fc <nameiparent>
    80005648:	892a                	mv	s2,a0
    8000564a:	c935                	beqz	a0,800056be <sys_link+0x10a>
  ilock(dp);
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	2e2080e7          	jalr	738(ra) # 8000392e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005654:	00092703          	lw	a4,0(s2)
    80005658:	409c                	lw	a5,0(s1)
    8000565a:	04f71d63          	bne	a4,a5,800056b4 <sys_link+0x100>
    8000565e:	40d0                	lw	a2,4(s1)
    80005660:	fd040593          	addi	a1,s0,-48
    80005664:	854a                	mv	a0,s2
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	9b6080e7          	jalr	-1610(ra) # 8000401c <dirlink>
    8000566e:	04054363          	bltz	a0,800056b4 <sys_link+0x100>
  iunlockput(dp);
    80005672:	854a                	mv	a0,s2
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	51c080e7          	jalr	1308(ra) # 80003b90 <iunlockput>
  iput(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	46a080e7          	jalr	1130(ra) # 80003ae8 <iput>
  end_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	ce8080e7          	jalr	-792(ra) # 8000436e <end_op>
  return 0;
    8000568e:	4781                	li	a5,0
    80005690:	a085                	j	800056f0 <sys_link+0x13c>
    end_op();
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	cdc080e7          	jalr	-804(ra) # 8000436e <end_op>
    return -1;
    8000569a:	57fd                	li	a5,-1
    8000569c:	a891                	j	800056f0 <sys_link+0x13c>
    iunlockput(ip);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	4f0080e7          	jalr	1264(ra) # 80003b90 <iunlockput>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	cc6080e7          	jalr	-826(ra) # 8000436e <end_op>
    return -1;
    800056b0:	57fd                	li	a5,-1
    800056b2:	a83d                	j	800056f0 <sys_link+0x13c>
    iunlockput(dp);
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	4da080e7          	jalr	1242(ra) # 80003b90 <iunlockput>
  ilock(ip);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	26e080e7          	jalr	622(ra) # 8000392e <ilock>
  ip->nlink--;
    800056c8:	04a4d783          	lhu	a5,74(s1)
    800056cc:	37fd                	addiw	a5,a5,-1
    800056ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	190080e7          	jalr	400(ra) # 80003864 <iupdate>
  iunlockput(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	4b2080e7          	jalr	1202(ra) # 80003b90 <iunlockput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	c88080e7          	jalr	-888(ra) # 8000436e <end_op>
  return -1;
    800056ee:	57fd                	li	a5,-1
}
    800056f0:	853e                	mv	a0,a5
    800056f2:	70b2                	ld	ra,296(sp)
    800056f4:	7412                	ld	s0,288(sp)
    800056f6:	64f2                	ld	s1,280(sp)
    800056f8:	6952                	ld	s2,272(sp)
    800056fa:	6155                	addi	sp,sp,304
    800056fc:	8082                	ret

00000000800056fe <sys_unlink>:
{
    800056fe:	7151                	addi	sp,sp,-240
    80005700:	f586                	sd	ra,232(sp)
    80005702:	f1a2                	sd	s0,224(sp)
    80005704:	eda6                	sd	s1,216(sp)
    80005706:	e9ca                	sd	s2,208(sp)
    80005708:	e5ce                	sd	s3,200(sp)
    8000570a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000570c:	08000613          	li	a2,128
    80005710:	f3040593          	addi	a1,s0,-208
    80005714:	4501                	li	a0,0
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	6c2080e7          	jalr	1730(ra) # 80002dd8 <argstr>
    8000571e:	18054163          	bltz	a0,800058a0 <sys_unlink+0x1a2>
  begin_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	bcc080e7          	jalr	-1076(ra) # 800042ee <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000572a:	fb040593          	addi	a1,s0,-80
    8000572e:	f3040513          	addi	a0,s0,-208
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	9ca080e7          	jalr	-1590(ra) # 800040fc <nameiparent>
    8000573a:	84aa                	mv	s1,a0
    8000573c:	c979                	beqz	a0,80005812 <sys_unlink+0x114>
  ilock(dp);
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	1f0080e7          	jalr	496(ra) # 8000392e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005746:	00003597          	auipc	a1,0x3
    8000574a:	01258593          	addi	a1,a1,18 # 80008758 <syscalls+0x2c0>
    8000574e:	fb040513          	addi	a0,s0,-80
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	6a0080e7          	jalr	1696(ra) # 80003df2 <namecmp>
    8000575a:	14050a63          	beqz	a0,800058ae <sys_unlink+0x1b0>
    8000575e:	00003597          	auipc	a1,0x3
    80005762:	00258593          	addi	a1,a1,2 # 80008760 <syscalls+0x2c8>
    80005766:	fb040513          	addi	a0,s0,-80
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	688080e7          	jalr	1672(ra) # 80003df2 <namecmp>
    80005772:	12050e63          	beqz	a0,800058ae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005776:	f2c40613          	addi	a2,s0,-212
    8000577a:	fb040593          	addi	a1,s0,-80
    8000577e:	8526                	mv	a0,s1
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	68c080e7          	jalr	1676(ra) # 80003e0c <dirlookup>
    80005788:	892a                	mv	s2,a0
    8000578a:	12050263          	beqz	a0,800058ae <sys_unlink+0x1b0>
  ilock(ip);
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	1a0080e7          	jalr	416(ra) # 8000392e <ilock>
  if(ip->nlink < 1)
    80005796:	04a91783          	lh	a5,74(s2)
    8000579a:	08f05263          	blez	a5,8000581e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000579e:	04491703          	lh	a4,68(s2)
    800057a2:	4785                	li	a5,1
    800057a4:	08f70563          	beq	a4,a5,8000582e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057a8:	4641                	li	a2,16
    800057aa:	4581                	li	a1,0
    800057ac:	fc040513          	addi	a0,s0,-64
    800057b0:	ffffb097          	auipc	ra,0xffffb
    800057b4:	548080e7          	jalr	1352(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b8:	4741                	li	a4,16
    800057ba:	f2c42683          	lw	a3,-212(s0)
    800057be:	fc040613          	addi	a2,s0,-64
    800057c2:	4581                	li	a1,0
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	512080e7          	jalr	1298(ra) # 80003cd8 <writei>
    800057ce:	47c1                	li	a5,16
    800057d0:	0af51563          	bne	a0,a5,8000587a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057d4:	04491703          	lh	a4,68(s2)
    800057d8:	4785                	li	a5,1
    800057da:	0af70863          	beq	a4,a5,8000588a <sys_unlink+0x18c>
  iunlockput(dp);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	3b0080e7          	jalr	944(ra) # 80003b90 <iunlockput>
  ip->nlink--;
    800057e8:	04a95783          	lhu	a5,74(s2)
    800057ec:	37fd                	addiw	a5,a5,-1
    800057ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057f2:	854a                	mv	a0,s2
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	070080e7          	jalr	112(ra) # 80003864 <iupdate>
  iunlockput(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	392080e7          	jalr	914(ra) # 80003b90 <iunlockput>
  end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	b68080e7          	jalr	-1176(ra) # 8000436e <end_op>
  return 0;
    8000580e:	4501                	li	a0,0
    80005810:	a84d                	j	800058c2 <sys_unlink+0x1c4>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	b5c080e7          	jalr	-1188(ra) # 8000436e <end_op>
    return -1;
    8000581a:	557d                	li	a0,-1
    8000581c:	a05d                	j	800058c2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000581e:	00003517          	auipc	a0,0x3
    80005822:	f6a50513          	addi	a0,a0,-150 # 80008788 <syscalls+0x2f0>
    80005826:	ffffb097          	auipc	ra,0xffffb
    8000582a:	d1a080e7          	jalr	-742(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582e:	04c92703          	lw	a4,76(s2)
    80005832:	02000793          	li	a5,32
    80005836:	f6e7f9e3          	bgeu	a5,a4,800057a8 <sys_unlink+0xaa>
    8000583a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583e:	4741                	li	a4,16
    80005840:	86ce                	mv	a3,s3
    80005842:	f1840613          	addi	a2,s0,-232
    80005846:	4581                	li	a1,0
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	398080e7          	jalr	920(ra) # 80003be2 <readi>
    80005852:	47c1                	li	a5,16
    80005854:	00f51b63          	bne	a0,a5,8000586a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005858:	f1845783          	lhu	a5,-232(s0)
    8000585c:	e7a1                	bnez	a5,800058a4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585e:	29c1                	addiw	s3,s3,16
    80005860:	04c92783          	lw	a5,76(s2)
    80005864:	fcf9ede3          	bltu	s3,a5,8000583e <sys_unlink+0x140>
    80005868:	b781                	j	800057a8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000586a:	00003517          	auipc	a0,0x3
    8000586e:	f3650513          	addi	a0,a0,-202 # 800087a0 <syscalls+0x308>
    80005872:	ffffb097          	auipc	ra,0xffffb
    80005876:	cce080e7          	jalr	-818(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000587a:	00003517          	auipc	a0,0x3
    8000587e:	f3e50513          	addi	a0,a0,-194 # 800087b8 <syscalls+0x320>
    80005882:	ffffb097          	auipc	ra,0xffffb
    80005886:	cbe080e7          	jalr	-834(ra) # 80000540 <panic>
    dp->nlink--;
    8000588a:	04a4d783          	lhu	a5,74(s1)
    8000588e:	37fd                	addiw	a5,a5,-1
    80005890:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	fce080e7          	jalr	-50(ra) # 80003864 <iupdate>
    8000589e:	b781                	j	800057de <sys_unlink+0xe0>
    return -1;
    800058a0:	557d                	li	a0,-1
    800058a2:	a005                	j	800058c2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	2ea080e7          	jalr	746(ra) # 80003b90 <iunlockput>
  iunlockput(dp);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	2e0080e7          	jalr	736(ra) # 80003b90 <iunlockput>
  end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	ab6080e7          	jalr	-1354(ra) # 8000436e <end_op>
  return -1;
    800058c0:	557d                	li	a0,-1
}
    800058c2:	70ae                	ld	ra,232(sp)
    800058c4:	740e                	ld	s0,224(sp)
    800058c6:	64ee                	ld	s1,216(sp)
    800058c8:	694e                	ld	s2,208(sp)
    800058ca:	69ae                	ld	s3,200(sp)
    800058cc:	616d                	addi	sp,sp,240
    800058ce:	8082                	ret

00000000800058d0 <sys_open>:

uint64
sys_open(void)
{
    800058d0:	7131                	addi	sp,sp,-192
    800058d2:	fd06                	sd	ra,184(sp)
    800058d4:	f922                	sd	s0,176(sp)
    800058d6:	f526                	sd	s1,168(sp)
    800058d8:	f14a                	sd	s2,160(sp)
    800058da:	ed4e                	sd	s3,152(sp)
    800058dc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058de:	08000613          	li	a2,128
    800058e2:	f5040593          	addi	a1,s0,-176
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	4f0080e7          	jalr	1264(ra) # 80002dd8 <argstr>
    return -1;
    800058f0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058f2:	0c054163          	bltz	a0,800059b4 <sys_open+0xe4>
    800058f6:	f4c40593          	addi	a1,s0,-180
    800058fa:	4505                	li	a0,1
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	498080e7          	jalr	1176(ra) # 80002d94 <argint>
    80005904:	0a054863          	bltz	a0,800059b4 <sys_open+0xe4>

  begin_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	9e6080e7          	jalr	-1562(ra) # 800042ee <begin_op>

  if(omode & O_CREATE){
    80005910:	f4c42783          	lw	a5,-180(s0)
    80005914:	2007f793          	andi	a5,a5,512
    80005918:	cbdd                	beqz	a5,800059ce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000591a:	4681                	li	a3,0
    8000591c:	4601                	li	a2,0
    8000591e:	4589                	li	a1,2
    80005920:	f5040513          	addi	a0,s0,-176
    80005924:	00000097          	auipc	ra,0x0
    80005928:	974080e7          	jalr	-1676(ra) # 80005298 <create>
    8000592c:	892a                	mv	s2,a0
    if(ip == 0){
    8000592e:	c959                	beqz	a0,800059c4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005930:	04491703          	lh	a4,68(s2)
    80005934:	478d                	li	a5,3
    80005936:	00f71763          	bne	a4,a5,80005944 <sys_open+0x74>
    8000593a:	04695703          	lhu	a4,70(s2)
    8000593e:	47a5                	li	a5,9
    80005940:	0ce7ec63          	bltu	a5,a4,80005a18 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	dc0080e7          	jalr	-576(ra) # 80004704 <filealloc>
    8000594c:	89aa                	mv	s3,a0
    8000594e:	10050263          	beqz	a0,80005a52 <sys_open+0x182>
    80005952:	00000097          	auipc	ra,0x0
    80005956:	904080e7          	jalr	-1788(ra) # 80005256 <fdalloc>
    8000595a:	84aa                	mv	s1,a0
    8000595c:	0e054663          	bltz	a0,80005a48 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005960:	04491703          	lh	a4,68(s2)
    80005964:	478d                	li	a5,3
    80005966:	0cf70463          	beq	a4,a5,80005a2e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000596a:	4789                	li	a5,2
    8000596c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005970:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005974:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005978:	f4c42783          	lw	a5,-180(s0)
    8000597c:	0017c713          	xori	a4,a5,1
    80005980:	8b05                	andi	a4,a4,1
    80005982:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005986:	0037f713          	andi	a4,a5,3
    8000598a:	00e03733          	snez	a4,a4
    8000598e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005992:	4007f793          	andi	a5,a5,1024
    80005996:	c791                	beqz	a5,800059a2 <sys_open+0xd2>
    80005998:	04491703          	lh	a4,68(s2)
    8000599c:	4789                	li	a5,2
    8000599e:	08f70f63          	beq	a4,a5,80005a3c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	04c080e7          	jalr	76(ra) # 800039f0 <iunlock>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	9c2080e7          	jalr	-1598(ra) # 8000436e <end_op>

  return fd;
}
    800059b4:	8526                	mv	a0,s1
    800059b6:	70ea                	ld	ra,184(sp)
    800059b8:	744a                	ld	s0,176(sp)
    800059ba:	74aa                	ld	s1,168(sp)
    800059bc:	790a                	ld	s2,160(sp)
    800059be:	69ea                	ld	s3,152(sp)
    800059c0:	6129                	addi	sp,sp,192
    800059c2:	8082                	ret
      end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	9aa080e7          	jalr	-1622(ra) # 8000436e <end_op>
      return -1;
    800059cc:	b7e5                	j	800059b4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059ce:	f5040513          	addi	a0,s0,-176
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	70c080e7          	jalr	1804(ra) # 800040de <namei>
    800059da:	892a                	mv	s2,a0
    800059dc:	c905                	beqz	a0,80005a0c <sys_open+0x13c>
    ilock(ip);
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	f50080e7          	jalr	-176(ra) # 8000392e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059e6:	04491703          	lh	a4,68(s2)
    800059ea:	4785                	li	a5,1
    800059ec:	f4f712e3          	bne	a4,a5,80005930 <sys_open+0x60>
    800059f0:	f4c42783          	lw	a5,-180(s0)
    800059f4:	dba1                	beqz	a5,80005944 <sys_open+0x74>
      iunlockput(ip);
    800059f6:	854a                	mv	a0,s2
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	198080e7          	jalr	408(ra) # 80003b90 <iunlockput>
      end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	96e080e7          	jalr	-1682(ra) # 8000436e <end_op>
      return -1;
    80005a08:	54fd                	li	s1,-1
    80005a0a:	b76d                	j	800059b4 <sys_open+0xe4>
      end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	962080e7          	jalr	-1694(ra) # 8000436e <end_op>
      return -1;
    80005a14:	54fd                	li	s1,-1
    80005a16:	bf79                	j	800059b4 <sys_open+0xe4>
    iunlockput(ip);
    80005a18:	854a                	mv	a0,s2
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	176080e7          	jalr	374(ra) # 80003b90 <iunlockput>
    end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	94c080e7          	jalr	-1716(ra) # 8000436e <end_op>
    return -1;
    80005a2a:	54fd                	li	s1,-1
    80005a2c:	b761                	j	800059b4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a2e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a32:	04691783          	lh	a5,70(s2)
    80005a36:	02f99223          	sh	a5,36(s3)
    80005a3a:	bf2d                	j	80005974 <sys_open+0xa4>
    itrunc(ip);
    80005a3c:	854a                	mv	a0,s2
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	ffe080e7          	jalr	-2(ra) # 80003a3c <itrunc>
    80005a46:	bfb1                	j	800059a2 <sys_open+0xd2>
      fileclose(f);
    80005a48:	854e                	mv	a0,s3
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	d76080e7          	jalr	-650(ra) # 800047c0 <fileclose>
    iunlockput(ip);
    80005a52:	854a                	mv	a0,s2
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	13c080e7          	jalr	316(ra) # 80003b90 <iunlockput>
    end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	912080e7          	jalr	-1774(ra) # 8000436e <end_op>
    return -1;
    80005a64:	54fd                	li	s1,-1
    80005a66:	b7b9                	j	800059b4 <sys_open+0xe4>

0000000080005a68 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a68:	7175                	addi	sp,sp,-144
    80005a6a:	e506                	sd	ra,136(sp)
    80005a6c:	e122                	sd	s0,128(sp)
    80005a6e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	87e080e7          	jalr	-1922(ra) # 800042ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a78:	08000613          	li	a2,128
    80005a7c:	f7040593          	addi	a1,s0,-144
    80005a80:	4501                	li	a0,0
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	356080e7          	jalr	854(ra) # 80002dd8 <argstr>
    80005a8a:	02054963          	bltz	a0,80005abc <sys_mkdir+0x54>
    80005a8e:	4681                	li	a3,0
    80005a90:	4601                	li	a2,0
    80005a92:	4585                	li	a1,1
    80005a94:	f7040513          	addi	a0,s0,-144
    80005a98:	00000097          	auipc	ra,0x0
    80005a9c:	800080e7          	jalr	-2048(ra) # 80005298 <create>
    80005aa0:	cd11                	beqz	a0,80005abc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	0ee080e7          	jalr	238(ra) # 80003b90 <iunlockput>
  end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	8c4080e7          	jalr	-1852(ra) # 8000436e <end_op>
  return 0;
    80005ab2:	4501                	li	a0,0
}
    80005ab4:	60aa                	ld	ra,136(sp)
    80005ab6:	640a                	ld	s0,128(sp)
    80005ab8:	6149                	addi	sp,sp,144
    80005aba:	8082                	ret
    end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	8b2080e7          	jalr	-1870(ra) # 8000436e <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	b7fd                	j	80005ab4 <sys_mkdir+0x4c>

0000000080005ac8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ac8:	7135                	addi	sp,sp,-160
    80005aca:	ed06                	sd	ra,152(sp)
    80005acc:	e922                	sd	s0,144(sp)
    80005ace:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	81e080e7          	jalr	-2018(ra) # 800042ee <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ad8:	08000613          	li	a2,128
    80005adc:	f7040593          	addi	a1,s0,-144
    80005ae0:	4501                	li	a0,0
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	2f6080e7          	jalr	758(ra) # 80002dd8 <argstr>
    80005aea:	04054a63          	bltz	a0,80005b3e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005aee:	f6c40593          	addi	a1,s0,-148
    80005af2:	4505                	li	a0,1
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	2a0080e7          	jalr	672(ra) # 80002d94 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005afc:	04054163          	bltz	a0,80005b3e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b00:	f6840593          	addi	a1,s0,-152
    80005b04:	4509                	li	a0,2
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	28e080e7          	jalr	654(ra) # 80002d94 <argint>
     argint(1, &major) < 0 ||
    80005b0e:	02054863          	bltz	a0,80005b3e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b12:	f6841683          	lh	a3,-152(s0)
    80005b16:	f6c41603          	lh	a2,-148(s0)
    80005b1a:	458d                	li	a1,3
    80005b1c:	f7040513          	addi	a0,s0,-144
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	778080e7          	jalr	1912(ra) # 80005298 <create>
     argint(2, &minor) < 0 ||
    80005b28:	c919                	beqz	a0,80005b3e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	066080e7          	jalr	102(ra) # 80003b90 <iunlockput>
  end_op();
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	83c080e7          	jalr	-1988(ra) # 8000436e <end_op>
  return 0;
    80005b3a:	4501                	li	a0,0
    80005b3c:	a031                	j	80005b48 <sys_mknod+0x80>
    end_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	830080e7          	jalr	-2000(ra) # 8000436e <end_op>
    return -1;
    80005b46:	557d                	li	a0,-1
}
    80005b48:	60ea                	ld	ra,152(sp)
    80005b4a:	644a                	ld	s0,144(sp)
    80005b4c:	610d                	addi	sp,sp,160
    80005b4e:	8082                	ret

0000000080005b50 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b50:	7135                	addi	sp,sp,-160
    80005b52:	ed06                	sd	ra,152(sp)
    80005b54:	e922                	sd	s0,144(sp)
    80005b56:	e526                	sd	s1,136(sp)
    80005b58:	e14a                	sd	s2,128(sp)
    80005b5a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b5c:	ffffc097          	auipc	ra,0xffffc
    80005b60:	f92080e7          	jalr	-110(ra) # 80001aee <myproc>
    80005b64:	892a                	mv	s2,a0
  
  begin_op();
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	788080e7          	jalr	1928(ra) # 800042ee <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b6e:	08000613          	li	a2,128
    80005b72:	f6040593          	addi	a1,s0,-160
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	260080e7          	jalr	608(ra) # 80002dd8 <argstr>
    80005b80:	04054b63          	bltz	a0,80005bd6 <sys_chdir+0x86>
    80005b84:	f6040513          	addi	a0,s0,-160
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	556080e7          	jalr	1366(ra) # 800040de <namei>
    80005b90:	84aa                	mv	s1,a0
    80005b92:	c131                	beqz	a0,80005bd6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	d9a080e7          	jalr	-614(ra) # 8000392e <ilock>
  if(ip->type != T_DIR){
    80005b9c:	04449703          	lh	a4,68(s1)
    80005ba0:	4785                	li	a5,1
    80005ba2:	04f71063          	bne	a4,a5,80005be2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	e48080e7          	jalr	-440(ra) # 800039f0 <iunlock>
  iput(p->cwd);
    80005bb0:	15093503          	ld	a0,336(s2)
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	f34080e7          	jalr	-204(ra) # 80003ae8 <iput>
  end_op();
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	7b2080e7          	jalr	1970(ra) # 8000436e <end_op>
  p->cwd = ip;
    80005bc4:	14993823          	sd	s1,336(s2)
  return 0;
    80005bc8:	4501                	li	a0,0
}
    80005bca:	60ea                	ld	ra,152(sp)
    80005bcc:	644a                	ld	s0,144(sp)
    80005bce:	64aa                	ld	s1,136(sp)
    80005bd0:	690a                	ld	s2,128(sp)
    80005bd2:	610d                	addi	sp,sp,160
    80005bd4:	8082                	ret
    end_op();
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	798080e7          	jalr	1944(ra) # 8000436e <end_op>
    return -1;
    80005bde:	557d                	li	a0,-1
    80005be0:	b7ed                	j	80005bca <sys_chdir+0x7a>
    iunlockput(ip);
    80005be2:	8526                	mv	a0,s1
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	fac080e7          	jalr	-84(ra) # 80003b90 <iunlockput>
    end_op();
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	782080e7          	jalr	1922(ra) # 8000436e <end_op>
    return -1;
    80005bf4:	557d                	li	a0,-1
    80005bf6:	bfd1                	j	80005bca <sys_chdir+0x7a>

0000000080005bf8 <sys_exec>:

uint64
sys_exec(void)
{
    80005bf8:	7145                	addi	sp,sp,-464
    80005bfa:	e786                	sd	ra,456(sp)
    80005bfc:	e3a2                	sd	s0,448(sp)
    80005bfe:	ff26                	sd	s1,440(sp)
    80005c00:	fb4a                	sd	s2,432(sp)
    80005c02:	f74e                	sd	s3,424(sp)
    80005c04:	f352                	sd	s4,416(sp)
    80005c06:	ef56                	sd	s5,408(sp)
    80005c08:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0a:	08000613          	li	a2,128
    80005c0e:	f4040593          	addi	a1,s0,-192
    80005c12:	4501                	li	a0,0
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	1c4080e7          	jalr	452(ra) # 80002dd8 <argstr>
    return -1;
    80005c1c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c1e:	0c054a63          	bltz	a0,80005cf2 <sys_exec+0xfa>
    80005c22:	e3840593          	addi	a1,s0,-456
    80005c26:	4505                	li	a0,1
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	18e080e7          	jalr	398(ra) # 80002db6 <argaddr>
    80005c30:	0c054163          	bltz	a0,80005cf2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c34:	10000613          	li	a2,256
    80005c38:	4581                	li	a1,0
    80005c3a:	e4040513          	addi	a0,s0,-448
    80005c3e:	ffffb097          	auipc	ra,0xffffb
    80005c42:	0ba080e7          	jalr	186(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c46:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c4a:	89a6                	mv	s3,s1
    80005c4c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c4e:	02000a13          	li	s4,32
    80005c52:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c56:	00391793          	slli	a5,s2,0x3
    80005c5a:	e3040593          	addi	a1,s0,-464
    80005c5e:	e3843503          	ld	a0,-456(s0)
    80005c62:	953e                	add	a0,a0,a5
    80005c64:	ffffd097          	auipc	ra,0xffffd
    80005c68:	096080e7          	jalr	150(ra) # 80002cfa <fetchaddr>
    80005c6c:	02054a63          	bltz	a0,80005ca0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c70:	e3043783          	ld	a5,-464(s0)
    80005c74:	c3b9                	beqz	a5,80005cba <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c76:	ffffb097          	auipc	ra,0xffffb
    80005c7a:	e96080e7          	jalr	-362(ra) # 80000b0c <kalloc>
    80005c7e:	85aa                	mv	a1,a0
    80005c80:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c84:	cd11                	beqz	a0,80005ca0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c86:	6605                	lui	a2,0x1
    80005c88:	e3043503          	ld	a0,-464(s0)
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	0c0080e7          	jalr	192(ra) # 80002d4c <fetchstr>
    80005c94:	00054663          	bltz	a0,80005ca0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c98:	0905                	addi	s2,s2,1
    80005c9a:	09a1                	addi	s3,s3,8
    80005c9c:	fb491be3          	bne	s2,s4,80005c52 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca0:	10048913          	addi	s2,s1,256
    80005ca4:	6088                	ld	a0,0(s1)
    80005ca6:	c529                	beqz	a0,80005cf0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	d68080e7          	jalr	-664(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb0:	04a1                	addi	s1,s1,8
    80005cb2:	ff2499e3          	bne	s1,s2,80005ca4 <sys_exec+0xac>
  return -1;
    80005cb6:	597d                	li	s2,-1
    80005cb8:	a82d                	j	80005cf2 <sys_exec+0xfa>
      argv[i] = 0;
    80005cba:	0a8e                	slli	s5,s5,0x3
    80005cbc:	fc040793          	addi	a5,s0,-64
    80005cc0:	9abe                	add	s5,s5,a5
    80005cc2:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005cc6:	e4040593          	addi	a1,s0,-448
    80005cca:	f4040513          	addi	a0,s0,-192
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	178080e7          	jalr	376(ra) # 80004e46 <exec>
    80005cd6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd8:	10048993          	addi	s3,s1,256
    80005cdc:	6088                	ld	a0,0(s1)
    80005cde:	c911                	beqz	a0,80005cf2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce0:	ffffb097          	auipc	ra,0xffffb
    80005ce4:	d30080e7          	jalr	-720(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce8:	04a1                	addi	s1,s1,8
    80005cea:	ff3499e3          	bne	s1,s3,80005cdc <sys_exec+0xe4>
    80005cee:	a011                	j	80005cf2 <sys_exec+0xfa>
  return -1;
    80005cf0:	597d                	li	s2,-1
}
    80005cf2:	854a                	mv	a0,s2
    80005cf4:	60be                	ld	ra,456(sp)
    80005cf6:	641e                	ld	s0,448(sp)
    80005cf8:	74fa                	ld	s1,440(sp)
    80005cfa:	795a                	ld	s2,432(sp)
    80005cfc:	79ba                	ld	s3,424(sp)
    80005cfe:	7a1a                	ld	s4,416(sp)
    80005d00:	6afa                	ld	s5,408(sp)
    80005d02:	6179                	addi	sp,sp,464
    80005d04:	8082                	ret

0000000080005d06 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d06:	7139                	addi	sp,sp,-64
    80005d08:	fc06                	sd	ra,56(sp)
    80005d0a:	f822                	sd	s0,48(sp)
    80005d0c:	f426                	sd	s1,40(sp)
    80005d0e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d10:	ffffc097          	auipc	ra,0xffffc
    80005d14:	dde080e7          	jalr	-546(ra) # 80001aee <myproc>
    80005d18:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d1a:	fd840593          	addi	a1,s0,-40
    80005d1e:	4501                	li	a0,0
    80005d20:	ffffd097          	auipc	ra,0xffffd
    80005d24:	096080e7          	jalr	150(ra) # 80002db6 <argaddr>
    return -1;
    80005d28:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d2a:	0e054063          	bltz	a0,80005e0a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d2e:	fc840593          	addi	a1,s0,-56
    80005d32:	fd040513          	addi	a0,s0,-48
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	de0080e7          	jalr	-544(ra) # 80004b16 <pipealloc>
    return -1;
    80005d3e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d40:	0c054563          	bltz	a0,80005e0a <sys_pipe+0x104>
  fd0 = -1;
    80005d44:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d48:	fd043503          	ld	a0,-48(s0)
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	50a080e7          	jalr	1290(ra) # 80005256 <fdalloc>
    80005d54:	fca42223          	sw	a0,-60(s0)
    80005d58:	08054c63          	bltz	a0,80005df0 <sys_pipe+0xea>
    80005d5c:	fc843503          	ld	a0,-56(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	4f6080e7          	jalr	1270(ra) # 80005256 <fdalloc>
    80005d68:	fca42023          	sw	a0,-64(s0)
    80005d6c:	06054863          	bltz	a0,80005ddc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d70:	4691                	li	a3,4
    80005d72:	fc440613          	addi	a2,s0,-60
    80005d76:	fd843583          	ld	a1,-40(s0)
    80005d7a:	68a8                	ld	a0,80(s1)
    80005d7c:	ffffc097          	auipc	ra,0xffffc
    80005d80:	92e080e7          	jalr	-1746(ra) # 800016aa <copyout>
    80005d84:	02054063          	bltz	a0,80005da4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d88:	4691                	li	a3,4
    80005d8a:	fc040613          	addi	a2,s0,-64
    80005d8e:	fd843583          	ld	a1,-40(s0)
    80005d92:	0591                	addi	a1,a1,4
    80005d94:	68a8                	ld	a0,80(s1)
    80005d96:	ffffc097          	auipc	ra,0xffffc
    80005d9a:	914080e7          	jalr	-1772(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d9e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da0:	06055563          	bgez	a0,80005e0a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005da4:	fc442783          	lw	a5,-60(s0)
    80005da8:	07e9                	addi	a5,a5,26
    80005daa:	078e                	slli	a5,a5,0x3
    80005dac:	97a6                	add	a5,a5,s1
    80005dae:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005db2:	fc042503          	lw	a0,-64(s0)
    80005db6:	0569                	addi	a0,a0,26
    80005db8:	050e                	slli	a0,a0,0x3
    80005dba:	9526                	add	a0,a0,s1
    80005dbc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc0:	fd043503          	ld	a0,-48(s0)
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	9fc080e7          	jalr	-1540(ra) # 800047c0 <fileclose>
    fileclose(wf);
    80005dcc:	fc843503          	ld	a0,-56(s0)
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	9f0080e7          	jalr	-1552(ra) # 800047c0 <fileclose>
    return -1;
    80005dd8:	57fd                	li	a5,-1
    80005dda:	a805                	j	80005e0a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ddc:	fc442783          	lw	a5,-60(s0)
    80005de0:	0007c863          	bltz	a5,80005df0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005de4:	01a78513          	addi	a0,a5,26
    80005de8:	050e                	slli	a0,a0,0x3
    80005dea:	9526                	add	a0,a0,s1
    80005dec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005df0:	fd043503          	ld	a0,-48(s0)
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	9cc080e7          	jalr	-1588(ra) # 800047c0 <fileclose>
    fileclose(wf);
    80005dfc:	fc843503          	ld	a0,-56(s0)
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	9c0080e7          	jalr	-1600(ra) # 800047c0 <fileclose>
    return -1;
    80005e08:	57fd                	li	a5,-1
}
    80005e0a:	853e                	mv	a0,a5
    80005e0c:	70e2                	ld	ra,56(sp)
    80005e0e:	7442                	ld	s0,48(sp)
    80005e10:	74a2                	ld	s1,40(sp)
    80005e12:	6121                	addi	sp,sp,64
    80005e14:	8082                	ret
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	d4ffc0ef          	jal	ra,80002bae <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	710c                	ld	a1,32(a0)
    80005ebc:	7510                	ld	a2,40(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	bca080e7          	jalr	-1078(ra) # 80001ac2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	b92080e7          	jalr	-1134(ra) # 80001ac2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	b6a080e7          	jalr	-1174(ra) # 80001ac2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f84:	0001e797          	auipc	a5,0x1e
    80005f88:	07c78793          	addi	a5,a5,124 # 80024000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	eba1                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451713          	slli	a4,a0,0x4
    80005f9e:	00020797          	auipc	a5,0x20
    80005fa2:	0627b783          	ld	a5,98(a5) # 80026000 <disk+0x2000>
    80005fa6:	97ba                	add	a5,a5,a4
    80005fa8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fac:	0001e797          	auipc	a5,0x1e
    80005fb0:	05478793          	addi	a5,a5,84 # 80024000 <disk>
    80005fb4:	97aa                	add	a5,a5,a0
    80005fb6:	6509                	lui	a0,0x2
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fc0:	00020517          	auipc	a0,0x20
    80005fc4:	05850513          	addi	a0,a0,88 # 80026018 <disk+0x2018>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	67c080e7          	jalr	1660(ra) # 80002644 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fd8:	00002517          	auipc	a0,0x2
    80005fdc:	7f050513          	addi	a0,a0,2032 # 800087c8 <syscalls+0x330>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	7f850513          	addi	a0,a0,2040 # 800087e0 <syscalls+0x348>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006002:	00002597          	auipc	a1,0x2
    80006006:	7f658593          	addi	a1,a1,2038 # 800087f8 <syscalls+0x360>
    8000600a:	00020517          	auipc	a0,0x20
    8000600e:	09e50513          	addi	a0,a0,158 # 800260a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	b5a080e7          	jalr	-1190(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	4398                	lw	a4,0(a5)
    80006020:	2701                	sext.w	a4,a4
    80006022:	747277b7          	lui	a5,0x74727
    80006026:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602a:	0ef71163          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	43dc                	lw	a5,4(a5)
    80006034:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006036:	4705                	li	a4,1
    80006038:	0ce79a63          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	479c                	lw	a5,8(a5)
    80006042:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006044:	4709                	li	a4,2
    80006046:	0ce79363          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	0af71963          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	4705                	li	a4,1
    80006064:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	470d                	li	a4,3
    80006068:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000606c:	c7ffe737          	lui	a4,0xc7ffe
    80006070:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80006074:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006076:	2701                	sext.w	a4,a4
    80006078:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	472d                	li	a4,11
    8000607c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	473d                	li	a4,15
    80006080:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006082:	6705                	lui	a4,0x1
    80006084:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006086:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000608a:	5bdc                	lw	a5,52(a5)
    8000608c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608e:	c7d9                	beqz	a5,8000611c <virtio_disk_init+0x124>
  if(max < NUM)
    80006090:	471d                	li	a4,7
    80006092:	08f77d63          	bgeu	a4,a5,8000612c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006096:	100014b7          	lui	s1,0x10001
    8000609a:	47a1                	li	a5,8
    8000609c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000609e:	6609                	lui	a2,0x2
    800060a0:	4581                	li	a1,0
    800060a2:	0001e517          	auipc	a0,0x1e
    800060a6:	f5e50513          	addi	a0,a0,-162 # 80024000 <disk>
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	c4e080e7          	jalr	-946(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060b2:	0001e717          	auipc	a4,0x1e
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80024000 <disk>
    800060ba:	00c75793          	srli	a5,a4,0xc
    800060be:	2781                	sext.w	a5,a5
    800060c0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060c2:	00020797          	auipc	a5,0x20
    800060c6:	f3e78793          	addi	a5,a5,-194 # 80026000 <disk+0x2000>
    800060ca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060cc:	0001e717          	auipc	a4,0x1e
    800060d0:	fb470713          	addi	a4,a4,-76 # 80024080 <disk+0x80>
    800060d4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060d6:	0001f717          	auipc	a4,0x1f
    800060da:	f2a70713          	addi	a4,a4,-214 # 80025000 <disk+0x1000>
    800060de:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060e0:	4705                	li	a4,1
    800060e2:	00e78c23          	sb	a4,24(a5)
    800060e6:	00e78ca3          	sb	a4,25(a5)
    800060ea:	00e78d23          	sb	a4,26(a5)
    800060ee:	00e78da3          	sb	a4,27(a5)
    800060f2:	00e78e23          	sb	a4,28(a5)
    800060f6:	00e78ea3          	sb	a4,29(a5)
    800060fa:	00e78f23          	sb	a4,30(a5)
    800060fe:	00e78fa3          	sb	a4,31(a5)
}
    80006102:	60e2                	ld	ra,24(sp)
    80006104:	6442                	ld	s0,16(sp)
    80006106:	64a2                	ld	s1,8(sp)
    80006108:	6105                	addi	sp,sp,32
    8000610a:	8082                	ret
    panic("could not find virtio disk");
    8000610c:	00002517          	auipc	a0,0x2
    80006110:	6fc50513          	addi	a0,a0,1788 # 80008808 <syscalls+0x370>
    80006114:	ffffa097          	auipc	ra,0xffffa
    80006118:	42c080e7          	jalr	1068(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000611c:	00002517          	auipc	a0,0x2
    80006120:	70c50513          	addi	a0,a0,1804 # 80008828 <syscalls+0x390>
    80006124:	ffffa097          	auipc	ra,0xffffa
    80006128:	41c080e7          	jalr	1052(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000612c:	00002517          	auipc	a0,0x2
    80006130:	71c50513          	addi	a0,a0,1820 # 80008848 <syscalls+0x3b0>
    80006134:	ffffa097          	auipc	ra,0xffffa
    80006138:	40c080e7          	jalr	1036(ra) # 80000540 <panic>

000000008000613c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000613c:	7175                	addi	sp,sp,-144
    8000613e:	e506                	sd	ra,136(sp)
    80006140:	e122                	sd	s0,128(sp)
    80006142:	fca6                	sd	s1,120(sp)
    80006144:	f8ca                	sd	s2,112(sp)
    80006146:	f4ce                	sd	s3,104(sp)
    80006148:	f0d2                	sd	s4,96(sp)
    8000614a:	ecd6                	sd	s5,88(sp)
    8000614c:	e8da                	sd	s6,80(sp)
    8000614e:	e4de                	sd	s7,72(sp)
    80006150:	e0e2                	sd	s8,64(sp)
    80006152:	fc66                	sd	s9,56(sp)
    80006154:	f86a                	sd	s10,48(sp)
    80006156:	f46e                	sd	s11,40(sp)
    80006158:	0900                	addi	s0,sp,144
    8000615a:	8aaa                	mv	s5,a0
    8000615c:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000615e:	00c52c83          	lw	s9,12(a0)
    80006162:	001c9c9b          	slliw	s9,s9,0x1
    80006166:	1c82                	slli	s9,s9,0x20
    80006168:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000616c:	00020517          	auipc	a0,0x20
    80006170:	f3c50513          	addi	a0,a0,-196 # 800260a8 <disk+0x20a8>
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	a88080e7          	jalr	-1400(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    8000617c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000617e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006180:	0001ec17          	auipc	s8,0x1e
    80006184:	e80c0c13          	addi	s8,s8,-384 # 80024000 <disk>
    80006188:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000618a:	4b0d                	li	s6,3
    8000618c:	a0ad                	j	800061f6 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000618e:	00fc0733          	add	a4,s8,a5
    80006192:	975e                	add	a4,a4,s7
    80006194:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006198:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000619a:	0207c563          	bltz	a5,800061c4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000619e:	2905                	addiw	s2,s2,1
    800061a0:	0611                	addi	a2,a2,4
    800061a2:	19690d63          	beq	s2,s6,8000633c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061a6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061a8:	00020717          	auipc	a4,0x20
    800061ac:	e7070713          	addi	a4,a4,-400 # 80026018 <disk+0x2018>
    800061b0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061b2:	00074683          	lbu	a3,0(a4)
    800061b6:	fee1                	bnez	a3,8000618e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061b8:	2785                	addiw	a5,a5,1
    800061ba:	0705                	addi	a4,a4,1
    800061bc:	fe979be3          	bne	a5,s1,800061b2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061c0:	57fd                	li	a5,-1
    800061c2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061c4:	01205d63          	blez	s2,800061de <virtio_disk_rw+0xa2>
    800061c8:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061ca:	000a2503          	lw	a0,0(s4)
    800061ce:	00000097          	auipc	ra,0x0
    800061d2:	da8080e7          	jalr	-600(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061d6:	2d85                	addiw	s11,s11,1
    800061d8:	0a11                	addi	s4,s4,4
    800061da:	ffb918e3          	bne	s2,s11,800061ca <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061de:	00020597          	auipc	a1,0x20
    800061e2:	eca58593          	addi	a1,a1,-310 # 800260a8 <disk+0x20a8>
    800061e6:	00020517          	auipc	a0,0x20
    800061ea:	e3250513          	addi	a0,a0,-462 # 80026018 <disk+0x2018>
    800061ee:	ffffc097          	auipc	ra,0xffffc
    800061f2:	2ca080e7          	jalr	714(ra) # 800024b8 <sleep>
  for(int i = 0; i < 3; i++){
    800061f6:	f8040a13          	addi	s4,s0,-128
{
    800061fa:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061fc:	894e                	mv	s2,s3
    800061fe:	b765                	j	800061a6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006200:	00020717          	auipc	a4,0x20
    80006204:	e0073703          	ld	a4,-512(a4) # 80026000 <disk+0x2000>
    80006208:	973e                	add	a4,a4,a5
    8000620a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620e:	0001e517          	auipc	a0,0x1e
    80006212:	df250513          	addi	a0,a0,-526 # 80024000 <disk>
    80006216:	00020717          	auipc	a4,0x20
    8000621a:	dea70713          	addi	a4,a4,-534 # 80026000 <disk+0x2000>
    8000621e:	6314                	ld	a3,0(a4)
    80006220:	96be                	add	a3,a3,a5
    80006222:	00c6d603          	lhu	a2,12(a3)
    80006226:	00166613          	ori	a2,a2,1
    8000622a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000622e:	f8842683          	lw	a3,-120(s0)
    80006232:	6310                	ld	a2,0(a4)
    80006234:	97b2                	add	a5,a5,a2
    80006236:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000623a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000623e:	0612                	slli	a2,a2,0x4
    80006240:	962a                	add	a2,a2,a0
    80006242:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006246:	00469793          	slli	a5,a3,0x4
    8000624a:	630c                	ld	a1,0(a4)
    8000624c:	95be                	add	a1,a1,a5
    8000624e:	6689                	lui	a3,0x2
    80006250:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006254:	96ca                	add	a3,a3,s2
    80006256:	96aa                	add	a3,a3,a0
    80006258:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    8000625a:	6314                	ld	a3,0(a4)
    8000625c:	96be                	add	a3,a3,a5
    8000625e:	4585                	li	a1,1
    80006260:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006262:	6314                	ld	a3,0(a4)
    80006264:	96be                	add	a3,a3,a5
    80006266:	4509                	li	a0,2
    80006268:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000626c:	6314                	ld	a3,0(a4)
    8000626e:	97b6                	add	a5,a5,a3
    80006270:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006274:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006278:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000627c:	6714                	ld	a3,8(a4)
    8000627e:	0026d783          	lhu	a5,2(a3)
    80006282:	8b9d                	andi	a5,a5,7
    80006284:	0789                	addi	a5,a5,2
    80006286:	0786                	slli	a5,a5,0x1
    80006288:	97b6                	add	a5,a5,a3
    8000628a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000628e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006292:	6718                	ld	a4,8(a4)
    80006294:	00275783          	lhu	a5,2(a4)
    80006298:	2785                	addiw	a5,a5,1
    8000629a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000629e:	100017b7          	lui	a5,0x10001
    800062a2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062a6:	004aa783          	lw	a5,4(s5)
    800062aa:	02b79163          	bne	a5,a1,800062cc <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062ae:	00020917          	auipc	s2,0x20
    800062b2:	dfa90913          	addi	s2,s2,-518 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062b8:	85ca                	mv	a1,s2
    800062ba:	8556                	mv	a0,s5
    800062bc:	ffffc097          	auipc	ra,0xffffc
    800062c0:	1fc080e7          	jalr	508(ra) # 800024b8 <sleep>
  while(b->disk == 1) {
    800062c4:	004aa783          	lw	a5,4(s5)
    800062c8:	fe9788e3          	beq	a5,s1,800062b8 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800062cc:	f8042483          	lw	s1,-128(s0)
    800062d0:	20048793          	addi	a5,s1,512
    800062d4:	00479713          	slli	a4,a5,0x4
    800062d8:	0001e797          	auipc	a5,0x1e
    800062dc:	d2878793          	addi	a5,a5,-728 # 80024000 <disk>
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062e6:	00020917          	auipc	s2,0x20
    800062ea:	d1a90913          	addi	s2,s2,-742 # 80026000 <disk+0x2000>
    800062ee:	a019                	j	800062f4 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    800062f0:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062f4:	8526                	mv	a0,s1
    800062f6:	00000097          	auipc	ra,0x0
    800062fa:	c80080e7          	jalr	-896(ra) # 80005f76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062fe:	0492                	slli	s1,s1,0x4
    80006300:	00093783          	ld	a5,0(s2)
    80006304:	94be                	add	s1,s1,a5
    80006306:	00c4d783          	lhu	a5,12(s1)
    8000630a:	8b85                	andi	a5,a5,1
    8000630c:	f3f5                	bnez	a5,800062f0 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000630e:	00020517          	auipc	a0,0x20
    80006312:	d9a50513          	addi	a0,a0,-614 # 800260a8 <disk+0x20a8>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	99a080e7          	jalr	-1638(ra) # 80000cb0 <release>
}
    8000631e:	60aa                	ld	ra,136(sp)
    80006320:	640a                	ld	s0,128(sp)
    80006322:	74e6                	ld	s1,120(sp)
    80006324:	7946                	ld	s2,112(sp)
    80006326:	79a6                	ld	s3,104(sp)
    80006328:	7a06                	ld	s4,96(sp)
    8000632a:	6ae6                	ld	s5,88(sp)
    8000632c:	6b46                	ld	s6,80(sp)
    8000632e:	6ba6                	ld	s7,72(sp)
    80006330:	6c06                	ld	s8,64(sp)
    80006332:	7ce2                	ld	s9,56(sp)
    80006334:	7d42                	ld	s10,48(sp)
    80006336:	7da2                	ld	s11,40(sp)
    80006338:	6149                	addi	sp,sp,144
    8000633a:	8082                	ret
  if(write)
    8000633c:	01a037b3          	snez	a5,s10
    80006340:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006344:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006348:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000634c:	f8042483          	lw	s1,-128(s0)
    80006350:	00449913          	slli	s2,s1,0x4
    80006354:	00020997          	auipc	s3,0x20
    80006358:	cac98993          	addi	s3,s3,-852 # 80026000 <disk+0x2000>
    8000635c:	0009ba03          	ld	s4,0(s3)
    80006360:	9a4a                	add	s4,s4,s2
    80006362:	f7040513          	addi	a0,s0,-144
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	d52080e7          	jalr	-686(ra) # 800010b8 <kvmpa>
    8000636e:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006372:	0009b783          	ld	a5,0(s3)
    80006376:	97ca                	add	a5,a5,s2
    80006378:	4741                	li	a4,16
    8000637a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000637c:	0009b783          	ld	a5,0(s3)
    80006380:	97ca                	add	a5,a5,s2
    80006382:	4705                	li	a4,1
    80006384:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006388:	f8442783          	lw	a5,-124(s0)
    8000638c:	0009b703          	ld	a4,0(s3)
    80006390:	974a                	add	a4,a4,s2
    80006392:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006396:	0792                	slli	a5,a5,0x4
    80006398:	0009b703          	ld	a4,0(s3)
    8000639c:	973e                	add	a4,a4,a5
    8000639e:	058a8693          	addi	a3,s5,88
    800063a2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063a4:	0009b703          	ld	a4,0(s3)
    800063a8:	973e                	add	a4,a4,a5
    800063aa:	40000693          	li	a3,1024
    800063ae:	c714                	sw	a3,8(a4)
  if(write)
    800063b0:	e40d18e3          	bnez	s10,80006200 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063b4:	00020717          	auipc	a4,0x20
    800063b8:	c4c73703          	ld	a4,-948(a4) # 80026000 <disk+0x2000>
    800063bc:	973e                	add	a4,a4,a5
    800063be:	4689                	li	a3,2
    800063c0:	00d71623          	sh	a3,12(a4)
    800063c4:	b5a9                	j	8000620e <virtio_disk_rw+0xd2>

00000000800063c6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063c6:	1101                	addi	sp,sp,-32
    800063c8:	ec06                	sd	ra,24(sp)
    800063ca:	e822                	sd	s0,16(sp)
    800063cc:	e426                	sd	s1,8(sp)
    800063ce:	e04a                	sd	s2,0(sp)
    800063d0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063d2:	00020517          	auipc	a0,0x20
    800063d6:	cd650513          	addi	a0,a0,-810 # 800260a8 <disk+0x20a8>
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	822080e7          	jalr	-2014(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063e2:	00020717          	auipc	a4,0x20
    800063e6:	c1e70713          	addi	a4,a4,-994 # 80026000 <disk+0x2000>
    800063ea:	02075783          	lhu	a5,32(a4)
    800063ee:	6b18                	ld	a4,16(a4)
    800063f0:	00275683          	lhu	a3,2(a4)
    800063f4:	8ebd                	xor	a3,a3,a5
    800063f6:	8a9d                	andi	a3,a3,7
    800063f8:	cab9                	beqz	a3,8000644e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063fa:	0001e917          	auipc	s2,0x1e
    800063fe:	c0690913          	addi	s2,s2,-1018 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006402:	00020497          	auipc	s1,0x20
    80006406:	bfe48493          	addi	s1,s1,-1026 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000640a:	078e                	slli	a5,a5,0x3
    8000640c:	97ba                	add	a5,a5,a4
    8000640e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006410:	20078713          	addi	a4,a5,512
    80006414:	0712                	slli	a4,a4,0x4
    80006416:	974a                	add	a4,a4,s2
    80006418:	03074703          	lbu	a4,48(a4)
    8000641c:	ef21                	bnez	a4,80006474 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000641e:	20078793          	addi	a5,a5,512
    80006422:	0792                	slli	a5,a5,0x4
    80006424:	97ca                	add	a5,a5,s2
    80006426:	7798                	ld	a4,40(a5)
    80006428:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000642c:	7788                	ld	a0,40(a5)
    8000642e:	ffffc097          	auipc	ra,0xffffc
    80006432:	216080e7          	jalr	534(ra) # 80002644 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006436:	0204d783          	lhu	a5,32(s1)
    8000643a:	2785                	addiw	a5,a5,1
    8000643c:	8b9d                	andi	a5,a5,7
    8000643e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006442:	6898                	ld	a4,16(s1)
    80006444:	00275683          	lhu	a3,2(a4)
    80006448:	8a9d                	andi	a3,a3,7
    8000644a:	fcf690e3          	bne	a3,a5,8000640a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000644e:	10001737          	lui	a4,0x10001
    80006452:	533c                	lw	a5,96(a4)
    80006454:	8b8d                	andi	a5,a5,3
    80006456:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006458:	00020517          	auipc	a0,0x20
    8000645c:	c5050513          	addi	a0,a0,-944 # 800260a8 <disk+0x20a8>
    80006460:	ffffb097          	auipc	ra,0xffffb
    80006464:	850080e7          	jalr	-1968(ra) # 80000cb0 <release>
}
    80006468:	60e2                	ld	ra,24(sp)
    8000646a:	6442                	ld	s0,16(sp)
    8000646c:	64a2                	ld	s1,8(sp)
    8000646e:	6902                	ld	s2,0(sp)
    80006470:	6105                	addi	sp,sp,32
    80006472:	8082                	ret
      panic("virtio_disk_intr status");
    80006474:	00002517          	auipc	a0,0x2
    80006478:	3f450513          	addi	a0,a0,1012 # 80008868 <syscalls+0x3d0>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	0c4080e7          	jalr	196(ra) # 80000540 <panic>
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


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
    80000128:	6d2080e7          	jalr	1746(ra) # 800027f6 <either_copyin>
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
    800001dc:	352080e7          	jalr	850(ra) # 8000252a <sleep>
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
    80000218:	58c080e7          	jalr	1420(ra) # 800027a0 <either_copyout>
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
    800002f8:	558080e7          	jalr	1368(ra) # 8000284c <procdump>
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
    8000044c:	26e080e7          	jalr	622(ra) # 800026b6 <wakeup>
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
    800008a4:	e16080e7          	jalr	-490(ra) # 800026b6 <wakeup>
    
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
    8000093e:	bf0080e7          	jalr	-1040(ra) # 8000252a <sleep>
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
    80000ef0:	aa2080e7          	jalr	-1374(ra) # 8000298e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	04c080e7          	jalr	76(ra) # 80005f40 <plicinithart>
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
    80000f58:	a12080e7          	jalr	-1518(ra) # 80002966 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	a32080e7          	jalr	-1486(ra) # 8000298e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fc6080e7          	jalr	-58(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fd4080e7          	jalr	-44(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	182080e7          	jalr	386(ra) # 800030f6 <binit>
    iinit();         // inode cache
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	814080e7          	jalr	-2028(ra) # 80003790 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7b2080e7          	jalr	1970(ra) # 80004736 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0bc080e7          	jalr	188(ra) # 80006048 <virtio_disk_init>
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
    80001a24:	a4890913          	addi	s2,s2,-1464 # 80012468 <proc>
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
    80001a46:	a26a0a13          	addi	s4,s4,-1498 # 80018468 <tickslock>
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
    80001b44:	d207a783          	lw	a5,-736(a5) # 80008860 <first.1>
    80001b48:	eb89                	bnez	a5,80001b5a <forkret+0x32>
  usertrapret();
    80001b4a:	00001097          	auipc	ra,0x1
    80001b4e:	e5c080e7          	jalr	-420(ra) # 800029a6 <usertrapret>
}
    80001b52:	60a2                	ld	ra,8(sp)
    80001b54:	6402                	ld	s0,0(sp)
    80001b56:	0141                	addi	sp,sp,16
    80001b58:	8082                	ret
    first = 0;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	d007a323          	sw	zero,-762(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b62:	4505                	li	a0,1
    80001b64:	00002097          	auipc	ra,0x2
    80001b68:	bac080e7          	jalr	-1108(ra) # 80003710 <fsinit>
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
    80001b90:	cd878793          	addi	a5,a5,-808 # 80008864 <nextpid>
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
    80001d56:	71648493          	addi	s1,s1,1814 # 80012468 <proc>
    80001d5a:	00016917          	auipc	s2,0x16
    80001d5e:	70e90913          	addi	s2,s2,1806 # 80018468 <tickslock>
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
    80001e2a:	a4a58593          	addi	a1,a1,-1462 # 80008870 <initcode>
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
    80001e68:	2d4080e7          	jalr	724(ra) # 80004138 <namei>
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
    80001fce:	7fe080e7          	jalr	2046(ra) # 800047c8 <filedup>
    80001fd2:	00a93023          	sd	a0,0(s2)
    80001fd6:	b7e5                	j	80001fbe <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001fd8:	150ab503          	ld	a0,336(s5)
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	96e080e7          	jalr	-1682(ra) # 8000394a <idup>
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
    80002056:	41648493          	addi	s1,s1,1046 # 80012468 <proc>
      pp->parent = initproc;
    8000205a:	00007a17          	auipc	s4,0x7
    8000205e:	fbea0a13          	addi	s4,s4,-66 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002062:	00016997          	auipc	s3,0x16
    80002066:	40698993          	addi	s3,s3,1030 # 80018468 <tickslock>
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
    800020a6:	7159                	addi	sp,sp,-112
    800020a8:	f486                	sd	ra,104(sp)
    800020aa:	f0a2                	sd	s0,96(sp)
    800020ac:	eca6                	sd	s1,88(sp)
    800020ae:	e8ca                	sd	s2,80(sp)
    800020b0:	e4ce                	sd	s3,72(sp)
    800020b2:	e0d2                	sd	s4,64(sp)
    800020b4:	fc56                	sd	s5,56(sp)
    800020b6:	f85a                	sd	s6,48(sp)
    800020b8:	f45e                	sd	s7,40(sp)
    800020ba:	f062                	sd	s8,32(sp)
    800020bc:	ec66                	sd	s9,24(sp)
    800020be:	e86a                	sd	s10,16(sp)
    800020c0:	e46e                	sd	s11,8(sp)
    800020c2:	1880                	addi	s0,sp,112
    800020c4:	8792                	mv	a5,tp
  int id = r_tp();
    800020c6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020c8:	00779c93          	slli	s9,a5,0x7
    800020cc:	00010717          	auipc	a4,0x10
    800020d0:	88470713          	addi	a4,a4,-1916 # 80011950 <Q>
    800020d4:	9766                	add	a4,a4,s9
    800020d6:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    800020da:	00010717          	auipc	a4,0x10
    800020de:	e9670713          	addi	a4,a4,-362 # 80011f70 <cpus+0x8>
    800020e2:	9cba                	add	s9,s9,a4
  int exec = 0;
    800020e4:	4c01                	li	s8,0
        c->proc = p;
    800020e6:	00010d97          	auipc	s11,0x10
    800020ea:	86ad8d93          	addi	s11,s11,-1942 # 80011950 <Q>
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	00fd8b33          	add	s6,s11,a5
        pid[tail] = p->pid;
    800020f4:	00007b97          	auipc	s7,0x7
    800020f8:	f2cb8b93          	addi	s7,s7,-212 # 80009020 <tail>
    800020fc:	00011d17          	auipc	s10,0x11
    80002100:	854d0d13          	addi	s10,s10,-1964 # 80012950 <proc+0x4e8>
    80002104:	a2b1                	j	80002250 <scheduler+0x1aa>
      exec = 0;
    80002106:	4c01                	li	s8,0
    80002108:	a2a1                	j	80002250 <scheduler+0x1aa>
        movequeue(p, 1, MOVE);
    8000210a:	4601                	li	a2,0
    8000210c:	85ce                	mv	a1,s3
    8000210e:	8526                	mv	a0,s1
    80002110:	00000097          	auipc	ra,0x0
    80002114:	836080e7          	jalr	-1994(ra) # 80001946 <movequeue>
        break;
    80002118:	a8a1                	j	80002170 <scheduler+0xca>
        movequeue(p, 0, MOVE);
    8000211a:	4601                	li	a2,0
    8000211c:	4581                	li	a1,0
    8000211e:	8526                	mv	a0,s1
    80002120:	00000097          	auipc	ra,0x0
    80002124:	826080e7          	jalr	-2010(ra) # 80001946 <movequeue>
        break;
    80002128:	a0a1                	j	80002170 <scheduler+0xca>
        movequeue(p, 2, MOVE);
    8000212a:	4601                	li	a2,0
    8000212c:	85ca                	mv	a1,s2
    8000212e:	8526                	mv	a0,s1
    80002130:	00000097          	auipc	ra,0x0
    80002134:	816080e7          	jalr	-2026(ra) # 80001946 <movequeue>
        break;
    80002138:	a825                	j	80002170 <scheduler+0xca>
          (p->Qtime[2])++;
    8000213a:	1744a783          	lw	a5,372(s1)
    8000213e:	2785                	addiw	a5,a5,1
    80002140:	16f4aa23          	sw	a5,372(s1)
      release(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b6a080e7          	jalr	-1174(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000214e:	18048493          	addi	s1,s1,384
    80002152:	05448463          	beq	s1,s4,8000219a <scheduler+0xf4>
      acquire(&p->lock);
    80002156:	8526                	mv	a0,s1
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	aa4080e7          	jalr	-1372(ra) # 80000bfc <acquire>
      switch (p->change)
    80002160:	1684a783          	lw	a5,360(s1)
    80002164:	fb278be3          	beq	a5,s2,8000211a <scheduler+0x74>
    80002168:	fd5781e3          	beq	a5,s5,8000212a <scheduler+0x84>
    8000216c:	f9378fe3          	beq	a5,s3,8000210a <scheduler+0x64>
      if (p->state != UNUSED)
    80002170:	4c9c                	lw	a5,24(s1)
    80002172:	dbe9                	beqz	a5,80002144 <scheduler+0x9e>
        if (p->priority == 2)
    80002174:	1784a783          	lw	a5,376(s1)
    80002178:	fd2781e3          	beq	a5,s2,8000213a <scheduler+0x94>
        else if (p->priority == 1)
    8000217c:	01378963          	beq	a5,s3,8000218e <scheduler+0xe8>
        else if (p->priority == 0)
    80002180:	f3f1                	bnez	a5,80002144 <scheduler+0x9e>
          (p->Qtime[0])++;
    80002182:	16c4a783          	lw	a5,364(s1)
    80002186:	2785                	addiw	a5,a5,1
    80002188:	16f4a623          	sw	a5,364(s1)
    8000218c:	bf65                	j	80002144 <scheduler+0x9e>
          (p->Qtime[1])++;
    8000218e:	1704a783          	lw	a5,368(s1)
    80002192:	2785                	addiw	a5,a5,1
    80002194:	16f4a823          	sw	a5,368(s1)
    80002198:	b775                	j	80002144 <scheduler+0x9e>
    int tail2 = findproc(0, 2) - 1;
    8000219a:	4589                	li	a1,2
    8000219c:	4501                	li	a0,0
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	76a080e7          	jalr	1898(ra) # 80001908 <findproc>
    for (int i = 0; i <= tail2; i++)
    800021a6:	06a05f63          	blez	a0,80002224 <scheduler+0x17e>
    800021aa:	00010917          	auipc	s2,0x10
    800021ae:	ba690913          	addi	s2,s2,-1114 # 80011d50 <Q+0x400>
    800021b2:	fff5099b          	addiw	s3,a0,-1
    800021b6:	02099793          	slli	a5,s3,0x20
    800021ba:	01d7d993          	srli	s3,a5,0x1d
    800021be:	00010797          	auipc	a5,0x10
    800021c2:	b9a78793          	addi	a5,a5,-1126 # 80011d58 <Q+0x408>
    800021c6:	99be                	add	s3,s3,a5
      if (p->state == RUNNABLE)
    800021c8:	4a09                	li	s4,2
        p->state = RUNNING;
    800021ca:	4a8d                	li	s5,3
    800021cc:	a809                	j	800021de <scheduler+0x138>
      release(&p->lock);
    800021ce:	8526                	mv	a0,s1
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	ae0080e7          	jalr	-1312(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    800021d8:	0921                	addi	s2,s2,8
    800021da:	05390563          	beq	s2,s3,80002224 <scheduler+0x17e>
      p = Q[2][i];
    800021de:	00093483          	ld	s1,0(s2)
      acquire(&p->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	a18080e7          	jalr	-1512(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    800021ec:	4c9c                	lw	a5,24(s1)
    800021ee:	ff4790e3          	bne	a5,s4,800021ce <scheduler+0x128>
        p->state = RUNNING;
    800021f2:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800021f6:	609b3c23          	sd	s1,1560(s6) # 1618 <_entry-0x7fffe9e8>
        swtch(&c->context, &p->context);
    800021fa:	06048593          	addi	a1,s1,96
    800021fe:	8566                	mv	a0,s9
    80002200:	00000097          	auipc	ra,0x0
    80002204:	6fc080e7          	jalr	1788(ra) # 800028fc <swtch>
        pid[tail] = p->pid;
    80002208:	000ba783          	lw	a5,0(s7)
    8000220c:	5c94                	lw	a3,56(s1)
    8000220e:	00279713          	slli	a4,a5,0x2
    80002212:	976a                	add	a4,a4,s10
    80002214:	a0d72c23          	sw	a3,-1512(a4)
        tail++;
    80002218:	2785                	addiw	a5,a5,1
    8000221a:	00fba023          	sw	a5,0(s7)
        c->proc = 0;
    8000221e:	600b3c23          	sd	zero,1560(s6)
    80002222:	b775                	j	800021ce <scheduler+0x128>
    p = Q[1][exec];
    80002224:	040c0793          	addi	a5,s8,64
    80002228:	078e                	slli	a5,a5,0x3
    8000222a:	97ee                	add	a5,a5,s11
    8000222c:	6384                	ld	s1,0(a5)
    if (p == 0)
    8000222e:	ec048ce3          	beqz	s1,80002106 <scheduler+0x60>
    acquire(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	9c8080e7          	jalr	-1592(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000223c:	4c98                	lw	a4,24(s1)
    8000223e:	4789                	li	a5,2
    80002240:	02f70a63          	beq	a4,a5,80002274 <scheduler+0x1ce>
    release(&p->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a6a080e7          	jalr	-1430(ra) # 80000cb0 <release>
    exec++;
    8000224e:	2c05                	addiw	s8,s8,1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002250:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002254:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002258:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000225c:	00010497          	auipc	s1,0x10
    80002260:	20c48493          	addi	s1,s1,524 # 80012468 <proc>
      switch (p->change)
    80002264:	4909                	li	s2,2
    80002266:	4a8d                	li	s5,3
    80002268:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++)
    8000226a:	00016a17          	auipc	s4,0x16
    8000226e:	1fea0a13          	addi	s4,s4,510 # 80018468 <tickslock>
    80002272:	b5d5                	j	80002156 <scheduler+0xb0>
      p->state = RUNNING;
    80002274:	478d                	li	a5,3
    80002276:	cc9c                	sw	a5,24(s1)
      c->proc = p;
    80002278:	609b3c23          	sd	s1,1560(s6)
      swtch(&c->context, &p->context);
    8000227c:	06048593          	addi	a1,s1,96
    80002280:	8566                	mv	a0,s9
    80002282:	00000097          	auipc	ra,0x0
    80002286:	67a080e7          	jalr	1658(ra) # 800028fc <swtch>
      pid[tail] = p->pid;
    8000228a:	000ba783          	lw	a5,0(s7)
    8000228e:	5c94                	lw	a3,56(s1)
    80002290:	00279713          	slli	a4,a5,0x2
    80002294:	976a                	add	a4,a4,s10
    80002296:	a0d72c23          	sw	a3,-1512(a4)
      tail++;
    8000229a:	2785                	addiw	a5,a5,1
    8000229c:	00fba023          	sw	a5,0(s7)
      c->proc = 0;
    800022a0:	600b3c23          	sd	zero,1560(s6)
    800022a4:	b745                	j	80002244 <scheduler+0x19e>

00000000800022a6 <sched>:
{
    800022a6:	7179                	addi	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	83a080e7          	jalr	-1990(ra) # 80001aee <myproc>
    800022bc:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	8c4080e7          	jalr	-1852(ra) # 80000b82 <holding>
    800022c6:	c93d                	beqz	a0,8000233c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c8:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022ca:	2781                	sext.w	a5,a5
    800022cc:	079e                	slli	a5,a5,0x7
    800022ce:	0000f717          	auipc	a4,0xf
    800022d2:	68270713          	addi	a4,a4,1666 # 80011950 <Q>
    800022d6:	97ba                	add	a5,a5,a4
    800022d8:	6907a703          	lw	a4,1680(a5)
    800022dc:	4785                	li	a5,1
    800022de:	06f71763          	bne	a4,a5,8000234c <sched+0xa6>
  if (p->state == RUNNING)
    800022e2:	4c98                	lw	a4,24(s1)
    800022e4:	478d                	li	a5,3
    800022e6:	06f70b63          	beq	a4,a5,8000235c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ee:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022f0:	efb5                	bnez	a5,8000236c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022f2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022f4:	0000f917          	auipc	s2,0xf
    800022f8:	65c90913          	addi	s2,s2,1628 # 80011950 <Q>
    800022fc:	2781                	sext.w	a5,a5
    800022fe:	079e                	slli	a5,a5,0x7
    80002300:	97ca                	add	a5,a5,s2
    80002302:	6947a983          	lw	s3,1684(a5)
    80002306:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002308:	2781                	sext.w	a5,a5
    8000230a:	079e                	slli	a5,a5,0x7
    8000230c:	00010597          	auipc	a1,0x10
    80002310:	c6458593          	addi	a1,a1,-924 # 80011f70 <cpus+0x8>
    80002314:	95be                	add	a1,a1,a5
    80002316:	06048513          	addi	a0,s1,96
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	5e2080e7          	jalr	1506(ra) # 800028fc <swtch>
    80002322:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002324:	2781                	sext.w	a5,a5
    80002326:	079e                	slli	a5,a5,0x7
    80002328:	97ca                	add	a5,a5,s2
    8000232a:	6937aa23          	sw	s3,1684(a5)
}
    8000232e:	70a2                	ld	ra,40(sp)
    80002330:	7402                	ld	s0,32(sp)
    80002332:	64e2                	ld	s1,24(sp)
    80002334:	6942                	ld	s2,16(sp)
    80002336:	69a2                	ld	s3,8(sp)
    80002338:	6145                	addi	sp,sp,48
    8000233a:	8082                	ret
    panic("sched p->lock");
    8000233c:	00006517          	auipc	a0,0x6
    80002340:	f1450513          	addi	a0,a0,-236 # 80008250 <digits+0x210>
    80002344:	ffffe097          	auipc	ra,0xffffe
    80002348:	1fc080e7          	jalr	508(ra) # 80000540 <panic>
    panic("sched locks");
    8000234c:	00006517          	auipc	a0,0x6
    80002350:	f1450513          	addi	a0,a0,-236 # 80008260 <digits+0x220>
    80002354:	ffffe097          	auipc	ra,0xffffe
    80002358:	1ec080e7          	jalr	492(ra) # 80000540 <panic>
    panic("sched running");
    8000235c:	00006517          	auipc	a0,0x6
    80002360:	f1450513          	addi	a0,a0,-236 # 80008270 <digits+0x230>
    80002364:	ffffe097          	auipc	ra,0xffffe
    80002368:	1dc080e7          	jalr	476(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000236c:	00006517          	auipc	a0,0x6
    80002370:	f1450513          	addi	a0,a0,-236 # 80008280 <digits+0x240>
    80002374:	ffffe097          	auipc	ra,0xffffe
    80002378:	1cc080e7          	jalr	460(ra) # 80000540 <panic>

000000008000237c <exit>:
{
    8000237c:	7179                	addi	sp,sp,-48
    8000237e:	f406                	sd	ra,40(sp)
    80002380:	f022                	sd	s0,32(sp)
    80002382:	ec26                	sd	s1,24(sp)
    80002384:	e84a                	sd	s2,16(sp)
    80002386:	e44e                	sd	s3,8(sp)
    80002388:	e052                	sd	s4,0(sp)
    8000238a:	1800                	addi	s0,sp,48
    8000238c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	760080e7          	jalr	1888(ra) # 80001aee <myproc>
    80002396:	89aa                	mv	s3,a0
  if (p == initproc)
    80002398:	00007797          	auipc	a5,0x7
    8000239c:	c807b783          	ld	a5,-896(a5) # 80009018 <initproc>
    800023a0:	0d050493          	addi	s1,a0,208
    800023a4:	15050913          	addi	s2,a0,336
    800023a8:	02a79363          	bne	a5,a0,800023ce <exit+0x52>
    panic("init exiting");
    800023ac:	00006517          	auipc	a0,0x6
    800023b0:	eec50513          	addi	a0,a0,-276 # 80008298 <digits+0x258>
    800023b4:	ffffe097          	auipc	ra,0xffffe
    800023b8:	18c080e7          	jalr	396(ra) # 80000540 <panic>
      fileclose(f);
    800023bc:	00002097          	auipc	ra,0x2
    800023c0:	45e080e7          	jalr	1118(ra) # 8000481a <fileclose>
      p->ofile[fd] = 0;
    800023c4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023c8:	04a1                	addi	s1,s1,8
    800023ca:	01248563          	beq	s1,s2,800023d4 <exit+0x58>
    if (p->ofile[fd])
    800023ce:	6088                	ld	a0,0(s1)
    800023d0:	f575                	bnez	a0,800023bc <exit+0x40>
    800023d2:	bfdd                	j	800023c8 <exit+0x4c>
  begin_op();
    800023d4:	00002097          	auipc	ra,0x2
    800023d8:	f74080e7          	jalr	-140(ra) # 80004348 <begin_op>
  iput(p->cwd);
    800023dc:	1509b503          	ld	a0,336(s3)
    800023e0:	00001097          	auipc	ra,0x1
    800023e4:	762080e7          	jalr	1890(ra) # 80003b42 <iput>
  end_op();
    800023e8:	00002097          	auipc	ra,0x2
    800023ec:	fe0080e7          	jalr	-32(ra) # 800043c8 <end_op>
  p->cwd = 0;
    800023f0:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023f4:	00007497          	auipc	s1,0x7
    800023f8:	c2448493          	addi	s1,s1,-988 # 80009018 <initproc>
    800023fc:	6088                	ld	a0,0(s1)
    800023fe:	ffffe097          	auipc	ra,0xffffe
    80002402:	7fe080e7          	jalr	2046(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    80002406:	6088                	ld	a0,0(s1)
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	470080e7          	jalr	1136(ra) # 80001878 <wakeup1>
  release(&initproc->lock);
    80002410:	6088                	ld	a0,0(s1)
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	89e080e7          	jalr	-1890(ra) # 80000cb0 <release>
  acquire(&p->lock);
    8000241a:	854e                	mv	a0,s3
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7e0080e7          	jalr	2016(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002424:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002428:	854e                	mv	a0,s3
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	886080e7          	jalr	-1914(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	7c8080e7          	jalr	1992(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    8000243c:	854e                	mv	a0,s3
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	7be080e7          	jalr	1982(ra) # 80000bfc <acquire>
  reparent(p);
    80002446:	854e                	mv	a0,s3
    80002448:	00000097          	auipc	ra,0x0
    8000244c:	bf8080e7          	jalr	-1032(ra) # 80002040 <reparent>
  wakeup1(original_parent);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	426080e7          	jalr	1062(ra) # 80001878 <wakeup1>
  p->xstate = status;
    8000245a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000245e:	4791                	li	a5,4
    80002460:	00f9ac23          	sw	a5,24(s3)
  p->change = 2;
    80002464:	4789                	li	a5,2
    80002466:	16f9a423          	sw	a5,360(s3)
  release(&original_parent->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	844080e7          	jalr	-1980(ra) # 80000cb0 <release>
  sched();
    80002474:	00000097          	auipc	ra,0x0
    80002478:	e32080e7          	jalr	-462(ra) # 800022a6 <sched>
  panic("zombie exit");
    8000247c:	00006517          	auipc	a0,0x6
    80002480:	e2c50513          	addi	a0,a0,-468 # 800082a8 <digits+0x268>
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	0bc080e7          	jalr	188(ra) # 80000540 <panic>

000000008000248c <yield>:
{
    8000248c:	1101                	addi	sp,sp,-32
    8000248e:	ec06                	sd	ra,24(sp)
    80002490:	e822                	sd	s0,16(sp)
    80002492:	e426                	sd	s1,8(sp)
    80002494:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	658080e7          	jalr	1624(ra) # 80001aee <myproc>
    8000249e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	75c080e7          	jalr	1884(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    800024a8:	4789                	li	a5,2
    800024aa:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    800024ac:	1784a703          	lw	a4,376(s1)
    800024b0:	02f70063          	beq	a4,a5,800024d0 <yield+0x44>
  sched();
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	df2080e7          	jalr	-526(ra) # 800022a6 <sched>
  release(&p->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7f2080e7          	jalr	2034(ra) # 80000cb0 <release>
}
    800024c6:	60e2                	ld	ra,24(sp)
    800024c8:	6442                	ld	s0,16(sp)
    800024ca:	64a2                	ld	s1,8(sp)
    800024cc:	6105                	addi	sp,sp,32
    800024ce:	8082                	ret
    for(int i=0; i<tail; i++)
    800024d0:	00007597          	auipc	a1,0x7
    800024d4:	b505a583          	lw	a1,-1200(a1) # 80009020 <tail>
    800024d8:	04b05563          	blez	a1,80002522 <yield+0x96>
    800024dc:	00010797          	auipc	a5,0x10
    800024e0:	e8c78793          	addi	a5,a5,-372 # 80012368 <pid>
    800024e4:	35fd                	addiw	a1,a1,-1
    800024e6:	02059713          	slli	a4,a1,0x20
    800024ea:	01e75593          	srli	a1,a4,0x1e
    800024ee:	00010717          	auipc	a4,0x10
    800024f2:	e7e70713          	addi	a4,a4,-386 # 8001236c <pid+0x4>
    800024f6:	95ba                	add	a1,a1,a4
  int down = 1;
    800024f8:	4505                	li	a0,1
        down = 0;
    800024fa:	4801                	li	a6,0
    800024fc:	a031                	j	80002508 <yield+0x7c>
      pid[i] = 0;
    800024fe:	00072023          	sw	zero,0(a4)
    for(int i=0; i<tail; i++)
    80002502:	0791                	addi	a5,a5,4
    80002504:	00b78963          	beq	a5,a1,80002516 <yield+0x8a>
      if(pid[i] != p->pid)
    80002508:	873e                	mv	a4,a5
    8000250a:	4390                	lw	a2,0(a5)
    8000250c:	5c94                	lw	a3,56(s1)
    8000250e:	fed608e3          	beq	a2,a3,800024fe <yield+0x72>
        down = 0;
    80002512:	8542                	mv	a0,a6
    80002514:	b7ed                	j	800024fe <yield+0x72>
    if(down)
    80002516:	e511                	bnez	a0,80002522 <yield+0x96>
    tail = 0;
    80002518:	00007797          	auipc	a5,0x7
    8000251c:	b007a423          	sw	zero,-1272(a5) # 80009020 <tail>
    80002520:	bf51                	j	800024b4 <yield+0x28>
      p->change = 1;
    80002522:	4785                	li	a5,1
    80002524:	16f4a423          	sw	a5,360(s1)
    80002528:	bfc5                	j	80002518 <yield+0x8c>

000000008000252a <sleep>:
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	89aa                	mv	s3,a0
    8000253a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	5b2080e7          	jalr	1458(ra) # 80001aee <myproc>
    80002544:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    80002546:	05250963          	beq	a0,s2,80002598 <sleep+0x6e>
    acquire(&p->lock); //DOC: sleeplock1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	6b2080e7          	jalr	1714(ra) # 80000bfc <acquire>
    release(lk);
    80002552:	854a                	mv	a0,s2
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	75c080e7          	jalr	1884(ra) # 80000cb0 <release>
  p->chan = chan;
    8000255c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002560:	4785                	li	a5,1
    80002562:	cc9c                	sw	a5,24(s1)
  p->change = 2;
    80002564:	4789                	li	a5,2
    80002566:	16f4a423          	sw	a5,360(s1)
  sched();
    8000256a:	00000097          	auipc	ra,0x0
    8000256e:	d3c080e7          	jalr	-708(ra) # 800022a6 <sched>
  p->chan = 0;
    80002572:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	738080e7          	jalr	1848(ra) # 80000cb0 <release>
    acquire(lk);
    80002580:	854a                	mv	a0,s2
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	67a080e7          	jalr	1658(ra) # 80000bfc <acquire>
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6145                	addi	sp,sp,48
    80002596:	8082                	ret
  p->chan = chan;
    80002598:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000259c:	4785                	li	a5,1
    8000259e:	cd1c                	sw	a5,24(a0)
  p->change = 2;
    800025a0:	4789                	li	a5,2
    800025a2:	16f52423          	sw	a5,360(a0)
  sched();
    800025a6:	00000097          	auipc	ra,0x0
    800025aa:	d00080e7          	jalr	-768(ra) # 800022a6 <sched>
  p->chan = 0;
    800025ae:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    800025b2:	bfe1                	j	8000258a <sleep+0x60>

00000000800025b4 <wait>:
{
    800025b4:	715d                	addi	sp,sp,-80
    800025b6:	e486                	sd	ra,72(sp)
    800025b8:	e0a2                	sd	s0,64(sp)
    800025ba:	fc26                	sd	s1,56(sp)
    800025bc:	f84a                	sd	s2,48(sp)
    800025be:	f44e                	sd	s3,40(sp)
    800025c0:	f052                	sd	s4,32(sp)
    800025c2:	ec56                	sd	s5,24(sp)
    800025c4:	e85a                	sd	s6,16(sp)
    800025c6:	e45e                	sd	s7,8(sp)
    800025c8:	0880                	addi	s0,sp,80
    800025ca:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	522080e7          	jalr	1314(ra) # 80001aee <myproc>
    800025d4:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	626080e7          	jalr	1574(ra) # 80000bfc <acquire>
    havekids = 0;
    800025de:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800025e0:	4a11                	li	s4,4
        havekids = 1;
    800025e2:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800025e4:	00016997          	auipc	s3,0x16
    800025e8:	e8498993          	addi	s3,s3,-380 # 80018468 <tickslock>
    havekids = 0;
    800025ec:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025ee:	00010497          	auipc	s1,0x10
    800025f2:	e7a48493          	addi	s1,s1,-390 # 80012468 <proc>
    800025f6:	a08d                	j	80002658 <wait+0xa4>
          pid = np->pid;
    800025f8:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025fc:	000b0e63          	beqz	s6,80002618 <wait+0x64>
    80002600:	4691                	li	a3,4
    80002602:	03448613          	addi	a2,s1,52
    80002606:	85da                	mv	a1,s6
    80002608:	05093503          	ld	a0,80(s2)
    8000260c:	fffff097          	auipc	ra,0xfffff
    80002610:	09e080e7          	jalr	158(ra) # 800016aa <copyout>
    80002614:	02054263          	bltz	a0,80002638 <wait+0x84>
          freeproc(np);
    80002618:	8526                	mv	a0,s1
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	688080e7          	jalr	1672(ra) # 80001ca2 <freeproc>
          release(&np->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	68c080e7          	jalr	1676(ra) # 80000cb0 <release>
          release(&p->lock);
    8000262c:	854a                	mv	a0,s2
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	682080e7          	jalr	1666(ra) # 80000cb0 <release>
          return pid;
    80002636:	a8a9                	j	80002690 <wait+0xdc>
            release(&np->lock);
    80002638:	8526                	mv	a0,s1
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	676080e7          	jalr	1654(ra) # 80000cb0 <release>
            release(&p->lock);
    80002642:	854a                	mv	a0,s2
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	66c080e7          	jalr	1644(ra) # 80000cb0 <release>
            return -1;
    8000264c:	59fd                	li	s3,-1
    8000264e:	a089                	j	80002690 <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    80002650:	18048493          	addi	s1,s1,384
    80002654:	03348463          	beq	s1,s3,8000267c <wait+0xc8>
      if (np->parent == p)
    80002658:	709c                	ld	a5,32(s1)
    8000265a:	ff279be3          	bne	a5,s2,80002650 <wait+0x9c>
        acquire(&np->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	59c080e7          	jalr	1436(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    80002668:	4c9c                	lw	a5,24(s1)
    8000266a:	f94787e3          	beq	a5,s4,800025f8 <wait+0x44>
        release(&np->lock);
    8000266e:	8526                	mv	a0,s1
    80002670:	ffffe097          	auipc	ra,0xffffe
    80002674:	640080e7          	jalr	1600(ra) # 80000cb0 <release>
        havekids = 1;
    80002678:	8756                	mv	a4,s5
    8000267a:	bfd9                	j	80002650 <wait+0x9c>
    if (!havekids || p->killed)
    8000267c:	c701                	beqz	a4,80002684 <wait+0xd0>
    8000267e:	03092783          	lw	a5,48(s2)
    80002682:	c39d                	beqz	a5,800026a8 <wait+0xf4>
      release(&p->lock);
    80002684:	854a                	mv	a0,s2
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	62a080e7          	jalr	1578(ra) # 80000cb0 <release>
      return -1;
    8000268e:	59fd                	li	s3,-1
}
    80002690:	854e                	mv	a0,s3
    80002692:	60a6                	ld	ra,72(sp)
    80002694:	6406                	ld	s0,64(sp)
    80002696:	74e2                	ld	s1,56(sp)
    80002698:	7942                	ld	s2,48(sp)
    8000269a:	79a2                	ld	s3,40(sp)
    8000269c:	7a02                	ld	s4,32(sp)
    8000269e:	6ae2                	ld	s5,24(sp)
    800026a0:	6b42                	ld	s6,16(sp)
    800026a2:	6ba2                	ld	s7,8(sp)
    800026a4:	6161                	addi	sp,sp,80
    800026a6:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    800026a8:	85ca                	mv	a1,s2
    800026aa:	854a                	mv	a0,s2
    800026ac:	00000097          	auipc	ra,0x0
    800026b0:	e7e080e7          	jalr	-386(ra) # 8000252a <sleep>
    havekids = 0;
    800026b4:	bf25                	j	800025ec <wait+0x38>

00000000800026b6 <wakeup>:
{
    800026b6:	7139                	addi	sp,sp,-64
    800026b8:	fc06                	sd	ra,56(sp)
    800026ba:	f822                	sd	s0,48(sp)
    800026bc:	f426                	sd	s1,40(sp)
    800026be:	f04a                	sd	s2,32(sp)
    800026c0:	ec4e                	sd	s3,24(sp)
    800026c2:	e852                	sd	s4,16(sp)
    800026c4:	e456                	sd	s5,8(sp)
    800026c6:	e05a                	sd	s6,0(sp)
    800026c8:	0080                	addi	s0,sp,64
    800026ca:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800026cc:	00010497          	auipc	s1,0x10
    800026d0:	d9c48493          	addi	s1,s1,-612 # 80012468 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800026d4:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026d6:	4b09                	li	s6,2
      p->change = 3;
    800026d8:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800026da:	00016917          	auipc	s2,0x16
    800026de:	d8e90913          	addi	s2,s2,-626 # 80018468 <tickslock>
    800026e2:	a811                	j	800026f6 <wakeup+0x40>
    release(&p->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5ca080e7          	jalr	1482(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ee:	18048493          	addi	s1,s1,384
    800026f2:	03248263          	beq	s1,s2,80002716 <wakeup+0x60>
    acquire(&p->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	504080e7          	jalr	1284(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    80002700:	4c9c                	lw	a5,24(s1)
    80002702:	ff3791e3          	bne	a5,s3,800026e4 <wakeup+0x2e>
    80002706:	749c                	ld	a5,40(s1)
    80002708:	fd479ee3          	bne	a5,s4,800026e4 <wakeup+0x2e>
      p->state = RUNNABLE;
    8000270c:	0164ac23          	sw	s6,24(s1)
      p->change = 3;
    80002710:	1754a423          	sw	s5,360(s1)
    80002714:	bfc1                	j	800026e4 <wakeup+0x2e>
}
    80002716:	70e2                	ld	ra,56(sp)
    80002718:	7442                	ld	s0,48(sp)
    8000271a:	74a2                	ld	s1,40(sp)
    8000271c:	7902                	ld	s2,32(sp)
    8000271e:	69e2                	ld	s3,24(sp)
    80002720:	6a42                	ld	s4,16(sp)
    80002722:	6aa2                	ld	s5,8(sp)
    80002724:	6b02                	ld	s6,0(sp)
    80002726:	6121                	addi	sp,sp,64
    80002728:	8082                	ret

000000008000272a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000272a:	7179                	addi	sp,sp,-48
    8000272c:	f406                	sd	ra,40(sp)
    8000272e:	f022                	sd	s0,32(sp)
    80002730:	ec26                	sd	s1,24(sp)
    80002732:	e84a                	sd	s2,16(sp)
    80002734:	e44e                	sd	s3,8(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000273a:	00010497          	auipc	s1,0x10
    8000273e:	d2e48493          	addi	s1,s1,-722 # 80012468 <proc>
    80002742:	00016997          	auipc	s3,0x16
    80002746:	d2698993          	addi	s3,s3,-730 # 80018468 <tickslock>
  {
    acquire(&p->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	4b0080e7          	jalr	1200(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    80002754:	5c9c                	lw	a5,56(s1)
    80002756:	01278d63          	beq	a5,s2,80002770 <kill+0x46>
        p->change = 3;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	554080e7          	jalr	1364(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002764:	18048493          	addi	s1,s1,384
    80002768:	ff3491e3          	bne	s1,s3,8000274a <kill+0x20>
  }
  return -1;
    8000276c:	557d                	li	a0,-1
    8000276e:	a821                	j	80002786 <kill+0x5c>
      p->killed = 1;
    80002770:	4785                	li	a5,1
    80002772:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    80002774:	4c98                	lw	a4,24(s1)
    80002776:	00f70f63          	beq	a4,a5,80002794 <kill+0x6a>
      release(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	534080e7          	jalr	1332(ra) # 80000cb0 <release>
      return 0;
    80002784:	4501                	li	a0,0
}
    80002786:	70a2                	ld	ra,40(sp)
    80002788:	7402                	ld	s0,32(sp)
    8000278a:	64e2                	ld	s1,24(sp)
    8000278c:	6942                	ld	s2,16(sp)
    8000278e:	69a2                	ld	s3,8(sp)
    80002790:	6145                	addi	sp,sp,48
    80002792:	8082                	ret
        p->state = RUNNABLE;
    80002794:	4789                	li	a5,2
    80002796:	cc9c                	sw	a5,24(s1)
        p->change = 3;
    80002798:	478d                	li	a5,3
    8000279a:	16f4a423          	sw	a5,360(s1)
    8000279e:	bff1                	j	8000277a <kill+0x50>

00000000800027a0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027a0:	7179                	addi	sp,sp,-48
    800027a2:	f406                	sd	ra,40(sp)
    800027a4:	f022                	sd	s0,32(sp)
    800027a6:	ec26                	sd	s1,24(sp)
    800027a8:	e84a                	sd	s2,16(sp)
    800027aa:	e44e                	sd	s3,8(sp)
    800027ac:	e052                	sd	s4,0(sp)
    800027ae:	1800                	addi	s0,sp,48
    800027b0:	84aa                	mv	s1,a0
    800027b2:	892e                	mv	s2,a1
    800027b4:	89b2                	mv	s3,a2
    800027b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	336080e7          	jalr	822(ra) # 80001aee <myproc>
  if (user_dst)
    800027c0:	c08d                	beqz	s1,800027e2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027c2:	86d2                	mv	a3,s4
    800027c4:	864e                	mv	a2,s3
    800027c6:	85ca                	mv	a1,s2
    800027c8:	6928                	ld	a0,80(a0)
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	ee0080e7          	jalr	-288(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d2:	70a2                	ld	ra,40(sp)
    800027d4:	7402                	ld	s0,32(sp)
    800027d6:	64e2                	ld	s1,24(sp)
    800027d8:	6942                	ld	s2,16(sp)
    800027da:	69a2                	ld	s3,8(sp)
    800027dc:	6a02                	ld	s4,0(sp)
    800027de:	6145                	addi	sp,sp,48
    800027e0:	8082                	ret
    memmove((char *)dst, src, len);
    800027e2:	000a061b          	sext.w	a2,s4
    800027e6:	85ce                	mv	a1,s3
    800027e8:	854a                	mv	a0,s2
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	56a080e7          	jalr	1386(ra) # 80000d54 <memmove>
    return 0;
    800027f2:	8526                	mv	a0,s1
    800027f4:	bff9                	j	800027d2 <either_copyout+0x32>

00000000800027f6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f6:	7179                	addi	sp,sp,-48
    800027f8:	f406                	sd	ra,40(sp)
    800027fa:	f022                	sd	s0,32(sp)
    800027fc:	ec26                	sd	s1,24(sp)
    800027fe:	e84a                	sd	s2,16(sp)
    80002800:	e44e                	sd	s3,8(sp)
    80002802:	e052                	sd	s4,0(sp)
    80002804:	1800                	addi	s0,sp,48
    80002806:	892a                	mv	s2,a0
    80002808:	84ae                	mv	s1,a1
    8000280a:	89b2                	mv	s3,a2
    8000280c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	2e0080e7          	jalr	736(ra) # 80001aee <myproc>
  if (user_src)
    80002816:	c08d                	beqz	s1,80002838 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002818:	86d2                	mv	a3,s4
    8000281a:	864e                	mv	a2,s3
    8000281c:	85ca                	mv	a1,s2
    8000281e:	6928                	ld	a0,80(a0)
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	f16080e7          	jalr	-234(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002828:	70a2                	ld	ra,40(sp)
    8000282a:	7402                	ld	s0,32(sp)
    8000282c:	64e2                	ld	s1,24(sp)
    8000282e:	6942                	ld	s2,16(sp)
    80002830:	69a2                	ld	s3,8(sp)
    80002832:	6a02                	ld	s4,0(sp)
    80002834:	6145                	addi	sp,sp,48
    80002836:	8082                	ret
    memmove(dst, (char *)src, len);
    80002838:	000a061b          	sext.w	a2,s4
    8000283c:	85ce                	mv	a1,s3
    8000283e:	854a                	mv	a0,s2
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	514080e7          	jalr	1300(ra) # 80000d54 <memmove>
    return 0;
    80002848:	8526                	mv	a0,s1
    8000284a:	bff9                	j	80002828 <either_copyin+0x32>

000000008000284c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000284c:	715d                	addi	sp,sp,-80
    8000284e:	e486                	sd	ra,72(sp)
    80002850:	e0a2                	sd	s0,64(sp)
    80002852:	fc26                	sd	s1,56(sp)
    80002854:	f84a                	sd	s2,48(sp)
    80002856:	f44e                	sd	s3,40(sp)
    80002858:	f052                	sd	s4,32(sp)
    8000285a:	ec56                	sd	s5,24(sp)
    8000285c:	e85a                	sd	s6,16(sp)
    8000285e:	e45e                	sd	s7,8(sp)
    80002860:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002862:	00006517          	auipc	a0,0x6
    80002866:	88650513          	addi	a0,a0,-1914 # 800080e8 <digits+0xa8>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	d20080e7          	jalr	-736(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002872:	00010497          	auipc	s1,0x10
    80002876:	d4e48493          	addi	s1,s1,-690 # 800125c0 <proc+0x158>
    8000287a:	00016917          	auipc	s2,0x16
    8000287e:	d4690913          	addi	s2,s2,-698 # 800185c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002882:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002884:	00006997          	auipc	s3,0x6
    80002888:	a3498993          	addi	s3,s3,-1484 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    8000288c:	00006a97          	auipc	s5,0x6
    80002890:	a34a8a93          	addi	s5,s5,-1484 # 800082c0 <digits+0x280>
    printf("\n");
    80002894:	00006a17          	auipc	s4,0x6
    80002898:	854a0a13          	addi	s4,s4,-1964 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289c:	00006b97          	auipc	s7,0x6
    800028a0:	a5cb8b93          	addi	s7,s7,-1444 # 800082f8 <states.0>
    800028a4:	a00d                	j	800028c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a6:	ee06a583          	lw	a1,-288(a3)
    800028aa:	8556                	mv	a0,s5
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	cde080e7          	jalr	-802(ra) # 8000058a <printf>
    printf("\n");
    800028b4:	8552                	mv	a0,s4
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	cd4080e7          	jalr	-812(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028be:	18048493          	addi	s1,s1,384
    800028c2:	03248263          	beq	s1,s2,800028e6 <procdump+0x9a>
    if (p->state == UNUSED)
    800028c6:	86a6                	mv	a3,s1
    800028c8:	ec04a783          	lw	a5,-320(s1)
    800028cc:	dbed                	beqz	a5,800028be <procdump+0x72>
      state = "???";
    800028ce:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028d0:	fcfb6be3          	bltu	s6,a5,800028a6 <procdump+0x5a>
    800028d4:	02079713          	slli	a4,a5,0x20
    800028d8:	01d75793          	srli	a5,a4,0x1d
    800028dc:	97de                	add	a5,a5,s7
    800028de:	6390                	ld	a2,0(a5)
    800028e0:	f279                	bnez	a2,800028a6 <procdump+0x5a>
      state = "???";
    800028e2:	864e                	mv	a2,s3
    800028e4:	b7c9                	j	800028a6 <procdump+0x5a>
  }
}
    800028e6:	60a6                	ld	ra,72(sp)
    800028e8:	6406                	ld	s0,64(sp)
    800028ea:	74e2                	ld	s1,56(sp)
    800028ec:	7942                	ld	s2,48(sp)
    800028ee:	79a2                	ld	s3,40(sp)
    800028f0:	7a02                	ld	s4,32(sp)
    800028f2:	6ae2                	ld	s5,24(sp)
    800028f4:	6b42                	ld	s6,16(sp)
    800028f6:	6ba2                	ld	s7,8(sp)
    800028f8:	6161                	addi	sp,sp,80
    800028fa:	8082                	ret

00000000800028fc <swtch>:
    800028fc:	00153023          	sd	ra,0(a0)
    80002900:	00253423          	sd	sp,8(a0)
    80002904:	e900                	sd	s0,16(a0)
    80002906:	ed04                	sd	s1,24(a0)
    80002908:	03253023          	sd	s2,32(a0)
    8000290c:	03353423          	sd	s3,40(a0)
    80002910:	03453823          	sd	s4,48(a0)
    80002914:	03553c23          	sd	s5,56(a0)
    80002918:	05653023          	sd	s6,64(a0)
    8000291c:	05753423          	sd	s7,72(a0)
    80002920:	05853823          	sd	s8,80(a0)
    80002924:	05953c23          	sd	s9,88(a0)
    80002928:	07a53023          	sd	s10,96(a0)
    8000292c:	07b53423          	sd	s11,104(a0)
    80002930:	0005b083          	ld	ra,0(a1)
    80002934:	0085b103          	ld	sp,8(a1)
    80002938:	6980                	ld	s0,16(a1)
    8000293a:	6d84                	ld	s1,24(a1)
    8000293c:	0205b903          	ld	s2,32(a1)
    80002940:	0285b983          	ld	s3,40(a1)
    80002944:	0305ba03          	ld	s4,48(a1)
    80002948:	0385ba83          	ld	s5,56(a1)
    8000294c:	0405bb03          	ld	s6,64(a1)
    80002950:	0485bb83          	ld	s7,72(a1)
    80002954:	0505bc03          	ld	s8,80(a1)
    80002958:	0585bc83          	ld	s9,88(a1)
    8000295c:	0605bd03          	ld	s10,96(a1)
    80002960:	0685bd83          	ld	s11,104(a1)
    80002964:	8082                	ret

0000000080002966 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002966:	1141                	addi	sp,sp,-16
    80002968:	e406                	sd	ra,8(sp)
    8000296a:	e022                	sd	s0,0(sp)
    8000296c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296e:	00006597          	auipc	a1,0x6
    80002972:	9b258593          	addi	a1,a1,-1614 # 80008320 <states.0+0x28>
    80002976:	00016517          	auipc	a0,0x16
    8000297a:	af250513          	addi	a0,a0,-1294 # 80018468 <tickslock>
    8000297e:	ffffe097          	auipc	ra,0xffffe
    80002982:	1ee080e7          	jalr	494(ra) # 80000b6c <initlock>
}
    80002986:	60a2                	ld	ra,8(sp)
    80002988:	6402                	ld	s0,0(sp)
    8000298a:	0141                	addi	sp,sp,16
    8000298c:	8082                	ret

000000008000298e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298e:	1141                	addi	sp,sp,-16
    80002990:	e422                	sd	s0,8(sp)
    80002992:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002994:	00003797          	auipc	a5,0x3
    80002998:	4dc78793          	addi	a5,a5,1244 # 80005e70 <kernelvec>
    8000299c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029a0:	6422                	ld	s0,8(sp)
    800029a2:	0141                	addi	sp,sp,16
    800029a4:	8082                	ret

00000000800029a6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a6:	1141                	addi	sp,sp,-16
    800029a8:	e406                	sd	ra,8(sp)
    800029aa:	e022                	sd	s0,0(sp)
    800029ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	140080e7          	jalr	320(ra) # 80001aee <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029c0:	00004617          	auipc	a2,0x4
    800029c4:	64060613          	addi	a2,a2,1600 # 80007000 <_trampoline>
    800029c8:	00004697          	auipc	a3,0x4
    800029cc:	63868693          	addi	a3,a3,1592 # 80007000 <_trampoline>
    800029d0:	8e91                	sub	a3,a3,a2
    800029d2:	040007b7          	lui	a5,0x4000
    800029d6:	17fd                	addi	a5,a5,-1
    800029d8:	07b2                	slli	a5,a5,0xc
    800029da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029dc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e2:	180026f3          	csrr	a3,satp
    800029e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e8:	6d38                	ld	a4,88(a0)
    800029ea:	6134                	ld	a3,64(a0)
    800029ec:	6585                	lui	a1,0x1
    800029ee:	96ae                	add	a3,a3,a1
    800029f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f2:	6d38                	ld	a4,88(a0)
    800029f4:	00000697          	auipc	a3,0x0
    800029f8:	13868693          	addi	a3,a3,312 # 80002b2c <usertrap>
    800029fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fe:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a00:	8692                	mv	a3,tp
    80002a02:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a08:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a10:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a14:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a16:	6f18                	ld	a4,24(a4)
    80002a18:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1c:	692c                	ld	a1,80(a0)
    80002a1e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a20:	00004717          	auipc	a4,0x4
    80002a24:	67070713          	addi	a4,a4,1648 # 80007090 <userret>
    80002a28:	8f11                	sub	a4,a4,a2
    80002a2a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a2c:	577d                	li	a4,-1
    80002a2e:	177e                	slli	a4,a4,0x3f
    80002a30:	8dd9                	or	a1,a1,a4
    80002a32:	02000537          	lui	a0,0x2000
    80002a36:	157d                	addi	a0,a0,-1
    80002a38:	0536                	slli	a0,a0,0xd
    80002a3a:	9782                	jalr	a5
}
    80002a3c:	60a2                	ld	ra,8(sp)
    80002a3e:	6402                	ld	s0,0(sp)
    80002a40:	0141                	addi	sp,sp,16
    80002a42:	8082                	ret

0000000080002a44 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a44:	1101                	addi	sp,sp,-32
    80002a46:	ec06                	sd	ra,24(sp)
    80002a48:	e822                	sd	s0,16(sp)
    80002a4a:	e426                	sd	s1,8(sp)
    80002a4c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4e:	00016497          	auipc	s1,0x16
    80002a52:	a1a48493          	addi	s1,s1,-1510 # 80018468 <tickslock>
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	1a4080e7          	jalr	420(ra) # 80000bfc <acquire>
  ticks++;
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	5c450513          	addi	a0,a0,1476 # 80009024 <ticks>
    80002a68:	411c                	lw	a5,0(a0)
    80002a6a:	2785                	addiw	a5,a5,1
    80002a6c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	c48080e7          	jalr	-952(ra) # 800026b6 <wakeup>
  release(&tickslock);
    80002a76:	8526                	mv	a0,s1
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	238080e7          	jalr	568(ra) # 80000cb0 <release>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6105                	addi	sp,sp,32
    80002a88:	8082                	ret

0000000080002a8a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a8a:	1101                	addi	sp,sp,-32
    80002a8c:	ec06                	sd	ra,24(sp)
    80002a8e:	e822                	sd	s0,16(sp)
    80002a90:	e426                	sd	s1,8(sp)
    80002a92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a98:	00074d63          	bltz	a4,80002ab2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a9c:	57fd                	li	a5,-1
    80002a9e:	17fe                	slli	a5,a5,0x3f
    80002aa0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa4:	06f70363          	beq	a4,a5,80002b0a <devintr+0x80>
  }
}
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6105                	addi	sp,sp,32
    80002ab0:	8082                	ret
     (scause & 0xff) == 9){
    80002ab2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab6:	46a5                	li	a3,9
    80002ab8:	fed792e3          	bne	a5,a3,80002a9c <devintr+0x12>
    int irq = plic_claim();
    80002abc:	00003097          	auipc	ra,0x3
    80002ac0:	4bc080e7          	jalr	1212(ra) # 80005f78 <plic_claim>
    80002ac4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac6:	47a9                	li	a5,10
    80002ac8:	02f50763          	beq	a0,a5,80002af6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002acc:	4785                	li	a5,1
    80002ace:	02f50963          	beq	a0,a5,80002b00 <devintr+0x76>
    return 1;
    80002ad2:	4505                	li	a0,1
    } else if(irq){
    80002ad4:	d8f1                	beqz	s1,80002aa8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad6:	85a6                	mv	a1,s1
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	85050513          	addi	a0,a0,-1968 # 80008328 <states.0+0x30>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	aaa080e7          	jalr	-1366(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	00003097          	auipc	ra,0x3
    80002aee:	4b2080e7          	jalr	1202(ra) # 80005f9c <plic_complete>
    return 1;
    80002af2:	4505                	li	a0,1
    80002af4:	bf55                	j	80002aa8 <devintr+0x1e>
      uartintr();
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	eca080e7          	jalr	-310(ra) # 800009c0 <uartintr>
    80002afe:	b7ed                	j	80002ae8 <devintr+0x5e>
      virtio_disk_intr();
    80002b00:	00004097          	auipc	ra,0x4
    80002b04:	916080e7          	jalr	-1770(ra) # 80006416 <virtio_disk_intr>
    80002b08:	b7c5                	j	80002ae8 <devintr+0x5e>
    if(cpuid() == 0){
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	fb8080e7          	jalr	-72(ra) # 80001ac2 <cpuid>
    80002b12:	c901                	beqz	a0,80002b22 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b14:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b1a:	14479073          	csrw	sip,a5
    return 2;
    80002b1e:	4509                	li	a0,2
    80002b20:	b761                	j	80002aa8 <devintr+0x1e>
      clockintr();
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	f22080e7          	jalr	-222(ra) # 80002a44 <clockintr>
    80002b2a:	b7ed                	j	80002b14 <devintr+0x8a>

0000000080002b2c <usertrap>:
{
    80002b2c:	1101                	addi	sp,sp,-32
    80002b2e:	ec06                	sd	ra,24(sp)
    80002b30:	e822                	sd	s0,16(sp)
    80002b32:	e426                	sd	s1,8(sp)
    80002b34:	e04a                	sd	s2,0(sp)
    80002b36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b38:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b3c:	1007f793          	andi	a5,a5,256
    80002b40:	e3ad                	bnez	a5,80002ba2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b42:	00003797          	auipc	a5,0x3
    80002b46:	32e78793          	addi	a5,a5,814 # 80005e70 <kernelvec>
    80002b4a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	fa0080e7          	jalr	-96(ra) # 80001aee <myproc>
    80002b56:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b58:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b5a:	14102773          	csrr	a4,sepc
    80002b5e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b60:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b64:	47a1                	li	a5,8
    80002b66:	04f71c63          	bne	a4,a5,80002bbe <usertrap+0x92>
    if(p->killed)
    80002b6a:	591c                	lw	a5,48(a0)
    80002b6c:	e3b9                	bnez	a5,80002bb2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b6e:	6cb8                	ld	a4,88(s1)
    80002b70:	6f1c                	ld	a5,24(a4)
    80002b72:	0791                	addi	a5,a5,4
    80002b74:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b76:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b7a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	2f8080e7          	jalr	760(ra) # 80002e7a <syscall>
  if(p->killed)
    80002b8a:	589c                	lw	a5,48(s1)
    80002b8c:	ebc1                	bnez	a5,80002c1c <usertrap+0xf0>
  usertrapret();
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	e18080e7          	jalr	-488(ra) # 800029a6 <usertrapret>
}
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6902                	ld	s2,0(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba2:	00005517          	auipc	a0,0x5
    80002ba6:	7a650513          	addi	a0,a0,1958 # 80008348 <states.0+0x50>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	996080e7          	jalr	-1642(ra) # 80000540 <panic>
      exit(-1);
    80002bb2:	557d                	li	a0,-1
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	7c8080e7          	jalr	1992(ra) # 8000237c <exit>
    80002bbc:	bf4d                	j	80002b6e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	ecc080e7          	jalr	-308(ra) # 80002a8a <devintr>
    80002bc6:	892a                	mv	s2,a0
    80002bc8:	c501                	beqz	a0,80002bd0 <usertrap+0xa4>
  if(p->killed)
    80002bca:	589c                	lw	a5,48(s1)
    80002bcc:	c3a1                	beqz	a5,80002c0c <usertrap+0xe0>
    80002bce:	a815                	j	80002c02 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd4:	5c90                	lw	a2,56(s1)
    80002bd6:	00005517          	auipc	a0,0x5
    80002bda:	79250513          	addi	a0,a0,1938 # 80008368 <states.0+0x70>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ac080e7          	jalr	-1620(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bee:	00005517          	auipc	a0,0x5
    80002bf2:	7aa50513          	addi	a0,a0,1962 # 80008398 <states.0+0xa0>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	994080e7          	jalr	-1644(ra) # 8000058a <printf>
    p->killed = 1;
    80002bfe:	4785                	li	a5,1
    80002c00:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c02:	557d                	li	a0,-1
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	778080e7          	jalr	1912(ra) # 8000237c <exit>
  if(which_dev == 2)
    80002c0c:	4789                	li	a5,2
    80002c0e:	f8f910e3          	bne	s2,a5,80002b8e <usertrap+0x62>
    yield();
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	87a080e7          	jalr	-1926(ra) # 8000248c <yield>
    80002c1a:	bf95                	j	80002b8e <usertrap+0x62>
  int which_dev = 0;
    80002c1c:	4901                	li	s2,0
    80002c1e:	b7d5                	j	80002c02 <usertrap+0xd6>

0000000080002c20 <kerneltrap>:
{
    80002c20:	7179                	addi	sp,sp,-48
    80002c22:	f406                	sd	ra,40(sp)
    80002c24:	f022                	sd	s0,32(sp)
    80002c26:	ec26                	sd	s1,24(sp)
    80002c28:	e84a                	sd	s2,16(sp)
    80002c2a:	e44e                	sd	s3,8(sp)
    80002c2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c36:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c3a:	1004f793          	andi	a5,s1,256
    80002c3e:	cb85                	beqz	a5,80002c6e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c44:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c46:	ef85                	bnez	a5,80002c7e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	e42080e7          	jalr	-446(ra) # 80002a8a <devintr>
    80002c50:	cd1d                	beqz	a0,80002c8e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c52:	4789                	li	a5,2
    80002c54:	08f50663          	beq	a0,a5,80002ce0 <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5c:	10049073          	csrw	sstatus,s1
}
    80002c60:	70a2                	ld	ra,40(sp)
    80002c62:	7402                	ld	s0,32(sp)
    80002c64:	64e2                	ld	s1,24(sp)
    80002c66:	6942                	ld	s2,16(sp)
    80002c68:	69a2                	ld	s3,8(sp)
    80002c6a:	6145                	addi	sp,sp,48
    80002c6c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	74a50513          	addi	a0,a0,1866 # 800083b8 <states.0+0xc0>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	8ca080e7          	jalr	-1846(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7e:	00005517          	auipc	a0,0x5
    80002c82:	76250513          	addi	a0,a0,1890 # 800083e0 <states.0+0xe8>
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	8ba080e7          	jalr	-1862(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c8e:	00006597          	auipc	a1,0x6
    80002c92:	3965a583          	lw	a1,918(a1) # 80009024 <ticks>
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	7c250513          	addi	a0,a0,1986 # 80008458 <states.0+0x160>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8ec080e7          	jalr	-1812(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002ca6:	85ce                	mv	a1,s3
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	75850513          	addi	a0,a0,1880 # 80008400 <states.0+0x108>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8da080e7          	jalr	-1830(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cbc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cc0:	00005517          	auipc	a0,0x5
    80002cc4:	75050513          	addi	a0,a0,1872 # 80008410 <states.0+0x118>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8c2080e7          	jalr	-1854(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cd0:	00005517          	auipc	a0,0x5
    80002cd4:	75850513          	addi	a0,a0,1880 # 80008428 <states.0+0x130>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	868080e7          	jalr	-1944(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	e0e080e7          	jalr	-498(ra) # 80001aee <myproc>
    80002ce8:	d925                	beqz	a0,80002c58 <kerneltrap+0x38>
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	e04080e7          	jalr	-508(ra) # 80001aee <myproc>
    80002cf2:	4d18                	lw	a4,24(a0)
    80002cf4:	478d                	li	a5,3
    80002cf6:	f6f711e3          	bne	a4,a5,80002c58 <kerneltrap+0x38>
    yield();
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	792080e7          	jalr	1938(ra) # 8000248c <yield>
    80002d02:	bf99                	j	80002c58 <kerneltrap+0x38>

0000000080002d04 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d04:	1101                	addi	sp,sp,-32
    80002d06:	ec06                	sd	ra,24(sp)
    80002d08:	e822                	sd	s0,16(sp)
    80002d0a:	e426                	sd	s1,8(sp)
    80002d0c:	1000                	addi	s0,sp,32
    80002d0e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d10:	fffff097          	auipc	ra,0xfffff
    80002d14:	dde080e7          	jalr	-546(ra) # 80001aee <myproc>
  switch (n)
    80002d18:	4795                	li	a5,5
    80002d1a:	0497e163          	bltu	a5,s1,80002d5c <argraw+0x58>
    80002d1e:	048a                	slli	s1,s1,0x2
    80002d20:	00005717          	auipc	a4,0x5
    80002d24:	74070713          	addi	a4,a4,1856 # 80008460 <states.0+0x168>
    80002d28:	94ba                	add	s1,s1,a4
    80002d2a:	409c                	lw	a5,0(s1)
    80002d2c:	97ba                	add	a5,a5,a4
    80002d2e:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d30:	6d3c                	ld	a5,88(a0)
    80002d32:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret
    return p->trapframe->a1;
    80002d3e:	6d3c                	ld	a5,88(a0)
    80002d40:	7fa8                	ld	a0,120(a5)
    80002d42:	bfcd                	j	80002d34 <argraw+0x30>
    return p->trapframe->a2;
    80002d44:	6d3c                	ld	a5,88(a0)
    80002d46:	63c8                	ld	a0,128(a5)
    80002d48:	b7f5                	j	80002d34 <argraw+0x30>
    return p->trapframe->a3;
    80002d4a:	6d3c                	ld	a5,88(a0)
    80002d4c:	67c8                	ld	a0,136(a5)
    80002d4e:	b7dd                	j	80002d34 <argraw+0x30>
    return p->trapframe->a4;
    80002d50:	6d3c                	ld	a5,88(a0)
    80002d52:	6bc8                	ld	a0,144(a5)
    80002d54:	b7c5                	j	80002d34 <argraw+0x30>
    return p->trapframe->a5;
    80002d56:	6d3c                	ld	a5,88(a0)
    80002d58:	6fc8                	ld	a0,152(a5)
    80002d5a:	bfe9                	j	80002d34 <argraw+0x30>
  panic("argraw");
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	6dc50513          	addi	a0,a0,1756 # 80008438 <states.0+0x140>
    80002d64:	ffffd097          	auipc	ra,0xffffd
    80002d68:	7dc080e7          	jalr	2012(ra) # 80000540 <panic>

0000000080002d6c <fetchaddr>:
{
    80002d6c:	1101                	addi	sp,sp,-32
    80002d6e:	ec06                	sd	ra,24(sp)
    80002d70:	e822                	sd	s0,16(sp)
    80002d72:	e426                	sd	s1,8(sp)
    80002d74:	e04a                	sd	s2,0(sp)
    80002d76:	1000                	addi	s0,sp,32
    80002d78:	84aa                	mv	s1,a0
    80002d7a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	d72080e7          	jalr	-654(ra) # 80001aee <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d84:	653c                	ld	a5,72(a0)
    80002d86:	02f4f863          	bgeu	s1,a5,80002db6 <fetchaddr+0x4a>
    80002d8a:	00848713          	addi	a4,s1,8
    80002d8e:	02e7e663          	bltu	a5,a4,80002dba <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d92:	46a1                	li	a3,8
    80002d94:	8626                	mv	a2,s1
    80002d96:	85ca                	mv	a1,s2
    80002d98:	6928                	ld	a0,80(a0)
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	99c080e7          	jalr	-1636(ra) # 80001736 <copyin>
    80002da2:	00a03533          	snez	a0,a0
    80002da6:	40a00533          	neg	a0,a0
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	64a2                	ld	s1,8(sp)
    80002db0:	6902                	ld	s2,0(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret
    return -1;
    80002db6:	557d                	li	a0,-1
    80002db8:	bfcd                	j	80002daa <fetchaddr+0x3e>
    80002dba:	557d                	li	a0,-1
    80002dbc:	b7fd                	j	80002daa <fetchaddr+0x3e>

0000000080002dbe <fetchstr>:
{
    80002dbe:	7179                	addi	sp,sp,-48
    80002dc0:	f406                	sd	ra,40(sp)
    80002dc2:	f022                	sd	s0,32(sp)
    80002dc4:	ec26                	sd	s1,24(sp)
    80002dc6:	e84a                	sd	s2,16(sp)
    80002dc8:	e44e                	sd	s3,8(sp)
    80002dca:	1800                	addi	s0,sp,48
    80002dcc:	892a                	mv	s2,a0
    80002dce:	84ae                	mv	s1,a1
    80002dd0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	d1c080e7          	jalr	-740(ra) # 80001aee <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dda:	86ce                	mv	a3,s3
    80002ddc:	864a                	mv	a2,s2
    80002dde:	85a6                	mv	a1,s1
    80002de0:	6928                	ld	a0,80(a0)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	9e2080e7          	jalr	-1566(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002dea:	00054763          	bltz	a0,80002df8 <fetchstr+0x3a>
  return strlen(buf);
    80002dee:	8526                	mv	a0,s1
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	08c080e7          	jalr	140(ra) # 80000e7c <strlen>
}
    80002df8:	70a2                	ld	ra,40(sp)
    80002dfa:	7402                	ld	s0,32(sp)
    80002dfc:	64e2                	ld	s1,24(sp)
    80002dfe:	6942                	ld	s2,16(sp)
    80002e00:	69a2                	ld	s3,8(sp)
    80002e02:	6145                	addi	sp,sp,48
    80002e04:	8082                	ret

0000000080002e06 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e12:	00000097          	auipc	ra,0x0
    80002e16:	ef2080e7          	jalr	-270(ra) # 80002d04 <argraw>
    80002e1a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e1c:	4501                	li	a0,0
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	64a2                	ld	s1,8(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	ed0080e7          	jalr	-304(ra) # 80002d04 <argraw>
    80002e3c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e3e:	4501                	li	a0,0
    80002e40:	60e2                	ld	ra,24(sp)
    80002e42:	6442                	ld	s0,16(sp)
    80002e44:	64a2                	ld	s1,8(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	e426                	sd	s1,8(sp)
    80002e52:	e04a                	sd	s2,0(sp)
    80002e54:	1000                	addi	s0,sp,32
    80002e56:	84ae                	mv	s1,a1
    80002e58:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	eaa080e7          	jalr	-342(ra) # 80002d04 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e62:	864a                	mv	a2,s2
    80002e64:	85a6                	mv	a1,s1
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	f58080e7          	jalr	-168(ra) # 80002dbe <fetchstr>
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6902                	ld	s2,0(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	c68080e7          	jalr	-920(ra) # 80001aee <myproc>
    80002e8e:	84aa                	mv	s1,a0

  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process
  if(p->priority != 2)
    80002e90:	17852703          	lw	a4,376(a0)
    80002e94:	4789                	li	a5,2
    80002e96:	00f70563          	beq	a4,a5,80002ea0 <syscall+0x26>
    p->change = 3;
    80002e9a:	478d                	li	a5,3
    80002e9c:	16f52423          	sw	a5,360(a0)

  num = p->trapframe->a7;
    80002ea0:	0584b903          	ld	s2,88(s1)
    80002ea4:	0a893783          	ld	a5,168(s2)
    80002ea8:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002eac:	37fd                	addiw	a5,a5,-1
    80002eae:	4751                	li	a4,20
    80002eb0:	00f76f63          	bltu	a4,a5,80002ece <syscall+0x54>
    80002eb4:	00369713          	slli	a4,a3,0x3
    80002eb8:	00005797          	auipc	a5,0x5
    80002ebc:	5c078793          	addi	a5,a5,1472 # 80008478 <syscalls>
    80002ec0:	97ba                	add	a5,a5,a4
    80002ec2:	639c                	ld	a5,0(a5)
    80002ec4:	c789                	beqz	a5,80002ece <syscall+0x54>
  {
    p->trapframe->a0 = syscalls[num]();
    80002ec6:	9782                	jalr	a5
    80002ec8:	06a93823          	sd	a0,112(s2)
    80002ecc:	a839                	j	80002eea <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002ece:	15848613          	addi	a2,s1,344
    80002ed2:	5c8c                	lw	a1,56(s1)
    80002ed4:	00005517          	auipc	a0,0x5
    80002ed8:	56c50513          	addi	a0,a0,1388 # 80008440 <states.0+0x148>
    80002edc:	ffffd097          	auipc	ra,0xffffd
    80002ee0:	6ae080e7          	jalr	1710(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee4:	6cbc                	ld	a5,88(s1)
    80002ee6:	577d                	li	a4,-1
    80002ee8:	fbb8                	sd	a4,112(a5)
  }
}
    80002eea:	60e2                	ld	ra,24(sp)
    80002eec:	6442                	ld	s0,16(sp)
    80002eee:	64a2                	ld	s1,8(sp)
    80002ef0:	6902                	ld	s2,0(sp)
    80002ef2:	6105                	addi	sp,sp,32
    80002ef4:	8082                	ret

0000000080002ef6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ef6:	1101                	addi	sp,sp,-32
    80002ef8:	ec06                	sd	ra,24(sp)
    80002efa:	e822                	sd	s0,16(sp)
    80002efc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002efe:	fec40593          	addi	a1,s0,-20
    80002f02:	4501                	li	a0,0
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	f02080e7          	jalr	-254(ra) # 80002e06 <argint>
    return -1;
    80002f0c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f0e:	00054963          	bltz	a0,80002f20 <sys_exit+0x2a>
  exit(n);
    80002f12:	fec42503          	lw	a0,-20(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	466080e7          	jalr	1126(ra) # 8000237c <exit>
  return 0;  // not reached
    80002f1e:	4781                	li	a5,0
}
    80002f20:	853e                	mv	a0,a5
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	6105                	addi	sp,sp,32
    80002f28:	8082                	ret

0000000080002f2a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f2a:	1141                	addi	sp,sp,-16
    80002f2c:	e406                	sd	ra,8(sp)
    80002f2e:	e022                	sd	s0,0(sp)
    80002f30:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f32:	fffff097          	auipc	ra,0xfffff
    80002f36:	bbc080e7          	jalr	-1092(ra) # 80001aee <myproc>
}
    80002f3a:	5d08                	lw	a0,56(a0)
    80002f3c:	60a2                	ld	ra,8(sp)
    80002f3e:	6402                	ld	s0,0(sp)
    80002f40:	0141                	addi	sp,sp,16
    80002f42:	8082                	ret

0000000080002f44 <sys_fork>:

uint64
sys_fork(void)
{
    80002f44:	1141                	addi	sp,sp,-16
    80002f46:	e406                	sd	ra,8(sp)
    80002f48:	e022                	sd	s0,0(sp)
    80002f4a:	0800                	addi	s0,sp,16
  return fork();
    80002f4c:	fffff097          	auipc	ra,0xfffff
    80002f50:	fca080e7          	jalr	-54(ra) # 80001f16 <fork>
}
    80002f54:	60a2                	ld	ra,8(sp)
    80002f56:	6402                	ld	s0,0(sp)
    80002f58:	0141                	addi	sp,sp,16
    80002f5a:	8082                	ret

0000000080002f5c <sys_wait>:

uint64
sys_wait(void)
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f64:	fe840593          	addi	a1,s0,-24
    80002f68:	4501                	li	a0,0
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	ebe080e7          	jalr	-322(ra) # 80002e28 <argaddr>
    80002f72:	87aa                	mv	a5,a0
    return -1;
    80002f74:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f76:	0007c863          	bltz	a5,80002f86 <sys_wait+0x2a>
  return wait(p);
    80002f7a:	fe843503          	ld	a0,-24(s0)
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	636080e7          	jalr	1590(ra) # 800025b4 <wait>
}
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret

0000000080002f8e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f98:	fdc40593          	addi	a1,s0,-36
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	e68080e7          	jalr	-408(ra) # 80002e06 <argint>
    return -1;
    80002fa6:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fa8:	00054f63          	bltz	a0,80002fc6 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	b42080e7          	jalr	-1214(ra) # 80001aee <myproc>
    80002fb4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fb6:	fdc42503          	lw	a0,-36(s0)
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	ee8080e7          	jalr	-280(ra) # 80001ea2 <growproc>
    80002fc2:	00054863          	bltz	a0,80002fd2 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	70a2                	ld	ra,40(sp)
    80002fca:	7402                	ld	s0,32(sp)
    80002fcc:	64e2                	ld	s1,24(sp)
    80002fce:	6145                	addi	sp,sp,48
    80002fd0:	8082                	ret
    return -1;
    80002fd2:	54fd                	li	s1,-1
    80002fd4:	bfcd                	j	80002fc6 <sys_sbrk+0x38>

0000000080002fd6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fd6:	7139                	addi	sp,sp,-64
    80002fd8:	fc06                	sd	ra,56(sp)
    80002fda:	f822                	sd	s0,48(sp)
    80002fdc:	f426                	sd	s1,40(sp)
    80002fde:	f04a                	sd	s2,32(sp)
    80002fe0:	ec4e                	sd	s3,24(sp)
    80002fe2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe4:	fcc40593          	addi	a1,s0,-52
    80002fe8:	4501                	li	a0,0
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	e1c080e7          	jalr	-484(ra) # 80002e06 <argint>
    return -1;
    80002ff2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff4:	06054563          	bltz	a0,8000305e <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff8:	00015517          	auipc	a0,0x15
    80002ffc:	47050513          	addi	a0,a0,1136 # 80018468 <tickslock>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	bfc080e7          	jalr	-1028(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80003008:	00006917          	auipc	s2,0x6
    8000300c:	01c92903          	lw	s2,28(s2) # 80009024 <ticks>
  while(ticks - ticks0 < n){
    80003010:	fcc42783          	lw	a5,-52(s0)
    80003014:	cf85                	beqz	a5,8000304c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003016:	00015997          	auipc	s3,0x15
    8000301a:	45298993          	addi	s3,s3,1106 # 80018468 <tickslock>
    8000301e:	00006497          	auipc	s1,0x6
    80003022:	00648493          	addi	s1,s1,6 # 80009024 <ticks>
    if(myproc()->killed){
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	ac8080e7          	jalr	-1336(ra) # 80001aee <myproc>
    8000302e:	591c                	lw	a5,48(a0)
    80003030:	ef9d                	bnez	a5,8000306e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003032:	85ce                	mv	a1,s3
    80003034:	8526                	mv	a0,s1
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	4f4080e7          	jalr	1268(ra) # 8000252a <sleep>
  while(ticks - ticks0 < n){
    8000303e:	409c                	lw	a5,0(s1)
    80003040:	412787bb          	subw	a5,a5,s2
    80003044:	fcc42703          	lw	a4,-52(s0)
    80003048:	fce7efe3          	bltu	a5,a4,80003026 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000304c:	00015517          	auipc	a0,0x15
    80003050:	41c50513          	addi	a0,a0,1052 # 80018468 <tickslock>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	c5c080e7          	jalr	-932(ra) # 80000cb0 <release>
  return 0;
    8000305c:	4781                	li	a5,0
}
    8000305e:	853e                	mv	a0,a5
    80003060:	70e2                	ld	ra,56(sp)
    80003062:	7442                	ld	s0,48(sp)
    80003064:	74a2                	ld	s1,40(sp)
    80003066:	7902                	ld	s2,32(sp)
    80003068:	69e2                	ld	s3,24(sp)
    8000306a:	6121                	addi	sp,sp,64
    8000306c:	8082                	ret
      release(&tickslock);
    8000306e:	00015517          	auipc	a0,0x15
    80003072:	3fa50513          	addi	a0,a0,1018 # 80018468 <tickslock>
    80003076:	ffffe097          	auipc	ra,0xffffe
    8000307a:	c3a080e7          	jalr	-966(ra) # 80000cb0 <release>
      return -1;
    8000307e:	57fd                	li	a5,-1
    80003080:	bff9                	j	8000305e <sys_sleep+0x88>

0000000080003082 <sys_kill>:

uint64
sys_kill(void)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000308a:	fec40593          	addi	a1,s0,-20
    8000308e:	4501                	li	a0,0
    80003090:	00000097          	auipc	ra,0x0
    80003094:	d76080e7          	jalr	-650(ra) # 80002e06 <argint>
    80003098:	87aa                	mv	a5,a0
    return -1;
    8000309a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000309c:	0007c863          	bltz	a5,800030ac <sys_kill+0x2a>
  return kill(pid);
    800030a0:	fec42503          	lw	a0,-20(s0)
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	686080e7          	jalr	1670(ra) # 8000272a <kill>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret

00000000800030b4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	e426                	sd	s1,8(sp)
    800030bc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030be:	00015517          	auipc	a0,0x15
    800030c2:	3aa50513          	addi	a0,a0,938 # 80018468 <tickslock>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	b36080e7          	jalr	-1226(ra) # 80000bfc <acquire>
  xticks = ticks;
    800030ce:	00006497          	auipc	s1,0x6
    800030d2:	f564a483          	lw	s1,-170(s1) # 80009024 <ticks>
  release(&tickslock);
    800030d6:	00015517          	auipc	a0,0x15
    800030da:	39250513          	addi	a0,a0,914 # 80018468 <tickslock>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	bd2080e7          	jalr	-1070(ra) # 80000cb0 <release>
  return xticks;
}
    800030e6:	02049513          	slli	a0,s1,0x20
    800030ea:	9101                	srli	a0,a0,0x20
    800030ec:	60e2                	ld	ra,24(sp)
    800030ee:	6442                	ld	s0,16(sp)
    800030f0:	64a2                	ld	s1,8(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030f6:	7179                	addi	sp,sp,-48
    800030f8:	f406                	sd	ra,40(sp)
    800030fa:	f022                	sd	s0,32(sp)
    800030fc:	ec26                	sd	s1,24(sp)
    800030fe:	e84a                	sd	s2,16(sp)
    80003100:	e44e                	sd	s3,8(sp)
    80003102:	e052                	sd	s4,0(sp)
    80003104:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003106:	00005597          	auipc	a1,0x5
    8000310a:	42258593          	addi	a1,a1,1058 # 80008528 <syscalls+0xb0>
    8000310e:	00015517          	auipc	a0,0x15
    80003112:	37250513          	addi	a0,a0,882 # 80018480 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	a56080e7          	jalr	-1450(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000311e:	0001d797          	auipc	a5,0x1d
    80003122:	36278793          	addi	a5,a5,866 # 80020480 <bcache+0x8000>
    80003126:	0001d717          	auipc	a4,0x1d
    8000312a:	5c270713          	addi	a4,a4,1474 # 800206e8 <bcache+0x8268>
    8000312e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003132:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003136:	00015497          	auipc	s1,0x15
    8000313a:	36248493          	addi	s1,s1,866 # 80018498 <bcache+0x18>
    b->next = bcache.head.next;
    8000313e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003140:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003142:	00005a17          	auipc	s4,0x5
    80003146:	3eea0a13          	addi	s4,s4,1006 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000314a:	2b893783          	ld	a5,696(s2)
    8000314e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003150:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003154:	85d2                	mv	a1,s4
    80003156:	01048513          	addi	a0,s1,16
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	4b2080e7          	jalr	1202(ra) # 8000460c <initsleeplock>
    bcache.head.next->prev = b;
    80003162:	2b893783          	ld	a5,696(s2)
    80003166:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003168:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000316c:	45848493          	addi	s1,s1,1112
    80003170:	fd349de3          	bne	s1,s3,8000314a <binit+0x54>
  }
}
    80003174:	70a2                	ld	ra,40(sp)
    80003176:	7402                	ld	s0,32(sp)
    80003178:	64e2                	ld	s1,24(sp)
    8000317a:	6942                	ld	s2,16(sp)
    8000317c:	69a2                	ld	s3,8(sp)
    8000317e:	6a02                	ld	s4,0(sp)
    80003180:	6145                	addi	sp,sp,48
    80003182:	8082                	ret

0000000080003184 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003184:	7179                	addi	sp,sp,-48
    80003186:	f406                	sd	ra,40(sp)
    80003188:	f022                	sd	s0,32(sp)
    8000318a:	ec26                	sd	s1,24(sp)
    8000318c:	e84a                	sd	s2,16(sp)
    8000318e:	e44e                	sd	s3,8(sp)
    80003190:	1800                	addi	s0,sp,48
    80003192:	892a                	mv	s2,a0
    80003194:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003196:	00015517          	auipc	a0,0x15
    8000319a:	2ea50513          	addi	a0,a0,746 # 80018480 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a5e080e7          	jalr	-1442(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031a6:	0001d497          	auipc	s1,0x1d
    800031aa:	5924b483          	ld	s1,1426(s1) # 80020738 <bcache+0x82b8>
    800031ae:	0001d797          	auipc	a5,0x1d
    800031b2:	53a78793          	addi	a5,a5,1338 # 800206e8 <bcache+0x8268>
    800031b6:	02f48f63          	beq	s1,a5,800031f4 <bread+0x70>
    800031ba:	873e                	mv	a4,a5
    800031bc:	a021                	j	800031c4 <bread+0x40>
    800031be:	68a4                	ld	s1,80(s1)
    800031c0:	02e48a63          	beq	s1,a4,800031f4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031c4:	449c                	lw	a5,8(s1)
    800031c6:	ff279ce3          	bne	a5,s2,800031be <bread+0x3a>
    800031ca:	44dc                	lw	a5,12(s1)
    800031cc:	ff3799e3          	bne	a5,s3,800031be <bread+0x3a>
      b->refcnt++;
    800031d0:	40bc                	lw	a5,64(s1)
    800031d2:	2785                	addiw	a5,a5,1
    800031d4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d6:	00015517          	auipc	a0,0x15
    800031da:	2aa50513          	addi	a0,a0,682 # 80018480 <bcache>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	ad2080e7          	jalr	-1326(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031e6:	01048513          	addi	a0,s1,16
    800031ea:	00001097          	auipc	ra,0x1
    800031ee:	45c080e7          	jalr	1116(ra) # 80004646 <acquiresleep>
      return b;
    800031f2:	a8b9                	j	80003250 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f4:	0001d497          	auipc	s1,0x1d
    800031f8:	53c4b483          	ld	s1,1340(s1) # 80020730 <bcache+0x82b0>
    800031fc:	0001d797          	auipc	a5,0x1d
    80003200:	4ec78793          	addi	a5,a5,1260 # 800206e8 <bcache+0x8268>
    80003204:	00f48863          	beq	s1,a5,80003214 <bread+0x90>
    80003208:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000320a:	40bc                	lw	a5,64(s1)
    8000320c:	cf81                	beqz	a5,80003224 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000320e:	64a4                	ld	s1,72(s1)
    80003210:	fee49de3          	bne	s1,a4,8000320a <bread+0x86>
  panic("bget: no buffers");
    80003214:	00005517          	auipc	a0,0x5
    80003218:	32450513          	addi	a0,a0,804 # 80008538 <syscalls+0xc0>
    8000321c:	ffffd097          	auipc	ra,0xffffd
    80003220:	324080e7          	jalr	804(ra) # 80000540 <panic>
      b->dev = dev;
    80003224:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003228:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000322c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003230:	4785                	li	a5,1
    80003232:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003234:	00015517          	auipc	a0,0x15
    80003238:	24c50513          	addi	a0,a0,588 # 80018480 <bcache>
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	a74080e7          	jalr	-1420(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003244:	01048513          	addi	a0,s1,16
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	3fe080e7          	jalr	1022(ra) # 80004646 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003250:	409c                	lw	a5,0(s1)
    80003252:	cb89                	beqz	a5,80003264 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003254:	8526                	mv	a0,s1
    80003256:	70a2                	ld	ra,40(sp)
    80003258:	7402                	ld	s0,32(sp)
    8000325a:	64e2                	ld	s1,24(sp)
    8000325c:	6942                	ld	s2,16(sp)
    8000325e:	69a2                	ld	s3,8(sp)
    80003260:	6145                	addi	sp,sp,48
    80003262:	8082                	ret
    virtio_disk_rw(b, 0);
    80003264:	4581                	li	a1,0
    80003266:	8526                	mv	a0,s1
    80003268:	00003097          	auipc	ra,0x3
    8000326c:	f24080e7          	jalr	-220(ra) # 8000618c <virtio_disk_rw>
    b->valid = 1;
    80003270:	4785                	li	a5,1
    80003272:	c09c                	sw	a5,0(s1)
  return b;
    80003274:	b7c5                	j	80003254 <bread+0xd0>

0000000080003276 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003276:	1101                	addi	sp,sp,-32
    80003278:	ec06                	sd	ra,24(sp)
    8000327a:	e822                	sd	s0,16(sp)
    8000327c:	e426                	sd	s1,8(sp)
    8000327e:	1000                	addi	s0,sp,32
    80003280:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003282:	0541                	addi	a0,a0,16
    80003284:	00001097          	auipc	ra,0x1
    80003288:	45c080e7          	jalr	1116(ra) # 800046e0 <holdingsleep>
    8000328c:	cd01                	beqz	a0,800032a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000328e:	4585                	li	a1,1
    80003290:	8526                	mv	a0,s1
    80003292:	00003097          	auipc	ra,0x3
    80003296:	efa080e7          	jalr	-262(ra) # 8000618c <virtio_disk_rw>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	64a2                	ld	s1,8(sp)
    800032a0:	6105                	addi	sp,sp,32
    800032a2:	8082                	ret
    panic("bwrite");
    800032a4:	00005517          	auipc	a0,0x5
    800032a8:	2ac50513          	addi	a0,a0,684 # 80008550 <syscalls+0xd8>
    800032ac:	ffffd097          	auipc	ra,0xffffd
    800032b0:	294080e7          	jalr	660(ra) # 80000540 <panic>

00000000800032b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	e04a                	sd	s2,0(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c2:	01050913          	addi	s2,a0,16
    800032c6:	854a                	mv	a0,s2
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	418080e7          	jalr	1048(ra) # 800046e0 <holdingsleep>
    800032d0:	c92d                	beqz	a0,80003342 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00001097          	auipc	ra,0x1
    800032d8:	3c8080e7          	jalr	968(ra) # 8000469c <releasesleep>

  acquire(&bcache.lock);
    800032dc:	00015517          	auipc	a0,0x15
    800032e0:	1a450513          	addi	a0,a0,420 # 80018480 <bcache>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	918080e7          	jalr	-1768(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032ec:	40bc                	lw	a5,64(s1)
    800032ee:	37fd                	addiw	a5,a5,-1
    800032f0:	0007871b          	sext.w	a4,a5
    800032f4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032f6:	eb05                	bnez	a4,80003326 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032f8:	68bc                	ld	a5,80(s1)
    800032fa:	64b8                	ld	a4,72(s1)
    800032fc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032fe:	64bc                	ld	a5,72(s1)
    80003300:	68b8                	ld	a4,80(s1)
    80003302:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003304:	0001d797          	auipc	a5,0x1d
    80003308:	17c78793          	addi	a5,a5,380 # 80020480 <bcache+0x8000>
    8000330c:	2b87b703          	ld	a4,696(a5)
    80003310:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003312:	0001d717          	auipc	a4,0x1d
    80003316:	3d670713          	addi	a4,a4,982 # 800206e8 <bcache+0x8268>
    8000331a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000331c:	2b87b703          	ld	a4,696(a5)
    80003320:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003322:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003326:	00015517          	auipc	a0,0x15
    8000332a:	15a50513          	addi	a0,a0,346 # 80018480 <bcache>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	982080e7          	jalr	-1662(ra) # 80000cb0 <release>
}
    80003336:	60e2                	ld	ra,24(sp)
    80003338:	6442                	ld	s0,16(sp)
    8000333a:	64a2                	ld	s1,8(sp)
    8000333c:	6902                	ld	s2,0(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret
    panic("brelse");
    80003342:	00005517          	auipc	a0,0x5
    80003346:	21650513          	addi	a0,a0,534 # 80008558 <syscalls+0xe0>
    8000334a:	ffffd097          	auipc	ra,0xffffd
    8000334e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>

0000000080003352 <bpin>:

void
bpin(struct buf *b) {
    80003352:	1101                	addi	sp,sp,-32
    80003354:	ec06                	sd	ra,24(sp)
    80003356:	e822                	sd	s0,16(sp)
    80003358:	e426                	sd	s1,8(sp)
    8000335a:	1000                	addi	s0,sp,32
    8000335c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000335e:	00015517          	auipc	a0,0x15
    80003362:	12250513          	addi	a0,a0,290 # 80018480 <bcache>
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	896080e7          	jalr	-1898(ra) # 80000bfc <acquire>
  b->refcnt++;
    8000336e:	40bc                	lw	a5,64(s1)
    80003370:	2785                	addiw	a5,a5,1
    80003372:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003374:	00015517          	auipc	a0,0x15
    80003378:	10c50513          	addi	a0,a0,268 # 80018480 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	934080e7          	jalr	-1740(ra) # 80000cb0 <release>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6105                	addi	sp,sp,32
    8000338c:	8082                	ret

000000008000338e <bunpin>:

void
bunpin(struct buf *b) {
    8000338e:	1101                	addi	sp,sp,-32
    80003390:	ec06                	sd	ra,24(sp)
    80003392:	e822                	sd	s0,16(sp)
    80003394:	e426                	sd	s1,8(sp)
    80003396:	1000                	addi	s0,sp,32
    80003398:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000339a:	00015517          	auipc	a0,0x15
    8000339e:	0e650513          	addi	a0,a0,230 # 80018480 <bcache>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	85a080e7          	jalr	-1958(ra) # 80000bfc <acquire>
  b->refcnt--;
    800033aa:	40bc                	lw	a5,64(s1)
    800033ac:	37fd                	addiw	a5,a5,-1
    800033ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033b0:	00015517          	auipc	a0,0x15
    800033b4:	0d050513          	addi	a0,a0,208 # 80018480 <bcache>
    800033b8:	ffffe097          	auipc	ra,0xffffe
    800033bc:	8f8080e7          	jalr	-1800(ra) # 80000cb0 <release>
}
    800033c0:	60e2                	ld	ra,24(sp)
    800033c2:	6442                	ld	s0,16(sp)
    800033c4:	64a2                	ld	s1,8(sp)
    800033c6:	6105                	addi	sp,sp,32
    800033c8:	8082                	ret

00000000800033ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ca:	1101                	addi	sp,sp,-32
    800033cc:	ec06                	sd	ra,24(sp)
    800033ce:	e822                	sd	s0,16(sp)
    800033d0:	e426                	sd	s1,8(sp)
    800033d2:	e04a                	sd	s2,0(sp)
    800033d4:	1000                	addi	s0,sp,32
    800033d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033d8:	00d5d59b          	srliw	a1,a1,0xd
    800033dc:	0001d797          	auipc	a5,0x1d
    800033e0:	7807a783          	lw	a5,1920(a5) # 80020b5c <sb+0x1c>
    800033e4:	9dbd                	addw	a1,a1,a5
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	d9e080e7          	jalr	-610(ra) # 80003184 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033ee:	0074f713          	andi	a4,s1,7
    800033f2:	4785                	li	a5,1
    800033f4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033f8:	14ce                	slli	s1,s1,0x33
    800033fa:	90d9                	srli	s1,s1,0x36
    800033fc:	00950733          	add	a4,a0,s1
    80003400:	05874703          	lbu	a4,88(a4)
    80003404:	00e7f6b3          	and	a3,a5,a4
    80003408:	c69d                	beqz	a3,80003436 <bfree+0x6c>
    8000340a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000340c:	94aa                	add	s1,s1,a0
    8000340e:	fff7c793          	not	a5,a5
    80003412:	8ff9                	and	a5,a5,a4
    80003414:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003418:	00001097          	auipc	ra,0x1
    8000341c:	106080e7          	jalr	262(ra) # 8000451e <log_write>
  brelse(bp);
    80003420:	854a                	mv	a0,s2
    80003422:	00000097          	auipc	ra,0x0
    80003426:	e92080e7          	jalr	-366(ra) # 800032b4 <brelse>
}
    8000342a:	60e2                	ld	ra,24(sp)
    8000342c:	6442                	ld	s0,16(sp)
    8000342e:	64a2                	ld	s1,8(sp)
    80003430:	6902                	ld	s2,0(sp)
    80003432:	6105                	addi	sp,sp,32
    80003434:	8082                	ret
    panic("freeing free block");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	12a50513          	addi	a0,a0,298 # 80008560 <syscalls+0xe8>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	102080e7          	jalr	258(ra) # 80000540 <panic>

0000000080003446 <balloc>:
{
    80003446:	711d                	addi	sp,sp,-96
    80003448:	ec86                	sd	ra,88(sp)
    8000344a:	e8a2                	sd	s0,80(sp)
    8000344c:	e4a6                	sd	s1,72(sp)
    8000344e:	e0ca                	sd	s2,64(sp)
    80003450:	fc4e                	sd	s3,56(sp)
    80003452:	f852                	sd	s4,48(sp)
    80003454:	f456                	sd	s5,40(sp)
    80003456:	f05a                	sd	s6,32(sp)
    80003458:	ec5e                	sd	s7,24(sp)
    8000345a:	e862                	sd	s8,16(sp)
    8000345c:	e466                	sd	s9,8(sp)
    8000345e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003460:	0001d797          	auipc	a5,0x1d
    80003464:	6e47a783          	lw	a5,1764(a5) # 80020b44 <sb+0x4>
    80003468:	cbd1                	beqz	a5,800034fc <balloc+0xb6>
    8000346a:	8baa                	mv	s7,a0
    8000346c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000346e:	0001db17          	auipc	s6,0x1d
    80003472:	6d2b0b13          	addi	s6,s6,1746 # 80020b40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003476:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003478:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000347a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000347c:	6c89                	lui	s9,0x2
    8000347e:	a831                	j	8000349a <balloc+0x54>
    brelse(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	00000097          	auipc	ra,0x0
    80003486:	e32080e7          	jalr	-462(ra) # 800032b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000348a:	015c87bb          	addw	a5,s9,s5
    8000348e:	00078a9b          	sext.w	s5,a5
    80003492:	004b2703          	lw	a4,4(s6)
    80003496:	06eaf363          	bgeu	s5,a4,800034fc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000349a:	41fad79b          	sraiw	a5,s5,0x1f
    8000349e:	0137d79b          	srliw	a5,a5,0x13
    800034a2:	015787bb          	addw	a5,a5,s5
    800034a6:	40d7d79b          	sraiw	a5,a5,0xd
    800034aa:	01cb2583          	lw	a1,28(s6)
    800034ae:	9dbd                	addw	a1,a1,a5
    800034b0:	855e                	mv	a0,s7
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	cd2080e7          	jalr	-814(ra) # 80003184 <bread>
    800034ba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034bc:	004b2503          	lw	a0,4(s6)
    800034c0:	000a849b          	sext.w	s1,s5
    800034c4:	8662                	mv	a2,s8
    800034c6:	faa4fde3          	bgeu	s1,a0,80003480 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ca:	41f6579b          	sraiw	a5,a2,0x1f
    800034ce:	01d7d69b          	srliw	a3,a5,0x1d
    800034d2:	00c6873b          	addw	a4,a3,a2
    800034d6:	00777793          	andi	a5,a4,7
    800034da:	9f95                	subw	a5,a5,a3
    800034dc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034e0:	4037571b          	sraiw	a4,a4,0x3
    800034e4:	00e906b3          	add	a3,s2,a4
    800034e8:	0586c683          	lbu	a3,88(a3)
    800034ec:	00d7f5b3          	and	a1,a5,a3
    800034f0:	cd91                	beqz	a1,8000350c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f2:	2605                	addiw	a2,a2,1
    800034f4:	2485                	addiw	s1,s1,1
    800034f6:	fd4618e3          	bne	a2,s4,800034c6 <balloc+0x80>
    800034fa:	b759                	j	80003480 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034fc:	00005517          	auipc	a0,0x5
    80003500:	07c50513          	addi	a0,a0,124 # 80008578 <syscalls+0x100>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	03c080e7          	jalr	60(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000350c:	974a                	add	a4,a4,s2
    8000350e:	8fd5                	or	a5,a5,a3
    80003510:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003514:	854a                	mv	a0,s2
    80003516:	00001097          	auipc	ra,0x1
    8000351a:	008080e7          	jalr	8(ra) # 8000451e <log_write>
        brelse(bp);
    8000351e:	854a                	mv	a0,s2
    80003520:	00000097          	auipc	ra,0x0
    80003524:	d94080e7          	jalr	-620(ra) # 800032b4 <brelse>
  bp = bread(dev, bno);
    80003528:	85a6                	mv	a1,s1
    8000352a:	855e                	mv	a0,s7
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	c58080e7          	jalr	-936(ra) # 80003184 <bread>
    80003534:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003536:	40000613          	li	a2,1024
    8000353a:	4581                	li	a1,0
    8000353c:	05850513          	addi	a0,a0,88
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	7b8080e7          	jalr	1976(ra) # 80000cf8 <memset>
  log_write(bp);
    80003548:	854a                	mv	a0,s2
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	fd4080e7          	jalr	-44(ra) # 8000451e <log_write>
  brelse(bp);
    80003552:	854a                	mv	a0,s2
    80003554:	00000097          	auipc	ra,0x0
    80003558:	d60080e7          	jalr	-672(ra) # 800032b4 <brelse>
}
    8000355c:	8526                	mv	a0,s1
    8000355e:	60e6                	ld	ra,88(sp)
    80003560:	6446                	ld	s0,80(sp)
    80003562:	64a6                	ld	s1,72(sp)
    80003564:	6906                	ld	s2,64(sp)
    80003566:	79e2                	ld	s3,56(sp)
    80003568:	7a42                	ld	s4,48(sp)
    8000356a:	7aa2                	ld	s5,40(sp)
    8000356c:	7b02                	ld	s6,32(sp)
    8000356e:	6be2                	ld	s7,24(sp)
    80003570:	6c42                	ld	s8,16(sp)
    80003572:	6ca2                	ld	s9,8(sp)
    80003574:	6125                	addi	sp,sp,96
    80003576:	8082                	ret

0000000080003578 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	e052                	sd	s4,0(sp)
    80003586:	1800                	addi	s0,sp,48
    80003588:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000358a:	47ad                	li	a5,11
    8000358c:	04b7fe63          	bgeu	a5,a1,800035e8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003590:	ff45849b          	addiw	s1,a1,-12
    80003594:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003598:	0ff00793          	li	a5,255
    8000359c:	0ae7e463          	bltu	a5,a4,80003644 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a0:	08052583          	lw	a1,128(a0)
    800035a4:	c5b5                	beqz	a1,80003610 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035a6:	00092503          	lw	a0,0(s2)
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	bda080e7          	jalr	-1062(ra) # 80003184 <bread>
    800035b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b8:	02049713          	slli	a4,s1,0x20
    800035bc:	01e75593          	srli	a1,a4,0x1e
    800035c0:	00b784b3          	add	s1,a5,a1
    800035c4:	0004a983          	lw	s3,0(s1)
    800035c8:	04098e63          	beqz	s3,80003624 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035cc:	8552                	mv	a0,s4
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	ce6080e7          	jalr	-794(ra) # 800032b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d6:	854e                	mv	a0,s3
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6a02                	ld	s4,0(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e8:	02059793          	slli	a5,a1,0x20
    800035ec:	01e7d593          	srli	a1,a5,0x1e
    800035f0:	00b504b3          	add	s1,a0,a1
    800035f4:	0504a983          	lw	s3,80(s1)
    800035f8:	fc099fe3          	bnez	s3,800035d6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035fc:	4108                	lw	a0,0(a0)
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	e48080e7          	jalr	-440(ra) # 80003446 <balloc>
    80003606:	0005099b          	sext.w	s3,a0
    8000360a:	0534a823          	sw	s3,80(s1)
    8000360e:	b7e1                	j	800035d6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003610:	4108                	lw	a0,0(a0)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e34080e7          	jalr	-460(ra) # 80003446 <balloc>
    8000361a:	0005059b          	sext.w	a1,a0
    8000361e:	08b92023          	sw	a1,128(s2)
    80003622:	b751                	j	800035a6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003624:	00092503          	lw	a0,0(s2)
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e1e080e7          	jalr	-482(ra) # 80003446 <balloc>
    80003630:	0005099b          	sext.w	s3,a0
    80003634:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003638:	8552                	mv	a0,s4
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	ee4080e7          	jalr	-284(ra) # 8000451e <log_write>
    80003642:	b769                	j	800035cc <bmap+0x54>
  panic("bmap: out of range");
    80003644:	00005517          	auipc	a0,0x5
    80003648:	f4c50513          	addi	a0,a0,-180 # 80008590 <syscalls+0x118>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	ef4080e7          	jalr	-268(ra) # 80000540 <panic>

0000000080003654 <iget>:
{
    80003654:	7179                	addi	sp,sp,-48
    80003656:	f406                	sd	ra,40(sp)
    80003658:	f022                	sd	s0,32(sp)
    8000365a:	ec26                	sd	s1,24(sp)
    8000365c:	e84a                	sd	s2,16(sp)
    8000365e:	e44e                	sd	s3,8(sp)
    80003660:	e052                	sd	s4,0(sp)
    80003662:	1800                	addi	s0,sp,48
    80003664:	89aa                	mv	s3,a0
    80003666:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003668:	0001d517          	auipc	a0,0x1d
    8000366c:	4f850513          	addi	a0,a0,1272 # 80020b60 <icache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	58c080e7          	jalr	1420(ra) # 80000bfc <acquire>
  empty = 0;
    80003678:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000367a:	0001d497          	auipc	s1,0x1d
    8000367e:	4fe48493          	addi	s1,s1,1278 # 80020b78 <icache+0x18>
    80003682:	0001f697          	auipc	a3,0x1f
    80003686:	f8668693          	addi	a3,a3,-122 # 80022608 <log>
    8000368a:	a039                	j	80003698 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368c:	02090b63          	beqz	s2,800036c2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003690:	08848493          	addi	s1,s1,136
    80003694:	02d48a63          	beq	s1,a3,800036c8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003698:	449c                	lw	a5,8(s1)
    8000369a:	fef059e3          	blez	a5,8000368c <iget+0x38>
    8000369e:	4098                	lw	a4,0(s1)
    800036a0:	ff3716e3          	bne	a4,s3,8000368c <iget+0x38>
    800036a4:	40d8                	lw	a4,4(s1)
    800036a6:	ff4713e3          	bne	a4,s4,8000368c <iget+0x38>
      ip->ref++;
    800036aa:	2785                	addiw	a5,a5,1
    800036ac:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036ae:	0001d517          	auipc	a0,0x1d
    800036b2:	4b250513          	addi	a0,a0,1202 # 80020b60 <icache>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	5fa080e7          	jalr	1530(ra) # 80000cb0 <release>
      return ip;
    800036be:	8926                	mv	s2,s1
    800036c0:	a03d                	j	800036ee <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c2:	f7f9                	bnez	a5,80003690 <iget+0x3c>
    800036c4:	8926                	mv	s2,s1
    800036c6:	b7e9                	j	80003690 <iget+0x3c>
  if(empty == 0)
    800036c8:	02090c63          	beqz	s2,80003700 <iget+0xac>
  ip->dev = dev;
    800036cc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036d0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d4:	4785                	li	a5,1
    800036d6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036da:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036de:	0001d517          	auipc	a0,0x1d
    800036e2:	48250513          	addi	a0,a0,1154 # 80020b60 <icache>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	5ca080e7          	jalr	1482(ra) # 80000cb0 <release>
}
    800036ee:	854a                	mv	a0,s2
    800036f0:	70a2                	ld	ra,40(sp)
    800036f2:	7402                	ld	s0,32(sp)
    800036f4:	64e2                	ld	s1,24(sp)
    800036f6:	6942                	ld	s2,16(sp)
    800036f8:	69a2                	ld	s3,8(sp)
    800036fa:	6a02                	ld	s4,0(sp)
    800036fc:	6145                	addi	sp,sp,48
    800036fe:	8082                	ret
    panic("iget: no inodes");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	ea850513          	addi	a0,a0,-344 # 800085a8 <syscalls+0x130>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e38080e7          	jalr	-456(ra) # 80000540 <panic>

0000000080003710 <fsinit>:
fsinit(int dev) {
    80003710:	7179                	addi	sp,sp,-48
    80003712:	f406                	sd	ra,40(sp)
    80003714:	f022                	sd	s0,32(sp)
    80003716:	ec26                	sd	s1,24(sp)
    80003718:	e84a                	sd	s2,16(sp)
    8000371a:	e44e                	sd	s3,8(sp)
    8000371c:	1800                	addi	s0,sp,48
    8000371e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003720:	4585                	li	a1,1
    80003722:	00000097          	auipc	ra,0x0
    80003726:	a62080e7          	jalr	-1438(ra) # 80003184 <bread>
    8000372a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000372c:	0001d997          	auipc	s3,0x1d
    80003730:	41498993          	addi	s3,s3,1044 # 80020b40 <sb>
    80003734:	02000613          	li	a2,32
    80003738:	05850593          	addi	a1,a0,88
    8000373c:	854e                	mv	a0,s3
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	616080e7          	jalr	1558(ra) # 80000d54 <memmove>
  brelse(bp);
    80003746:	8526                	mv	a0,s1
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	b6c080e7          	jalr	-1172(ra) # 800032b4 <brelse>
  if(sb.magic != FSMAGIC)
    80003750:	0009a703          	lw	a4,0(s3)
    80003754:	102037b7          	lui	a5,0x10203
    80003758:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000375c:	02f71263          	bne	a4,a5,80003780 <fsinit+0x70>
  initlog(dev, &sb);
    80003760:	0001d597          	auipc	a1,0x1d
    80003764:	3e058593          	addi	a1,a1,992 # 80020b40 <sb>
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	b3a080e7          	jalr	-1222(ra) # 800042a4 <initlog>
}
    80003772:	70a2                	ld	ra,40(sp)
    80003774:	7402                	ld	s0,32(sp)
    80003776:	64e2                	ld	s1,24(sp)
    80003778:	6942                	ld	s2,16(sp)
    8000377a:	69a2                	ld	s3,8(sp)
    8000377c:	6145                	addi	sp,sp,48
    8000377e:	8082                	ret
    panic("invalid file system");
    80003780:	00005517          	auipc	a0,0x5
    80003784:	e3850513          	addi	a0,a0,-456 # 800085b8 <syscalls+0x140>
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	db8080e7          	jalr	-584(ra) # 80000540 <panic>

0000000080003790 <iinit>:
{
    80003790:	7179                	addi	sp,sp,-48
    80003792:	f406                	sd	ra,40(sp)
    80003794:	f022                	sd	s0,32(sp)
    80003796:	ec26                	sd	s1,24(sp)
    80003798:	e84a                	sd	s2,16(sp)
    8000379a:	e44e                	sd	s3,8(sp)
    8000379c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000379e:	00005597          	auipc	a1,0x5
    800037a2:	e3258593          	addi	a1,a1,-462 # 800085d0 <syscalls+0x158>
    800037a6:	0001d517          	auipc	a0,0x1d
    800037aa:	3ba50513          	addi	a0,a0,954 # 80020b60 <icache>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	3be080e7          	jalr	958(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037b6:	0001d497          	auipc	s1,0x1d
    800037ba:	3d248493          	addi	s1,s1,978 # 80020b88 <icache+0x28>
    800037be:	0001f997          	auipc	s3,0x1f
    800037c2:	e5a98993          	addi	s3,s3,-422 # 80022618 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037c6:	00005917          	auipc	s2,0x5
    800037ca:	e1290913          	addi	s2,s2,-494 # 800085d8 <syscalls+0x160>
    800037ce:	85ca                	mv	a1,s2
    800037d0:	8526                	mv	a0,s1
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	e3a080e7          	jalr	-454(ra) # 8000460c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037da:	08848493          	addi	s1,s1,136
    800037de:	ff3498e3          	bne	s1,s3,800037ce <iinit+0x3e>
}
    800037e2:	70a2                	ld	ra,40(sp)
    800037e4:	7402                	ld	s0,32(sp)
    800037e6:	64e2                	ld	s1,24(sp)
    800037e8:	6942                	ld	s2,16(sp)
    800037ea:	69a2                	ld	s3,8(sp)
    800037ec:	6145                	addi	sp,sp,48
    800037ee:	8082                	ret

00000000800037f0 <ialloc>:
{
    800037f0:	715d                	addi	sp,sp,-80
    800037f2:	e486                	sd	ra,72(sp)
    800037f4:	e0a2                	sd	s0,64(sp)
    800037f6:	fc26                	sd	s1,56(sp)
    800037f8:	f84a                	sd	s2,48(sp)
    800037fa:	f44e                	sd	s3,40(sp)
    800037fc:	f052                	sd	s4,32(sp)
    800037fe:	ec56                	sd	s5,24(sp)
    80003800:	e85a                	sd	s6,16(sp)
    80003802:	e45e                	sd	s7,8(sp)
    80003804:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003806:	0001d717          	auipc	a4,0x1d
    8000380a:	34672703          	lw	a4,838(a4) # 80020b4c <sb+0xc>
    8000380e:	4785                	li	a5,1
    80003810:	04e7fa63          	bgeu	a5,a4,80003864 <ialloc+0x74>
    80003814:	8aaa                	mv	s5,a0
    80003816:	8bae                	mv	s7,a1
    80003818:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000381a:	0001da17          	auipc	s4,0x1d
    8000381e:	326a0a13          	addi	s4,s4,806 # 80020b40 <sb>
    80003822:	00048b1b          	sext.w	s6,s1
    80003826:	0044d793          	srli	a5,s1,0x4
    8000382a:	018a2583          	lw	a1,24(s4)
    8000382e:	9dbd                	addw	a1,a1,a5
    80003830:	8556                	mv	a0,s5
    80003832:	00000097          	auipc	ra,0x0
    80003836:	952080e7          	jalr	-1710(ra) # 80003184 <bread>
    8000383a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000383c:	05850993          	addi	s3,a0,88
    80003840:	00f4f793          	andi	a5,s1,15
    80003844:	079a                	slli	a5,a5,0x6
    80003846:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003848:	00099783          	lh	a5,0(s3)
    8000384c:	c785                	beqz	a5,80003874 <ialloc+0x84>
    brelse(bp);
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	a66080e7          	jalr	-1434(ra) # 800032b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003856:	0485                	addi	s1,s1,1
    80003858:	00ca2703          	lw	a4,12(s4)
    8000385c:	0004879b          	sext.w	a5,s1
    80003860:	fce7e1e3          	bltu	a5,a4,80003822 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003864:	00005517          	auipc	a0,0x5
    80003868:	d7c50513          	addi	a0,a0,-644 # 800085e0 <syscalls+0x168>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	cd4080e7          	jalr	-812(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003874:	04000613          	li	a2,64
    80003878:	4581                	li	a1,0
    8000387a:	854e                	mv	a0,s3
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	47c080e7          	jalr	1148(ra) # 80000cf8 <memset>
      dip->type = type;
    80003884:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003888:	854a                	mv	a0,s2
    8000388a:	00001097          	auipc	ra,0x1
    8000388e:	c94080e7          	jalr	-876(ra) # 8000451e <log_write>
      brelse(bp);
    80003892:	854a                	mv	a0,s2
    80003894:	00000097          	auipc	ra,0x0
    80003898:	a20080e7          	jalr	-1504(ra) # 800032b4 <brelse>
      return iget(dev, inum);
    8000389c:	85da                	mv	a1,s6
    8000389e:	8556                	mv	a0,s5
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	db4080e7          	jalr	-588(ra) # 80003654 <iget>
}
    800038a8:	60a6                	ld	ra,72(sp)
    800038aa:	6406                	ld	s0,64(sp)
    800038ac:	74e2                	ld	s1,56(sp)
    800038ae:	7942                	ld	s2,48(sp)
    800038b0:	79a2                	ld	s3,40(sp)
    800038b2:	7a02                	ld	s4,32(sp)
    800038b4:	6ae2                	ld	s5,24(sp)
    800038b6:	6b42                	ld	s6,16(sp)
    800038b8:	6ba2                	ld	s7,8(sp)
    800038ba:	6161                	addi	sp,sp,80
    800038bc:	8082                	ret

00000000800038be <iupdate>:
{
    800038be:	1101                	addi	sp,sp,-32
    800038c0:	ec06                	sd	ra,24(sp)
    800038c2:	e822                	sd	s0,16(sp)
    800038c4:	e426                	sd	s1,8(sp)
    800038c6:	e04a                	sd	s2,0(sp)
    800038c8:	1000                	addi	s0,sp,32
    800038ca:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038cc:	415c                	lw	a5,4(a0)
    800038ce:	0047d79b          	srliw	a5,a5,0x4
    800038d2:	0001d597          	auipc	a1,0x1d
    800038d6:	2865a583          	lw	a1,646(a1) # 80020b58 <sb+0x18>
    800038da:	9dbd                	addw	a1,a1,a5
    800038dc:	4108                	lw	a0,0(a0)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	8a6080e7          	jalr	-1882(ra) # 80003184 <bread>
    800038e6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e8:	05850793          	addi	a5,a0,88
    800038ec:	40c8                	lw	a0,4(s1)
    800038ee:	893d                	andi	a0,a0,15
    800038f0:	051a                	slli	a0,a0,0x6
    800038f2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f4:	04449703          	lh	a4,68(s1)
    800038f8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038fc:	04649703          	lh	a4,70(s1)
    80003900:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003904:	04849703          	lh	a4,72(s1)
    80003908:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000390c:	04a49703          	lh	a4,74(s1)
    80003910:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003914:	44f8                	lw	a4,76(s1)
    80003916:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003918:	03400613          	li	a2,52
    8000391c:	05048593          	addi	a1,s1,80
    80003920:	0531                	addi	a0,a0,12
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	432080e7          	jalr	1074(ra) # 80000d54 <memmove>
  log_write(bp);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	bf2080e7          	jalr	-1038(ra) # 8000451e <log_write>
  brelse(bp);
    80003934:	854a                	mv	a0,s2
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	97e080e7          	jalr	-1666(ra) # 800032b4 <brelse>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	64a2                	ld	s1,8(sp)
    80003944:	6902                	ld	s2,0(sp)
    80003946:	6105                	addi	sp,sp,32
    80003948:	8082                	ret

000000008000394a <idup>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	1000                	addi	s0,sp,32
    80003954:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003956:	0001d517          	auipc	a0,0x1d
    8000395a:	20a50513          	addi	a0,a0,522 # 80020b60 <icache>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	29e080e7          	jalr	670(ra) # 80000bfc <acquire>
  ip->ref++;
    80003966:	449c                	lw	a5,8(s1)
    80003968:	2785                	addiw	a5,a5,1
    8000396a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000396c:	0001d517          	auipc	a0,0x1d
    80003970:	1f450513          	addi	a0,a0,500 # 80020b60 <icache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	33c080e7          	jalr	828(ra) # 80000cb0 <release>
}
    8000397c:	8526                	mv	a0,s1
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <ilock>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003994:	c115                	beqz	a0,800039b8 <ilock+0x30>
    80003996:	84aa                	mv	s1,a0
    80003998:	451c                	lw	a5,8(a0)
    8000399a:	00f05f63          	blez	a5,800039b8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399e:	0541                	addi	a0,a0,16
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	ca6080e7          	jalr	-858(ra) # 80004646 <acquiresleep>
  if(ip->valid == 0){
    800039a8:	40bc                	lw	a5,64(s1)
    800039aa:	cf99                	beqz	a5,800039c8 <ilock+0x40>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
    panic("ilock");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	c4050513          	addi	a0,a0,-960 # 800085f8 <syscalls+0x180>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	b80080e7          	jalr	-1152(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c8:	40dc                	lw	a5,4(s1)
    800039ca:	0047d79b          	srliw	a5,a5,0x4
    800039ce:	0001d597          	auipc	a1,0x1d
    800039d2:	18a5a583          	lw	a1,394(a1) # 80020b58 <sb+0x18>
    800039d6:	9dbd                	addw	a1,a1,a5
    800039d8:	4088                	lw	a0,0(s1)
    800039da:	fffff097          	auipc	ra,0xfffff
    800039de:	7aa080e7          	jalr	1962(ra) # 80003184 <bread>
    800039e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e4:	05850593          	addi	a1,a0,88
    800039e8:	40dc                	lw	a5,4(s1)
    800039ea:	8bbd                	andi	a5,a5,15
    800039ec:	079a                	slli	a5,a5,0x6
    800039ee:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f0:	00059783          	lh	a5,0(a1)
    800039f4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f8:	00259783          	lh	a5,2(a1)
    800039fc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a00:	00459783          	lh	a5,4(a1)
    80003a04:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a08:	00659783          	lh	a5,6(a1)
    80003a0c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a10:	459c                	lw	a5,8(a1)
    80003a12:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a14:	03400613          	li	a2,52
    80003a18:	05b1                	addi	a1,a1,12
    80003a1a:	05048513          	addi	a0,s1,80
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	336080e7          	jalr	822(ra) # 80000d54 <memmove>
    brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	88c080e7          	jalr	-1908(ra) # 800032b4 <brelse>
    ip->valid = 1;
    80003a30:	4785                	li	a5,1
    80003a32:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a34:	04449783          	lh	a5,68(s1)
    80003a38:	fbb5                	bnez	a5,800039ac <ilock+0x24>
      panic("ilock: no type");
    80003a3a:	00005517          	auipc	a0,0x5
    80003a3e:	bc650513          	addi	a0,a0,-1082 # 80008600 <syscalls+0x188>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	afe080e7          	jalr	-1282(ra) # 80000540 <panic>

0000000080003a4a <iunlock>:
{
    80003a4a:	1101                	addi	sp,sp,-32
    80003a4c:	ec06                	sd	ra,24(sp)
    80003a4e:	e822                	sd	s0,16(sp)
    80003a50:	e426                	sd	s1,8(sp)
    80003a52:	e04a                	sd	s2,0(sp)
    80003a54:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a56:	c905                	beqz	a0,80003a86 <iunlock+0x3c>
    80003a58:	84aa                	mv	s1,a0
    80003a5a:	01050913          	addi	s2,a0,16
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	c80080e7          	jalr	-896(ra) # 800046e0 <holdingsleep>
    80003a68:	cd19                	beqz	a0,80003a86 <iunlock+0x3c>
    80003a6a:	449c                	lw	a5,8(s1)
    80003a6c:	00f05d63          	blez	a5,80003a86 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a70:	854a                	mv	a0,s2
    80003a72:	00001097          	auipc	ra,0x1
    80003a76:	c2a080e7          	jalr	-982(ra) # 8000469c <releasesleep>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6902                	ld	s2,0(sp)
    80003a82:	6105                	addi	sp,sp,32
    80003a84:	8082                	ret
    panic("iunlock");
    80003a86:	00005517          	auipc	a0,0x5
    80003a8a:	b8a50513          	addi	a0,a0,-1142 # 80008610 <syscalls+0x198>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	ab2080e7          	jalr	-1358(ra) # 80000540 <panic>

0000000080003a96 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a96:	7179                	addi	sp,sp,-48
    80003a98:	f406                	sd	ra,40(sp)
    80003a9a:	f022                	sd	s0,32(sp)
    80003a9c:	ec26                	sd	s1,24(sp)
    80003a9e:	e84a                	sd	s2,16(sp)
    80003aa0:	e44e                	sd	s3,8(sp)
    80003aa2:	e052                	sd	s4,0(sp)
    80003aa4:	1800                	addi	s0,sp,48
    80003aa6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aa8:	05050493          	addi	s1,a0,80
    80003aac:	08050913          	addi	s2,a0,128
    80003ab0:	a021                	j	80003ab8 <itrunc+0x22>
    80003ab2:	0491                	addi	s1,s1,4
    80003ab4:	01248d63          	beq	s1,s2,80003ace <itrunc+0x38>
    if(ip->addrs[i]){
    80003ab8:	408c                	lw	a1,0(s1)
    80003aba:	dde5                	beqz	a1,80003ab2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003abc:	0009a503          	lw	a0,0(s3)
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	90a080e7          	jalr	-1782(ra) # 800033ca <bfree>
      ip->addrs[i] = 0;
    80003ac8:	0004a023          	sw	zero,0(s1)
    80003acc:	b7dd                	j	80003ab2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ace:	0809a583          	lw	a1,128(s3)
    80003ad2:	e185                	bnez	a1,80003af2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad8:	854e                	mv	a0,s3
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	de4080e7          	jalr	-540(ra) # 800038be <iupdate>
}
    80003ae2:	70a2                	ld	ra,40(sp)
    80003ae4:	7402                	ld	s0,32(sp)
    80003ae6:	64e2                	ld	s1,24(sp)
    80003ae8:	6942                	ld	s2,16(sp)
    80003aea:	69a2                	ld	s3,8(sp)
    80003aec:	6a02                	ld	s4,0(sp)
    80003aee:	6145                	addi	sp,sp,48
    80003af0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af2:	0009a503          	lw	a0,0(s3)
    80003af6:	fffff097          	auipc	ra,0xfffff
    80003afa:	68e080e7          	jalr	1678(ra) # 80003184 <bread>
    80003afe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b00:	05850493          	addi	s1,a0,88
    80003b04:	45850913          	addi	s2,a0,1112
    80003b08:	a021                	j	80003b10 <itrunc+0x7a>
    80003b0a:	0491                	addi	s1,s1,4
    80003b0c:	01248b63          	beq	s1,s2,80003b22 <itrunc+0x8c>
      if(a[j])
    80003b10:	408c                	lw	a1,0(s1)
    80003b12:	dde5                	beqz	a1,80003b0a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b14:	0009a503          	lw	a0,0(s3)
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	8b2080e7          	jalr	-1870(ra) # 800033ca <bfree>
    80003b20:	b7ed                	j	80003b0a <itrunc+0x74>
    brelse(bp);
    80003b22:	8552                	mv	a0,s4
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	790080e7          	jalr	1936(ra) # 800032b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b2c:	0809a583          	lw	a1,128(s3)
    80003b30:	0009a503          	lw	a0,0(s3)
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	896080e7          	jalr	-1898(ra) # 800033ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b3c:	0809a023          	sw	zero,128(s3)
    80003b40:	bf51                	j	80003ad4 <itrunc+0x3e>

0000000080003b42 <iput>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	e04a                	sd	s2,0(sp)
    80003b4c:	1000                	addi	s0,sp,32
    80003b4e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b50:	0001d517          	auipc	a0,0x1d
    80003b54:	01050513          	addi	a0,a0,16 # 80020b60 <icache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	0a4080e7          	jalr	164(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b60:	4498                	lw	a4,8(s1)
    80003b62:	4785                	li	a5,1
    80003b64:	02f70363          	beq	a4,a5,80003b8a <iput+0x48>
  ip->ref--;
    80003b68:	449c                	lw	a5,8(s1)
    80003b6a:	37fd                	addiw	a5,a5,-1
    80003b6c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b6e:	0001d517          	auipc	a0,0x1d
    80003b72:	ff250513          	addi	a0,a0,-14 # 80020b60 <icache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	13a080e7          	jalr	314(ra) # 80000cb0 <release>
}
    80003b7e:	60e2                	ld	ra,24(sp)
    80003b80:	6442                	ld	s0,16(sp)
    80003b82:	64a2                	ld	s1,8(sp)
    80003b84:	6902                	ld	s2,0(sp)
    80003b86:	6105                	addi	sp,sp,32
    80003b88:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b8a:	40bc                	lw	a5,64(s1)
    80003b8c:	dff1                	beqz	a5,80003b68 <iput+0x26>
    80003b8e:	04a49783          	lh	a5,74(s1)
    80003b92:	fbf9                	bnez	a5,80003b68 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b94:	01048913          	addi	s2,s1,16
    80003b98:	854a                	mv	a0,s2
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	aac080e7          	jalr	-1364(ra) # 80004646 <acquiresleep>
    release(&icache.lock);
    80003ba2:	0001d517          	auipc	a0,0x1d
    80003ba6:	fbe50513          	addi	a0,a0,-66 # 80020b60 <icache>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	106080e7          	jalr	262(ra) # 80000cb0 <release>
    itrunc(ip);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	ee2080e7          	jalr	-286(ra) # 80003a96 <itrunc>
    ip->type = 0;
    80003bbc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc0:	8526                	mv	a0,s1
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	cfc080e7          	jalr	-772(ra) # 800038be <iupdate>
    ip->valid = 0;
    80003bca:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bce:	854a                	mv	a0,s2
    80003bd0:	00001097          	auipc	ra,0x1
    80003bd4:	acc080e7          	jalr	-1332(ra) # 8000469c <releasesleep>
    acquire(&icache.lock);
    80003bd8:	0001d517          	auipc	a0,0x1d
    80003bdc:	f8850513          	addi	a0,a0,-120 # 80020b60 <icache>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	01c080e7          	jalr	28(ra) # 80000bfc <acquire>
    80003be8:	b741                	j	80003b68 <iput+0x26>

0000000080003bea <iunlockput>:
{
    80003bea:	1101                	addi	sp,sp,-32
    80003bec:	ec06                	sd	ra,24(sp)
    80003bee:	e822                	sd	s0,16(sp)
    80003bf0:	e426                	sd	s1,8(sp)
    80003bf2:	1000                	addi	s0,sp,32
    80003bf4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	e54080e7          	jalr	-428(ra) # 80003a4a <iunlock>
  iput(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	f42080e7          	jalr	-190(ra) # 80003b42 <iput>
}
    80003c08:	60e2                	ld	ra,24(sp)
    80003c0a:	6442                	ld	s0,16(sp)
    80003c0c:	64a2                	ld	s1,8(sp)
    80003c0e:	6105                	addi	sp,sp,32
    80003c10:	8082                	ret

0000000080003c12 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c12:	1141                	addi	sp,sp,-16
    80003c14:	e422                	sd	s0,8(sp)
    80003c16:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c18:	411c                	lw	a5,0(a0)
    80003c1a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c1c:	415c                	lw	a5,4(a0)
    80003c1e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c20:	04451783          	lh	a5,68(a0)
    80003c24:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c28:	04a51783          	lh	a5,74(a0)
    80003c2c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c30:	04c56783          	lwu	a5,76(a0)
    80003c34:	e99c                	sd	a5,16(a1)
}
    80003c36:	6422                	ld	s0,8(sp)
    80003c38:	0141                	addi	sp,sp,16
    80003c3a:	8082                	ret

0000000080003c3c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c3c:	457c                	lw	a5,76(a0)
    80003c3e:	0ed7e863          	bltu	a5,a3,80003d2e <readi+0xf2>
{
    80003c42:	7159                	addi	sp,sp,-112
    80003c44:	f486                	sd	ra,104(sp)
    80003c46:	f0a2                	sd	s0,96(sp)
    80003c48:	eca6                	sd	s1,88(sp)
    80003c4a:	e8ca                	sd	s2,80(sp)
    80003c4c:	e4ce                	sd	s3,72(sp)
    80003c4e:	e0d2                	sd	s4,64(sp)
    80003c50:	fc56                	sd	s5,56(sp)
    80003c52:	f85a                	sd	s6,48(sp)
    80003c54:	f45e                	sd	s7,40(sp)
    80003c56:	f062                	sd	s8,32(sp)
    80003c58:	ec66                	sd	s9,24(sp)
    80003c5a:	e86a                	sd	s10,16(sp)
    80003c5c:	e46e                	sd	s11,8(sp)
    80003c5e:	1880                	addi	s0,sp,112
    80003c60:	8baa                	mv	s7,a0
    80003c62:	8c2e                	mv	s8,a1
    80003c64:	8ab2                	mv	s5,a2
    80003c66:	84b6                	mv	s1,a3
    80003c68:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c6a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c6c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c6e:	08d76f63          	bltu	a4,a3,80003d0c <readi+0xd0>
  if(off + n > ip->size)
    80003c72:	00e7f463          	bgeu	a5,a4,80003c7a <readi+0x3e>
    n = ip->size - off;
    80003c76:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7a:	0a0b0863          	beqz	s6,80003d2a <readi+0xee>
    80003c7e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c80:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c84:	5cfd                	li	s9,-1
    80003c86:	a82d                	j	80003cc0 <readi+0x84>
    80003c88:	020a1d93          	slli	s11,s4,0x20
    80003c8c:	020ddd93          	srli	s11,s11,0x20
    80003c90:	05890793          	addi	a5,s2,88
    80003c94:	86ee                	mv	a3,s11
    80003c96:	963e                	add	a2,a2,a5
    80003c98:	85d6                	mv	a1,s5
    80003c9a:	8562                	mv	a0,s8
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	b04080e7          	jalr	-1276(ra) # 800027a0 <either_copyout>
    80003ca4:	05950d63          	beq	a0,s9,80003cfe <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	60a080e7          	jalr	1546(ra) # 800032b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb2:	013a09bb          	addw	s3,s4,s3
    80003cb6:	009a04bb          	addw	s1,s4,s1
    80003cba:	9aee                	add	s5,s5,s11
    80003cbc:	0569f663          	bgeu	s3,s6,80003d08 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc0:	000ba903          	lw	s2,0(s7)
    80003cc4:	00a4d59b          	srliw	a1,s1,0xa
    80003cc8:	855e                	mv	a0,s7
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	8ae080e7          	jalr	-1874(ra) # 80003578 <bmap>
    80003cd2:	0005059b          	sext.w	a1,a0
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	4ac080e7          	jalr	1196(ra) # 80003184 <bread>
    80003ce0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	3ff4f613          	andi	a2,s1,1023
    80003ce6:	40cd07bb          	subw	a5,s10,a2
    80003cea:	413b073b          	subw	a4,s6,s3
    80003cee:	8a3e                	mv	s4,a5
    80003cf0:	2781                	sext.w	a5,a5
    80003cf2:	0007069b          	sext.w	a3,a4
    80003cf6:	f8f6f9e3          	bgeu	a3,a5,80003c88 <readi+0x4c>
    80003cfa:	8a3a                	mv	s4,a4
    80003cfc:	b771                	j	80003c88 <readi+0x4c>
      brelse(bp);
    80003cfe:	854a                	mv	a0,s2
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	5b4080e7          	jalr	1460(ra) # 800032b4 <brelse>
  }
  return tot;
    80003d08:	0009851b          	sext.w	a0,s3
}
    80003d0c:	70a6                	ld	ra,104(sp)
    80003d0e:	7406                	ld	s0,96(sp)
    80003d10:	64e6                	ld	s1,88(sp)
    80003d12:	6946                	ld	s2,80(sp)
    80003d14:	69a6                	ld	s3,72(sp)
    80003d16:	6a06                	ld	s4,64(sp)
    80003d18:	7ae2                	ld	s5,56(sp)
    80003d1a:	7b42                	ld	s6,48(sp)
    80003d1c:	7ba2                	ld	s7,40(sp)
    80003d1e:	7c02                	ld	s8,32(sp)
    80003d20:	6ce2                	ld	s9,24(sp)
    80003d22:	6d42                	ld	s10,16(sp)
    80003d24:	6da2                	ld	s11,8(sp)
    80003d26:	6165                	addi	sp,sp,112
    80003d28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2a:	89da                	mv	s3,s6
    80003d2c:	bff1                	j	80003d08 <readi+0xcc>
    return 0;
    80003d2e:	4501                	li	a0,0
}
    80003d30:	8082                	ret

0000000080003d32 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d32:	457c                	lw	a5,76(a0)
    80003d34:	10d7e663          	bltu	a5,a3,80003e40 <writei+0x10e>
{
    80003d38:	7159                	addi	sp,sp,-112
    80003d3a:	f486                	sd	ra,104(sp)
    80003d3c:	f0a2                	sd	s0,96(sp)
    80003d3e:	eca6                	sd	s1,88(sp)
    80003d40:	e8ca                	sd	s2,80(sp)
    80003d42:	e4ce                	sd	s3,72(sp)
    80003d44:	e0d2                	sd	s4,64(sp)
    80003d46:	fc56                	sd	s5,56(sp)
    80003d48:	f85a                	sd	s6,48(sp)
    80003d4a:	f45e                	sd	s7,40(sp)
    80003d4c:	f062                	sd	s8,32(sp)
    80003d4e:	ec66                	sd	s9,24(sp)
    80003d50:	e86a                	sd	s10,16(sp)
    80003d52:	e46e                	sd	s11,8(sp)
    80003d54:	1880                	addi	s0,sp,112
    80003d56:	8baa                	mv	s7,a0
    80003d58:	8c2e                	mv	s8,a1
    80003d5a:	8ab2                	mv	s5,a2
    80003d5c:	8936                	mv	s2,a3
    80003d5e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d60:	00e687bb          	addw	a5,a3,a4
    80003d64:	0ed7e063          	bltu	a5,a3,80003e44 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d68:	00043737          	lui	a4,0x43
    80003d6c:	0cf76e63          	bltu	a4,a5,80003e48 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d70:	0a0b0763          	beqz	s6,80003e1e <writei+0xec>
    80003d74:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d76:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d7a:	5cfd                	li	s9,-1
    80003d7c:	a091                	j	80003dc0 <writei+0x8e>
    80003d7e:	02099d93          	slli	s11,s3,0x20
    80003d82:	020ddd93          	srli	s11,s11,0x20
    80003d86:	05848793          	addi	a5,s1,88
    80003d8a:	86ee                	mv	a3,s11
    80003d8c:	8656                	mv	a2,s5
    80003d8e:	85e2                	mv	a1,s8
    80003d90:	953e                	add	a0,a0,a5
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	a64080e7          	jalr	-1436(ra) # 800027f6 <either_copyin>
    80003d9a:	07950263          	beq	a0,s9,80003dfe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d9e:	8526                	mv	a0,s1
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	77e080e7          	jalr	1918(ra) # 8000451e <log_write>
    brelse(bp);
    80003da8:	8526                	mv	a0,s1
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	50a080e7          	jalr	1290(ra) # 800032b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db2:	01498a3b          	addw	s4,s3,s4
    80003db6:	0129893b          	addw	s2,s3,s2
    80003dba:	9aee                	add	s5,s5,s11
    80003dbc:	056a7663          	bgeu	s4,s6,80003e08 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dc0:	000ba483          	lw	s1,0(s7)
    80003dc4:	00a9559b          	srliw	a1,s2,0xa
    80003dc8:	855e                	mv	a0,s7
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	7ae080e7          	jalr	1966(ra) # 80003578 <bmap>
    80003dd2:	0005059b          	sext.w	a1,a0
    80003dd6:	8526                	mv	a0,s1
    80003dd8:	fffff097          	auipc	ra,0xfffff
    80003ddc:	3ac080e7          	jalr	940(ra) # 80003184 <bread>
    80003de0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de2:	3ff97513          	andi	a0,s2,1023
    80003de6:	40ad07bb          	subw	a5,s10,a0
    80003dea:	414b073b          	subw	a4,s6,s4
    80003dee:	89be                	mv	s3,a5
    80003df0:	2781                	sext.w	a5,a5
    80003df2:	0007069b          	sext.w	a3,a4
    80003df6:	f8f6f4e3          	bgeu	a3,a5,80003d7e <writei+0x4c>
    80003dfa:	89ba                	mv	s3,a4
    80003dfc:	b749                	j	80003d7e <writei+0x4c>
      brelse(bp);
    80003dfe:	8526                	mv	a0,s1
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	4b4080e7          	jalr	1204(ra) # 800032b4 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e08:	04cba783          	lw	a5,76(s7)
    80003e0c:	0127f463          	bgeu	a5,s2,80003e14 <writei+0xe2>
      ip->size = off;
    80003e10:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e14:	855e                	mv	a0,s7
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	aa8080e7          	jalr	-1368(ra) # 800038be <iupdate>
  }

  return n;
    80003e1e:	000b051b          	sext.w	a0,s6
}
    80003e22:	70a6                	ld	ra,104(sp)
    80003e24:	7406                	ld	s0,96(sp)
    80003e26:	64e6                	ld	s1,88(sp)
    80003e28:	6946                	ld	s2,80(sp)
    80003e2a:	69a6                	ld	s3,72(sp)
    80003e2c:	6a06                	ld	s4,64(sp)
    80003e2e:	7ae2                	ld	s5,56(sp)
    80003e30:	7b42                	ld	s6,48(sp)
    80003e32:	7ba2                	ld	s7,40(sp)
    80003e34:	7c02                	ld	s8,32(sp)
    80003e36:	6ce2                	ld	s9,24(sp)
    80003e38:	6d42                	ld	s10,16(sp)
    80003e3a:	6da2                	ld	s11,8(sp)
    80003e3c:	6165                	addi	sp,sp,112
    80003e3e:	8082                	ret
    return -1;
    80003e40:	557d                	li	a0,-1
}
    80003e42:	8082                	ret
    return -1;
    80003e44:	557d                	li	a0,-1
    80003e46:	bff1                	j	80003e22 <writei+0xf0>
    return -1;
    80003e48:	557d                	li	a0,-1
    80003e4a:	bfe1                	j	80003e22 <writei+0xf0>

0000000080003e4c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e4c:	1141                	addi	sp,sp,-16
    80003e4e:	e406                	sd	ra,8(sp)
    80003e50:	e022                	sd	s0,0(sp)
    80003e52:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e54:	4639                	li	a2,14
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	f7a080e7          	jalr	-134(ra) # 80000dd0 <strncmp>
}
    80003e5e:	60a2                	ld	ra,8(sp)
    80003e60:	6402                	ld	s0,0(sp)
    80003e62:	0141                	addi	sp,sp,16
    80003e64:	8082                	ret

0000000080003e66 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e76:	04451703          	lh	a4,68(a0)
    80003e7a:	4785                	li	a5,1
    80003e7c:	00f71a63          	bne	a4,a5,80003e90 <dirlookup+0x2a>
    80003e80:	892a                	mv	s2,a0
    80003e82:	89ae                	mv	s3,a1
    80003e84:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e86:	457c                	lw	a5,76(a0)
    80003e88:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e8a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8c:	e79d                	bnez	a5,80003eba <dirlookup+0x54>
    80003e8e:	a8a5                	j	80003f06 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e90:	00004517          	auipc	a0,0x4
    80003e94:	78850513          	addi	a0,a0,1928 # 80008618 <syscalls+0x1a0>
    80003e98:	ffffc097          	auipc	ra,0xffffc
    80003e9c:	6a8080e7          	jalr	1704(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ea0:	00004517          	auipc	a0,0x4
    80003ea4:	79050513          	addi	a0,a0,1936 # 80008630 <syscalls+0x1b8>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	698080e7          	jalr	1688(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	24c1                	addiw	s1,s1,16
    80003eb2:	04c92783          	lw	a5,76(s2)
    80003eb6:	04f4f763          	bgeu	s1,a5,80003f04 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eba:	4741                	li	a4,16
    80003ebc:	86a6                	mv	a3,s1
    80003ebe:	fc040613          	addi	a2,s0,-64
    80003ec2:	4581                	li	a1,0
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	d76080e7          	jalr	-650(ra) # 80003c3c <readi>
    80003ece:	47c1                	li	a5,16
    80003ed0:	fcf518e3          	bne	a0,a5,80003ea0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed4:	fc045783          	lhu	a5,-64(s0)
    80003ed8:	dfe1                	beqz	a5,80003eb0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eda:	fc240593          	addi	a1,s0,-62
    80003ede:	854e                	mv	a0,s3
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	f6c080e7          	jalr	-148(ra) # 80003e4c <namecmp>
    80003ee8:	f561                	bnez	a0,80003eb0 <dirlookup+0x4a>
      if(poff)
    80003eea:	000a0463          	beqz	s4,80003ef2 <dirlookup+0x8c>
        *poff = off;
    80003eee:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef2:	fc045583          	lhu	a1,-64(s0)
    80003ef6:	00092503          	lw	a0,0(s2)
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	75a080e7          	jalr	1882(ra) # 80003654 <iget>
    80003f02:	a011                	j	80003f06 <dirlookup+0xa0>
  return 0;
    80003f04:	4501                	li	a0,0
}
    80003f06:	70e2                	ld	ra,56(sp)
    80003f08:	7442                	ld	s0,48(sp)
    80003f0a:	74a2                	ld	s1,40(sp)
    80003f0c:	7902                	ld	s2,32(sp)
    80003f0e:	69e2                	ld	s3,24(sp)
    80003f10:	6a42                	ld	s4,16(sp)
    80003f12:	6121                	addi	sp,sp,64
    80003f14:	8082                	ret

0000000080003f16 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f16:	711d                	addi	sp,sp,-96
    80003f18:	ec86                	sd	ra,88(sp)
    80003f1a:	e8a2                	sd	s0,80(sp)
    80003f1c:	e4a6                	sd	s1,72(sp)
    80003f1e:	e0ca                	sd	s2,64(sp)
    80003f20:	fc4e                	sd	s3,56(sp)
    80003f22:	f852                	sd	s4,48(sp)
    80003f24:	f456                	sd	s5,40(sp)
    80003f26:	f05a                	sd	s6,32(sp)
    80003f28:	ec5e                	sd	s7,24(sp)
    80003f2a:	e862                	sd	s8,16(sp)
    80003f2c:	e466                	sd	s9,8(sp)
    80003f2e:	1080                	addi	s0,sp,96
    80003f30:	84aa                	mv	s1,a0
    80003f32:	8aae                	mv	s5,a1
    80003f34:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f36:	00054703          	lbu	a4,0(a0)
    80003f3a:	02f00793          	li	a5,47
    80003f3e:	02f70363          	beq	a4,a5,80003f64 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f42:	ffffe097          	auipc	ra,0xffffe
    80003f46:	bac080e7          	jalr	-1108(ra) # 80001aee <myproc>
    80003f4a:	15053503          	ld	a0,336(a0)
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	9fc080e7          	jalr	-1540(ra) # 8000394a <idup>
    80003f56:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f58:	02f00913          	li	s2,47
  len = path - s;
    80003f5c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f5e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f60:	4b85                	li	s7,1
    80003f62:	a865                	j	8000401a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f64:	4585                	li	a1,1
    80003f66:	4505                	li	a0,1
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	6ec080e7          	jalr	1772(ra) # 80003654 <iget>
    80003f70:	89aa                	mv	s3,a0
    80003f72:	b7dd                	j	80003f58 <namex+0x42>
      iunlockput(ip);
    80003f74:	854e                	mv	a0,s3
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	c74080e7          	jalr	-908(ra) # 80003bea <iunlockput>
      return 0;
    80003f7e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f80:	854e                	mv	a0,s3
    80003f82:	60e6                	ld	ra,88(sp)
    80003f84:	6446                	ld	s0,80(sp)
    80003f86:	64a6                	ld	s1,72(sp)
    80003f88:	6906                	ld	s2,64(sp)
    80003f8a:	79e2                	ld	s3,56(sp)
    80003f8c:	7a42                	ld	s4,48(sp)
    80003f8e:	7aa2                	ld	s5,40(sp)
    80003f90:	7b02                	ld	s6,32(sp)
    80003f92:	6be2                	ld	s7,24(sp)
    80003f94:	6c42                	ld	s8,16(sp)
    80003f96:	6ca2                	ld	s9,8(sp)
    80003f98:	6125                	addi	sp,sp,96
    80003f9a:	8082                	ret
      iunlock(ip);
    80003f9c:	854e                	mv	a0,s3
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	aac080e7          	jalr	-1364(ra) # 80003a4a <iunlock>
      return ip;
    80003fa6:	bfe9                	j	80003f80 <namex+0x6a>
      iunlockput(ip);
    80003fa8:	854e                	mv	a0,s3
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	c40080e7          	jalr	-960(ra) # 80003bea <iunlockput>
      return 0;
    80003fb2:	89e6                	mv	s3,s9
    80003fb4:	b7f1                	j	80003f80 <namex+0x6a>
  len = path - s;
    80003fb6:	40b48633          	sub	a2,s1,a1
    80003fba:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fbe:	099c5463          	bge	s8,s9,80004046 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc2:	4639                	li	a2,14
    80003fc4:	8552                	mv	a0,s4
    80003fc6:	ffffd097          	auipc	ra,0xffffd
    80003fca:	d8e080e7          	jalr	-626(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	01279763          	bne	a5,s2,80003fe0 <namex+0xca>
    path++;
    80003fd6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd8:	0004c783          	lbu	a5,0(s1)
    80003fdc:	ff278de3          	beq	a5,s2,80003fd6 <namex+0xc0>
    ilock(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	9a6080e7          	jalr	-1626(ra) # 80003988 <ilock>
    if(ip->type != T_DIR){
    80003fea:	04499783          	lh	a5,68(s3)
    80003fee:	f97793e3          	bne	a5,s7,80003f74 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff2:	000a8563          	beqz	s5,80003ffc <namex+0xe6>
    80003ff6:	0004c783          	lbu	a5,0(s1)
    80003ffa:	d3cd                	beqz	a5,80003f9c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ffc:	865a                	mv	a2,s6
    80003ffe:	85d2                	mv	a1,s4
    80004000:	854e                	mv	a0,s3
    80004002:	00000097          	auipc	ra,0x0
    80004006:	e64080e7          	jalr	-412(ra) # 80003e66 <dirlookup>
    8000400a:	8caa                	mv	s9,a0
    8000400c:	dd51                	beqz	a0,80003fa8 <namex+0x92>
    iunlockput(ip);
    8000400e:	854e                	mv	a0,s3
    80004010:	00000097          	auipc	ra,0x0
    80004014:	bda080e7          	jalr	-1062(ra) # 80003bea <iunlockput>
    ip = next;
    80004018:	89e6                	mv	s3,s9
  while(*path == '/')
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	05279763          	bne	a5,s2,8000406c <namex+0x156>
    path++;
    80004022:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004024:	0004c783          	lbu	a5,0(s1)
    80004028:	ff278de3          	beq	a5,s2,80004022 <namex+0x10c>
  if(*path == 0)
    8000402c:	c79d                	beqz	a5,8000405a <namex+0x144>
    path++;
    8000402e:	85a6                	mv	a1,s1
  len = path - s;
    80004030:	8cda                	mv	s9,s6
    80004032:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004034:	01278963          	beq	a5,s2,80004046 <namex+0x130>
    80004038:	dfbd                	beqz	a5,80003fb6 <namex+0xa0>
    path++;
    8000403a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000403c:	0004c783          	lbu	a5,0(s1)
    80004040:	ff279ce3          	bne	a5,s2,80004038 <namex+0x122>
    80004044:	bf8d                	j	80003fb6 <namex+0xa0>
    memmove(name, s, len);
    80004046:	2601                	sext.w	a2,a2
    80004048:	8552                	mv	a0,s4
    8000404a:	ffffd097          	auipc	ra,0xffffd
    8000404e:	d0a080e7          	jalr	-758(ra) # 80000d54 <memmove>
    name[len] = 0;
    80004052:	9cd2                	add	s9,s9,s4
    80004054:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004058:	bf9d                	j	80003fce <namex+0xb8>
  if(nameiparent){
    8000405a:	f20a83e3          	beqz	s5,80003f80 <namex+0x6a>
    iput(ip);
    8000405e:	854e                	mv	a0,s3
    80004060:	00000097          	auipc	ra,0x0
    80004064:	ae2080e7          	jalr	-1310(ra) # 80003b42 <iput>
    return 0;
    80004068:	4981                	li	s3,0
    8000406a:	bf19                	j	80003f80 <namex+0x6a>
  if(*path == 0)
    8000406c:	d7fd                	beqz	a5,8000405a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000406e:	0004c783          	lbu	a5,0(s1)
    80004072:	85a6                	mv	a1,s1
    80004074:	b7d1                	j	80004038 <namex+0x122>

0000000080004076 <dirlink>:
{
    80004076:	7139                	addi	sp,sp,-64
    80004078:	fc06                	sd	ra,56(sp)
    8000407a:	f822                	sd	s0,48(sp)
    8000407c:	f426                	sd	s1,40(sp)
    8000407e:	f04a                	sd	s2,32(sp)
    80004080:	ec4e                	sd	s3,24(sp)
    80004082:	e852                	sd	s4,16(sp)
    80004084:	0080                	addi	s0,sp,64
    80004086:	892a                	mv	s2,a0
    80004088:	8a2e                	mv	s4,a1
    8000408a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000408c:	4601                	li	a2,0
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	dd8080e7          	jalr	-552(ra) # 80003e66 <dirlookup>
    80004096:	e93d                	bnez	a0,8000410c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004098:	04c92483          	lw	s1,76(s2)
    8000409c:	c49d                	beqz	s1,800040ca <dirlink+0x54>
    8000409e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a0:	4741                	li	a4,16
    800040a2:	86a6                	mv	a3,s1
    800040a4:	fc040613          	addi	a2,s0,-64
    800040a8:	4581                	li	a1,0
    800040aa:	854a                	mv	a0,s2
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	b90080e7          	jalr	-1136(ra) # 80003c3c <readi>
    800040b4:	47c1                	li	a5,16
    800040b6:	06f51163          	bne	a0,a5,80004118 <dirlink+0xa2>
    if(de.inum == 0)
    800040ba:	fc045783          	lhu	a5,-64(s0)
    800040be:	c791                	beqz	a5,800040ca <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c0:	24c1                	addiw	s1,s1,16
    800040c2:	04c92783          	lw	a5,76(s2)
    800040c6:	fcf4ede3          	bltu	s1,a5,800040a0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ca:	4639                	li	a2,14
    800040cc:	85d2                	mv	a1,s4
    800040ce:	fc240513          	addi	a0,s0,-62
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	d3a080e7          	jalr	-710(ra) # 80000e0c <strncpy>
  de.inum = inum;
    800040da:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040de:	4741                	li	a4,16
    800040e0:	86a6                	mv	a3,s1
    800040e2:	fc040613          	addi	a2,s0,-64
    800040e6:	4581                	li	a1,0
    800040e8:	854a                	mv	a0,s2
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	c48080e7          	jalr	-952(ra) # 80003d32 <writei>
    800040f2:	872a                	mv	a4,a0
    800040f4:	47c1                	li	a5,16
  return 0;
    800040f6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f8:	02f71863          	bne	a4,a5,80004128 <dirlink+0xb2>
}
    800040fc:	70e2                	ld	ra,56(sp)
    800040fe:	7442                	ld	s0,48(sp)
    80004100:	74a2                	ld	s1,40(sp)
    80004102:	7902                	ld	s2,32(sp)
    80004104:	69e2                	ld	s3,24(sp)
    80004106:	6a42                	ld	s4,16(sp)
    80004108:	6121                	addi	sp,sp,64
    8000410a:	8082                	ret
    iput(ip);
    8000410c:	00000097          	auipc	ra,0x0
    80004110:	a36080e7          	jalr	-1482(ra) # 80003b42 <iput>
    return -1;
    80004114:	557d                	li	a0,-1
    80004116:	b7dd                	j	800040fc <dirlink+0x86>
      panic("dirlink read");
    80004118:	00004517          	auipc	a0,0x4
    8000411c:	52850513          	addi	a0,a0,1320 # 80008640 <syscalls+0x1c8>
    80004120:	ffffc097          	auipc	ra,0xffffc
    80004124:	420080e7          	jalr	1056(ra) # 80000540 <panic>
    panic("dirlink");
    80004128:	00004517          	auipc	a0,0x4
    8000412c:	63850513          	addi	a0,a0,1592 # 80008760 <syscalls+0x2e8>
    80004130:	ffffc097          	auipc	ra,0xffffc
    80004134:	410080e7          	jalr	1040(ra) # 80000540 <panic>

0000000080004138 <namei>:

struct inode*
namei(char *path)
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004140:	fe040613          	addi	a2,s0,-32
    80004144:	4581                	li	a1,0
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	dd0080e7          	jalr	-560(ra) # 80003f16 <namex>
}
    8000414e:	60e2                	ld	ra,24(sp)
    80004150:	6442                	ld	s0,16(sp)
    80004152:	6105                	addi	sp,sp,32
    80004154:	8082                	ret

0000000080004156 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004156:	1141                	addi	sp,sp,-16
    80004158:	e406                	sd	ra,8(sp)
    8000415a:	e022                	sd	s0,0(sp)
    8000415c:	0800                	addi	s0,sp,16
    8000415e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004160:	4585                	li	a1,1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	db4080e7          	jalr	-588(ra) # 80003f16 <namex>
}
    8000416a:	60a2                	ld	ra,8(sp)
    8000416c:	6402                	ld	s0,0(sp)
    8000416e:	0141                	addi	sp,sp,16
    80004170:	8082                	ret

0000000080004172 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004172:	1101                	addi	sp,sp,-32
    80004174:	ec06                	sd	ra,24(sp)
    80004176:	e822                	sd	s0,16(sp)
    80004178:	e426                	sd	s1,8(sp)
    8000417a:	e04a                	sd	s2,0(sp)
    8000417c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000417e:	0001e917          	auipc	s2,0x1e
    80004182:	48a90913          	addi	s2,s2,1162 # 80022608 <log>
    80004186:	01892583          	lw	a1,24(s2)
    8000418a:	02892503          	lw	a0,40(s2)
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	ff6080e7          	jalr	-10(ra) # 80003184 <bread>
    80004196:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004198:	02c92683          	lw	a3,44(s2)
    8000419c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000419e:	02d05863          	blez	a3,800041ce <write_head+0x5c>
    800041a2:	0001e797          	auipc	a5,0x1e
    800041a6:	49678793          	addi	a5,a5,1174 # 80022638 <log+0x30>
    800041aa:	05c50713          	addi	a4,a0,92
    800041ae:	36fd                	addiw	a3,a3,-1
    800041b0:	02069613          	slli	a2,a3,0x20
    800041b4:	01e65693          	srli	a3,a2,0x1e
    800041b8:	0001e617          	auipc	a2,0x1e
    800041bc:	48460613          	addi	a2,a2,1156 # 8002263c <log+0x34>
    800041c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041c2:	4390                	lw	a2,0(a5)
    800041c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c6:	0791                	addi	a5,a5,4
    800041c8:	0711                	addi	a4,a4,4
    800041ca:	fed79ce3          	bne	a5,a3,800041c2 <write_head+0x50>
  }
  bwrite(buf);
    800041ce:	8526                	mv	a0,s1
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	0a6080e7          	jalr	166(ra) # 80003276 <bwrite>
  brelse(buf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	0da080e7          	jalr	218(ra) # 800032b4 <brelse>
}
    800041e2:	60e2                	ld	ra,24(sp)
    800041e4:	6442                	ld	s0,16(sp)
    800041e6:	64a2                	ld	s1,8(sp)
    800041e8:	6902                	ld	s2,0(sp)
    800041ea:	6105                	addi	sp,sp,32
    800041ec:	8082                	ret

00000000800041ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ee:	0001e797          	auipc	a5,0x1e
    800041f2:	4467a783          	lw	a5,1094(a5) # 80022634 <log+0x2c>
    800041f6:	0af05663          	blez	a5,800042a2 <install_trans+0xb4>
{
    800041fa:	7139                	addi	sp,sp,-64
    800041fc:	fc06                	sd	ra,56(sp)
    800041fe:	f822                	sd	s0,48(sp)
    80004200:	f426                	sd	s1,40(sp)
    80004202:	f04a                	sd	s2,32(sp)
    80004204:	ec4e                	sd	s3,24(sp)
    80004206:	e852                	sd	s4,16(sp)
    80004208:	e456                	sd	s5,8(sp)
    8000420a:	0080                	addi	s0,sp,64
    8000420c:	0001ea97          	auipc	s5,0x1e
    80004210:	42ca8a93          	addi	s5,s5,1068 # 80022638 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004216:	0001e997          	auipc	s3,0x1e
    8000421a:	3f298993          	addi	s3,s3,1010 # 80022608 <log>
    8000421e:	0189a583          	lw	a1,24(s3)
    80004222:	014585bb          	addw	a1,a1,s4
    80004226:	2585                	addiw	a1,a1,1
    80004228:	0289a503          	lw	a0,40(s3)
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	f58080e7          	jalr	-168(ra) # 80003184 <bread>
    80004234:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004236:	000aa583          	lw	a1,0(s5)
    8000423a:	0289a503          	lw	a0,40(s3)
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	f46080e7          	jalr	-186(ra) # 80003184 <bread>
    80004246:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004248:	40000613          	li	a2,1024
    8000424c:	05890593          	addi	a1,s2,88
    80004250:	05850513          	addi	a0,a0,88
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	b00080e7          	jalr	-1280(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000425c:	8526                	mv	a0,s1
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	018080e7          	jalr	24(ra) # 80003276 <bwrite>
    bunpin(dbuf);
    80004266:	8526                	mv	a0,s1
    80004268:	fffff097          	auipc	ra,0xfffff
    8000426c:	126080e7          	jalr	294(ra) # 8000338e <bunpin>
    brelse(lbuf);
    80004270:	854a                	mv	a0,s2
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	042080e7          	jalr	66(ra) # 800032b4 <brelse>
    brelse(dbuf);
    8000427a:	8526                	mv	a0,s1
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	038080e7          	jalr	56(ra) # 800032b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004284:	2a05                	addiw	s4,s4,1
    80004286:	0a91                	addi	s5,s5,4
    80004288:	02c9a783          	lw	a5,44(s3)
    8000428c:	f8fa49e3          	blt	s4,a5,8000421e <install_trans+0x30>
}
    80004290:	70e2                	ld	ra,56(sp)
    80004292:	7442                	ld	s0,48(sp)
    80004294:	74a2                	ld	s1,40(sp)
    80004296:	7902                	ld	s2,32(sp)
    80004298:	69e2                	ld	s3,24(sp)
    8000429a:	6a42                	ld	s4,16(sp)
    8000429c:	6aa2                	ld	s5,8(sp)
    8000429e:	6121                	addi	sp,sp,64
    800042a0:	8082                	ret
    800042a2:	8082                	ret

00000000800042a4 <initlog>:
{
    800042a4:	7179                	addi	sp,sp,-48
    800042a6:	f406                	sd	ra,40(sp)
    800042a8:	f022                	sd	s0,32(sp)
    800042aa:	ec26                	sd	s1,24(sp)
    800042ac:	e84a                	sd	s2,16(sp)
    800042ae:	e44e                	sd	s3,8(sp)
    800042b0:	1800                	addi	s0,sp,48
    800042b2:	892a                	mv	s2,a0
    800042b4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b6:	0001e497          	auipc	s1,0x1e
    800042ba:	35248493          	addi	s1,s1,850 # 80022608 <log>
    800042be:	00004597          	auipc	a1,0x4
    800042c2:	39258593          	addi	a1,a1,914 # 80008650 <syscalls+0x1d8>
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	8a4080e7          	jalr	-1884(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800042d0:	0149a583          	lw	a1,20(s3)
    800042d4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d6:	0109a783          	lw	a5,16(s3)
    800042da:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042dc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042e0:	854a                	mv	a0,s2
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	ea2080e7          	jalr	-350(ra) # 80003184 <bread>
  log.lh.n = lh->n;
    800042ea:	4d34                	lw	a3,88(a0)
    800042ec:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ee:	02d05663          	blez	a3,8000431a <initlog+0x76>
    800042f2:	05c50793          	addi	a5,a0,92
    800042f6:	0001e717          	auipc	a4,0x1e
    800042fa:	34270713          	addi	a4,a4,834 # 80022638 <log+0x30>
    800042fe:	36fd                	addiw	a3,a3,-1
    80004300:	02069613          	slli	a2,a3,0x20
    80004304:	01e65693          	srli	a3,a2,0x1e
    80004308:	06050613          	addi	a2,a0,96
    8000430c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000430e:	4390                	lw	a2,0(a5)
    80004310:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004312:	0791                	addi	a5,a5,4
    80004314:	0711                	addi	a4,a4,4
    80004316:	fed79ce3          	bne	a5,a3,8000430e <initlog+0x6a>
  brelse(buf);
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	f9a080e7          	jalr	-102(ra) # 800032b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004322:	00000097          	auipc	ra,0x0
    80004326:	ecc080e7          	jalr	-308(ra) # 800041ee <install_trans>
  log.lh.n = 0;
    8000432a:	0001e797          	auipc	a5,0x1e
    8000432e:	3007a523          	sw	zero,778(a5) # 80022634 <log+0x2c>
  write_head(); // clear the log
    80004332:	00000097          	auipc	ra,0x0
    80004336:	e40080e7          	jalr	-448(ra) # 80004172 <write_head>
}
    8000433a:	70a2                	ld	ra,40(sp)
    8000433c:	7402                	ld	s0,32(sp)
    8000433e:	64e2                	ld	s1,24(sp)
    80004340:	6942                	ld	s2,16(sp)
    80004342:	69a2                	ld	s3,8(sp)
    80004344:	6145                	addi	sp,sp,48
    80004346:	8082                	ret

0000000080004348 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004354:	0001e517          	auipc	a0,0x1e
    80004358:	2b450513          	addi	a0,a0,692 # 80022608 <log>
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	8a0080e7          	jalr	-1888(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004364:	0001e497          	auipc	s1,0x1e
    80004368:	2a448493          	addi	s1,s1,676 # 80022608 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436c:	4979                	li	s2,30
    8000436e:	a039                	j	8000437c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004370:	85a6                	mv	a1,s1
    80004372:	8526                	mv	a0,s1
    80004374:	ffffe097          	auipc	ra,0xffffe
    80004378:	1b6080e7          	jalr	438(ra) # 8000252a <sleep>
    if(log.committing){
    8000437c:	50dc                	lw	a5,36(s1)
    8000437e:	fbed                	bnez	a5,80004370 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004380:	509c                	lw	a5,32(s1)
    80004382:	0017871b          	addiw	a4,a5,1
    80004386:	0007069b          	sext.w	a3,a4
    8000438a:	0027179b          	slliw	a5,a4,0x2
    8000438e:	9fb9                	addw	a5,a5,a4
    80004390:	0017979b          	slliw	a5,a5,0x1
    80004394:	54d8                	lw	a4,44(s1)
    80004396:	9fb9                	addw	a5,a5,a4
    80004398:	00f95963          	bge	s2,a5,800043aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000439c:	85a6                	mv	a1,s1
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	18a080e7          	jalr	394(ra) # 8000252a <sleep>
    800043a8:	bfd1                	j	8000437c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043aa:	0001e517          	auipc	a0,0x1e
    800043ae:	25e50513          	addi	a0,a0,606 # 80022608 <log>
    800043b2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b4:	ffffd097          	auipc	ra,0xffffd
    800043b8:	8fc080e7          	jalr	-1796(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800043bc:	60e2                	ld	ra,24(sp)
    800043be:	6442                	ld	s0,16(sp)
    800043c0:	64a2                	ld	s1,8(sp)
    800043c2:	6902                	ld	s2,0(sp)
    800043c4:	6105                	addi	sp,sp,32
    800043c6:	8082                	ret

00000000800043c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c8:	7139                	addi	sp,sp,-64
    800043ca:	fc06                	sd	ra,56(sp)
    800043cc:	f822                	sd	s0,48(sp)
    800043ce:	f426                	sd	s1,40(sp)
    800043d0:	f04a                	sd	s2,32(sp)
    800043d2:	ec4e                	sd	s3,24(sp)
    800043d4:	e852                	sd	s4,16(sp)
    800043d6:	e456                	sd	s5,8(sp)
    800043d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043da:	0001e497          	auipc	s1,0x1e
    800043de:	22e48493          	addi	s1,s1,558 # 80022608 <log>
    800043e2:	8526                	mv	a0,s1
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	818080e7          	jalr	-2024(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800043ec:	509c                	lw	a5,32(s1)
    800043ee:	37fd                	addiw	a5,a5,-1
    800043f0:	0007891b          	sext.w	s2,a5
    800043f4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f6:	50dc                	lw	a5,36(s1)
    800043f8:	e7b9                	bnez	a5,80004446 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043fa:	04091e63          	bnez	s2,80004456 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043fe:	0001e497          	auipc	s1,0x1e
    80004402:	20a48493          	addi	s1,s1,522 # 80022608 <log>
    80004406:	4785                	li	a5,1
    80004408:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	8a4080e7          	jalr	-1884(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004414:	54dc                	lw	a5,44(s1)
    80004416:	06f04763          	bgtz	a5,80004484 <end_op+0xbc>
    acquire(&log.lock);
    8000441a:	0001e497          	auipc	s1,0x1e
    8000441e:	1ee48493          	addi	s1,s1,494 # 80022608 <log>
    80004422:	8526                	mv	a0,s1
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7d8080e7          	jalr	2008(ra) # 80000bfc <acquire>
    log.committing = 0;
    8000442c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004430:	8526                	mv	a0,s1
    80004432:	ffffe097          	auipc	ra,0xffffe
    80004436:	284080e7          	jalr	644(ra) # 800026b6 <wakeup>
    release(&log.lock);
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	874080e7          	jalr	-1932(ra) # 80000cb0 <release>
}
    80004444:	a03d                	j	80004472 <end_op+0xaa>
    panic("log.committing");
    80004446:	00004517          	auipc	a0,0x4
    8000444a:	21250513          	addi	a0,a0,530 # 80008658 <syscalls+0x1e0>
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	0f2080e7          	jalr	242(ra) # 80000540 <panic>
    wakeup(&log);
    80004456:	0001e497          	auipc	s1,0x1e
    8000445a:	1b248493          	addi	s1,s1,434 # 80022608 <log>
    8000445e:	8526                	mv	a0,s1
    80004460:	ffffe097          	auipc	ra,0xffffe
    80004464:	256080e7          	jalr	598(ra) # 800026b6 <wakeup>
  release(&log.lock);
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	846080e7          	jalr	-1978(ra) # 80000cb0 <release>
}
    80004472:	70e2                	ld	ra,56(sp)
    80004474:	7442                	ld	s0,48(sp)
    80004476:	74a2                	ld	s1,40(sp)
    80004478:	7902                	ld	s2,32(sp)
    8000447a:	69e2                	ld	s3,24(sp)
    8000447c:	6a42                	ld	s4,16(sp)
    8000447e:	6aa2                	ld	s5,8(sp)
    80004480:	6121                	addi	sp,sp,64
    80004482:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004484:	0001ea97          	auipc	s5,0x1e
    80004488:	1b4a8a93          	addi	s5,s5,436 # 80022638 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000448c:	0001ea17          	auipc	s4,0x1e
    80004490:	17ca0a13          	addi	s4,s4,380 # 80022608 <log>
    80004494:	018a2583          	lw	a1,24(s4)
    80004498:	012585bb          	addw	a1,a1,s2
    8000449c:	2585                	addiw	a1,a1,1
    8000449e:	028a2503          	lw	a0,40(s4)
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	ce2080e7          	jalr	-798(ra) # 80003184 <bread>
    800044aa:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044ac:	000aa583          	lw	a1,0(s5)
    800044b0:	028a2503          	lw	a0,40(s4)
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	cd0080e7          	jalr	-816(ra) # 80003184 <bread>
    800044bc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044be:	40000613          	li	a2,1024
    800044c2:	05850593          	addi	a1,a0,88
    800044c6:	05848513          	addi	a0,s1,88
    800044ca:	ffffd097          	auipc	ra,0xffffd
    800044ce:	88a080e7          	jalr	-1910(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800044d2:	8526                	mv	a0,s1
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	da2080e7          	jalr	-606(ra) # 80003276 <bwrite>
    brelse(from);
    800044dc:	854e                	mv	a0,s3
    800044de:	fffff097          	auipc	ra,0xfffff
    800044e2:	dd6080e7          	jalr	-554(ra) # 800032b4 <brelse>
    brelse(to);
    800044e6:	8526                	mv	a0,s1
    800044e8:	fffff097          	auipc	ra,0xfffff
    800044ec:	dcc080e7          	jalr	-564(ra) # 800032b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044f0:	2905                	addiw	s2,s2,1
    800044f2:	0a91                	addi	s5,s5,4
    800044f4:	02ca2783          	lw	a5,44(s4)
    800044f8:	f8f94ee3          	blt	s2,a5,80004494 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	c76080e7          	jalr	-906(ra) # 80004172 <write_head>
    install_trans(); // Now install writes to home locations
    80004504:	00000097          	auipc	ra,0x0
    80004508:	cea080e7          	jalr	-790(ra) # 800041ee <install_trans>
    log.lh.n = 0;
    8000450c:	0001e797          	auipc	a5,0x1e
    80004510:	1207a423          	sw	zero,296(a5) # 80022634 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004514:	00000097          	auipc	ra,0x0
    80004518:	c5e080e7          	jalr	-930(ra) # 80004172 <write_head>
    8000451c:	bdfd                	j	8000441a <end_op+0x52>

000000008000451e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451e:	1101                	addi	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	e04a                	sd	s2,0(sp)
    80004528:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000452a:	0001e717          	auipc	a4,0x1e
    8000452e:	10a72703          	lw	a4,266(a4) # 80022634 <log+0x2c>
    80004532:	47f5                	li	a5,29
    80004534:	08e7c063          	blt	a5,a4,800045b4 <log_write+0x96>
    80004538:	84aa                	mv	s1,a0
    8000453a:	0001e797          	auipc	a5,0x1e
    8000453e:	0ea7a783          	lw	a5,234(a5) # 80022624 <log+0x1c>
    80004542:	37fd                	addiw	a5,a5,-1
    80004544:	06f75863          	bge	a4,a5,800045b4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004548:	0001e797          	auipc	a5,0x1e
    8000454c:	0e07a783          	lw	a5,224(a5) # 80022628 <log+0x20>
    80004550:	06f05a63          	blez	a5,800045c4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004554:	0001e917          	auipc	s2,0x1e
    80004558:	0b490913          	addi	s2,s2,180 # 80022608 <log>
    8000455c:	854a                	mv	a0,s2
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	69e080e7          	jalr	1694(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004566:	02c92603          	lw	a2,44(s2)
    8000456a:	06c05563          	blez	a2,800045d4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456e:	44cc                	lw	a1,12(s1)
    80004570:	0001e717          	auipc	a4,0x1e
    80004574:	0c870713          	addi	a4,a4,200 # 80022638 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004578:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000457a:	4314                	lw	a3,0(a4)
    8000457c:	04b68d63          	beq	a3,a1,800045d6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004580:	2785                	addiw	a5,a5,1
    80004582:	0711                	addi	a4,a4,4
    80004584:	fec79be3          	bne	a5,a2,8000457a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004588:	0621                	addi	a2,a2,8
    8000458a:	060a                	slli	a2,a2,0x2
    8000458c:	0001e797          	auipc	a5,0x1e
    80004590:	07c78793          	addi	a5,a5,124 # 80022608 <log>
    80004594:	963e                	add	a2,a2,a5
    80004596:	44dc                	lw	a5,12(s1)
    80004598:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	db6080e7          	jalr	-586(ra) # 80003352 <bpin>
    log.lh.n++;
    800045a4:	0001e717          	auipc	a4,0x1e
    800045a8:	06470713          	addi	a4,a4,100 # 80022608 <log>
    800045ac:	575c                	lw	a5,44(a4)
    800045ae:	2785                	addiw	a5,a5,1
    800045b0:	d75c                	sw	a5,44(a4)
    800045b2:	a83d                	j	800045f0 <log_write+0xd2>
    panic("too big a transaction");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	0b450513          	addi	a0,a0,180 # 80008668 <syscalls+0x1f0>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f84080e7          	jalr	-124(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045c4:	00004517          	auipc	a0,0x4
    800045c8:	0bc50513          	addi	a0,a0,188 # 80008680 <syscalls+0x208>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	f74080e7          	jalr	-140(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d6:	00878713          	addi	a4,a5,8
    800045da:	00271693          	slli	a3,a4,0x2
    800045de:	0001e717          	auipc	a4,0x1e
    800045e2:	02a70713          	addi	a4,a4,42 # 80022608 <log>
    800045e6:	9736                	add	a4,a4,a3
    800045e8:	44d4                	lw	a3,12(s1)
    800045ea:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ec:	faf607e3          	beq	a2,a5,8000459a <log_write+0x7c>
  }
  release(&log.lock);
    800045f0:	0001e517          	auipc	a0,0x1e
    800045f4:	01850513          	addi	a0,a0,24 # 80022608 <log>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	6b8080e7          	jalr	1720(ra) # 80000cb0 <release>
}
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6902                	ld	s2,0(sp)
    80004608:	6105                	addi	sp,sp,32
    8000460a:	8082                	ret

000000008000460c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000460c:	1101                	addi	sp,sp,-32
    8000460e:	ec06                	sd	ra,24(sp)
    80004610:	e822                	sd	s0,16(sp)
    80004612:	e426                	sd	s1,8(sp)
    80004614:	e04a                	sd	s2,0(sp)
    80004616:	1000                	addi	s0,sp,32
    80004618:	84aa                	mv	s1,a0
    8000461a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000461c:	00004597          	auipc	a1,0x4
    80004620:	08458593          	addi	a1,a1,132 # 800086a0 <syscalls+0x228>
    80004624:	0521                	addi	a0,a0,8
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	546080e7          	jalr	1350(ra) # 80000b6c <initlock>
  lk->name = name;
    8000462e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004632:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004636:	0204a423          	sw	zero,40(s1)
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004646:	1101                	addi	sp,sp,-32
    80004648:	ec06                	sd	ra,24(sp)
    8000464a:	e822                	sd	s0,16(sp)
    8000464c:	e426                	sd	s1,8(sp)
    8000464e:	e04a                	sd	s2,0(sp)
    80004650:	1000                	addi	s0,sp,32
    80004652:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004654:	00850913          	addi	s2,a0,8
    80004658:	854a                	mv	a0,s2
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	5a2080e7          	jalr	1442(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004662:	409c                	lw	a5,0(s1)
    80004664:	cb89                	beqz	a5,80004676 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004666:	85ca                	mv	a1,s2
    80004668:	8526                	mv	a0,s1
    8000466a:	ffffe097          	auipc	ra,0xffffe
    8000466e:	ec0080e7          	jalr	-320(ra) # 8000252a <sleep>
  while (lk->locked) {
    80004672:	409c                	lw	a5,0(s1)
    80004674:	fbed                	bnez	a5,80004666 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004676:	4785                	li	a5,1
    80004678:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000467a:	ffffd097          	auipc	ra,0xffffd
    8000467e:	474080e7          	jalr	1140(ra) # 80001aee <myproc>
    80004682:	5d1c                	lw	a5,56(a0)
    80004684:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004686:	854a                	mv	a0,s2
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	628080e7          	jalr	1576(ra) # 80000cb0 <release>
}
    80004690:	60e2                	ld	ra,24(sp)
    80004692:	6442                	ld	s0,16(sp)
    80004694:	64a2                	ld	s1,8(sp)
    80004696:	6902                	ld	s2,0(sp)
    80004698:	6105                	addi	sp,sp,32
    8000469a:	8082                	ret

000000008000469c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000469c:	1101                	addi	sp,sp,-32
    8000469e:	ec06                	sd	ra,24(sp)
    800046a0:	e822                	sd	s0,16(sp)
    800046a2:	e426                	sd	s1,8(sp)
    800046a4:	e04a                	sd	s2,0(sp)
    800046a6:	1000                	addi	s0,sp,32
    800046a8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046aa:	00850913          	addi	s2,a0,8
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	54c080e7          	jalr	1356(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800046b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046bc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffe097          	auipc	ra,0xffffe
    800046c6:	ff4080e7          	jalr	-12(ra) # 800026b6 <wakeup>
  release(&lk->lk);
    800046ca:	854a                	mv	a0,s2
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	5e4080e7          	jalr	1508(ra) # 80000cb0 <release>
}
    800046d4:	60e2                	ld	ra,24(sp)
    800046d6:	6442                	ld	s0,16(sp)
    800046d8:	64a2                	ld	s1,8(sp)
    800046da:	6902                	ld	s2,0(sp)
    800046dc:	6105                	addi	sp,sp,32
    800046de:	8082                	ret

00000000800046e0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046e0:	7179                	addi	sp,sp,-48
    800046e2:	f406                	sd	ra,40(sp)
    800046e4:	f022                	sd	s0,32(sp)
    800046e6:	ec26                	sd	s1,24(sp)
    800046e8:	e84a                	sd	s2,16(sp)
    800046ea:	e44e                	sd	s3,8(sp)
    800046ec:	1800                	addi	s0,sp,48
    800046ee:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046f0:	00850913          	addi	s2,a0,8
    800046f4:	854a                	mv	a0,s2
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	506080e7          	jalr	1286(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fe:	409c                	lw	a5,0(s1)
    80004700:	ef99                	bnez	a5,8000471e <holdingsleep+0x3e>
    80004702:	4481                	li	s1,0
  release(&lk->lk);
    80004704:	854a                	mv	a0,s2
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	5aa080e7          	jalr	1450(ra) # 80000cb0 <release>
  return r;
}
    8000470e:	8526                	mv	a0,s1
    80004710:	70a2                	ld	ra,40(sp)
    80004712:	7402                	ld	s0,32(sp)
    80004714:	64e2                	ld	s1,24(sp)
    80004716:	6942                	ld	s2,16(sp)
    80004718:	69a2                	ld	s3,8(sp)
    8000471a:	6145                	addi	sp,sp,48
    8000471c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000471e:	0284a983          	lw	s3,40(s1)
    80004722:	ffffd097          	auipc	ra,0xffffd
    80004726:	3cc080e7          	jalr	972(ra) # 80001aee <myproc>
    8000472a:	5d04                	lw	s1,56(a0)
    8000472c:	413484b3          	sub	s1,s1,s3
    80004730:	0014b493          	seqz	s1,s1
    80004734:	bfc1                	j	80004704 <holdingsleep+0x24>

0000000080004736 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004736:	1141                	addi	sp,sp,-16
    80004738:	e406                	sd	ra,8(sp)
    8000473a:	e022                	sd	s0,0(sp)
    8000473c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000473e:	00004597          	auipc	a1,0x4
    80004742:	f7258593          	addi	a1,a1,-142 # 800086b0 <syscalls+0x238>
    80004746:	0001e517          	auipc	a0,0x1e
    8000474a:	00a50513          	addi	a0,a0,10 # 80022750 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	41e080e7          	jalr	1054(ra) # 80000b6c <initlock>
}
    80004756:	60a2                	ld	ra,8(sp)
    80004758:	6402                	ld	s0,0(sp)
    8000475a:	0141                	addi	sp,sp,16
    8000475c:	8082                	ret

000000008000475e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000475e:	1101                	addi	sp,sp,-32
    80004760:	ec06                	sd	ra,24(sp)
    80004762:	e822                	sd	s0,16(sp)
    80004764:	e426                	sd	s1,8(sp)
    80004766:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004768:	0001e517          	auipc	a0,0x1e
    8000476c:	fe850513          	addi	a0,a0,-24 # 80022750 <ftable>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	48c080e7          	jalr	1164(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004778:	0001e497          	auipc	s1,0x1e
    8000477c:	ff048493          	addi	s1,s1,-16 # 80022768 <ftable+0x18>
    80004780:	0001f717          	auipc	a4,0x1f
    80004784:	f8870713          	addi	a4,a4,-120 # 80023708 <ftable+0xfb8>
    if(f->ref == 0){
    80004788:	40dc                	lw	a5,4(s1)
    8000478a:	cf99                	beqz	a5,800047a8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000478c:	02848493          	addi	s1,s1,40
    80004790:	fee49ce3          	bne	s1,a4,80004788 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004794:	0001e517          	auipc	a0,0x1e
    80004798:	fbc50513          	addi	a0,a0,-68 # 80022750 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	514080e7          	jalr	1300(ra) # 80000cb0 <release>
  return 0;
    800047a4:	4481                	li	s1,0
    800047a6:	a819                	j	800047bc <filealloc+0x5e>
      f->ref = 1;
    800047a8:	4785                	li	a5,1
    800047aa:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047ac:	0001e517          	auipc	a0,0x1e
    800047b0:	fa450513          	addi	a0,a0,-92 # 80022750 <ftable>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	4fc080e7          	jalr	1276(ra) # 80000cb0 <release>
}
    800047bc:	8526                	mv	a0,s1
    800047be:	60e2                	ld	ra,24(sp)
    800047c0:	6442                	ld	s0,16(sp)
    800047c2:	64a2                	ld	s1,8(sp)
    800047c4:	6105                	addi	sp,sp,32
    800047c6:	8082                	ret

00000000800047c8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c8:	1101                	addi	sp,sp,-32
    800047ca:	ec06                	sd	ra,24(sp)
    800047cc:	e822                	sd	s0,16(sp)
    800047ce:	e426                	sd	s1,8(sp)
    800047d0:	1000                	addi	s0,sp,32
    800047d2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d4:	0001e517          	auipc	a0,0x1e
    800047d8:	f7c50513          	addi	a0,a0,-132 # 80022750 <ftable>
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	420080e7          	jalr	1056(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047e4:	40dc                	lw	a5,4(s1)
    800047e6:	02f05263          	blez	a5,8000480a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ea:	2785                	addiw	a5,a5,1
    800047ec:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ee:	0001e517          	auipc	a0,0x1e
    800047f2:	f6250513          	addi	a0,a0,-158 # 80022750 <ftable>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	4ba080e7          	jalr	1210(ra) # 80000cb0 <release>
  return f;
}
    800047fe:	8526                	mv	a0,s1
    80004800:	60e2                	ld	ra,24(sp)
    80004802:	6442                	ld	s0,16(sp)
    80004804:	64a2                	ld	s1,8(sp)
    80004806:	6105                	addi	sp,sp,32
    80004808:	8082                	ret
    panic("filedup");
    8000480a:	00004517          	auipc	a0,0x4
    8000480e:	eae50513          	addi	a0,a0,-338 # 800086b8 <syscalls+0x240>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d2e080e7          	jalr	-722(ra) # 80000540 <panic>

000000008000481a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000481a:	7139                	addi	sp,sp,-64
    8000481c:	fc06                	sd	ra,56(sp)
    8000481e:	f822                	sd	s0,48(sp)
    80004820:	f426                	sd	s1,40(sp)
    80004822:	f04a                	sd	s2,32(sp)
    80004824:	ec4e                	sd	s3,24(sp)
    80004826:	e852                	sd	s4,16(sp)
    80004828:	e456                	sd	s5,8(sp)
    8000482a:	0080                	addi	s0,sp,64
    8000482c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000482e:	0001e517          	auipc	a0,0x1e
    80004832:	f2250513          	addi	a0,a0,-222 # 80022750 <ftable>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	3c6080e7          	jalr	966(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000483e:	40dc                	lw	a5,4(s1)
    80004840:	06f05163          	blez	a5,800048a2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004844:	37fd                	addiw	a5,a5,-1
    80004846:	0007871b          	sext.w	a4,a5
    8000484a:	c0dc                	sw	a5,4(s1)
    8000484c:	06e04363          	bgtz	a4,800048b2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004850:	0004a903          	lw	s2,0(s1)
    80004854:	0094ca83          	lbu	s5,9(s1)
    80004858:	0104ba03          	ld	s4,16(s1)
    8000485c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004860:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004864:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004868:	0001e517          	auipc	a0,0x1e
    8000486c:	ee850513          	addi	a0,a0,-280 # 80022750 <ftable>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	440080e7          	jalr	1088(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    80004878:	4785                	li	a5,1
    8000487a:	04f90d63          	beq	s2,a5,800048d4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000487e:	3979                	addiw	s2,s2,-2
    80004880:	4785                	li	a5,1
    80004882:	0527e063          	bltu	a5,s2,800048c2 <fileclose+0xa8>
    begin_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	ac2080e7          	jalr	-1342(ra) # 80004348 <begin_op>
    iput(ff.ip);
    8000488e:	854e                	mv	a0,s3
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	2b2080e7          	jalr	690(ra) # 80003b42 <iput>
    end_op();
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	b30080e7          	jalr	-1232(ra) # 800043c8 <end_op>
    800048a0:	a00d                	j	800048c2 <fileclose+0xa8>
    panic("fileclose");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	e1e50513          	addi	a0,a0,-482 # 800086c0 <syscalls+0x248>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c96080e7          	jalr	-874(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048b2:	0001e517          	auipc	a0,0x1e
    800048b6:	e9e50513          	addi	a0,a0,-354 # 80022750 <ftable>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	3f6080e7          	jalr	1014(ra) # 80000cb0 <release>
  }
}
    800048c2:	70e2                	ld	ra,56(sp)
    800048c4:	7442                	ld	s0,48(sp)
    800048c6:	74a2                	ld	s1,40(sp)
    800048c8:	7902                	ld	s2,32(sp)
    800048ca:	69e2                	ld	s3,24(sp)
    800048cc:	6a42                	ld	s4,16(sp)
    800048ce:	6aa2                	ld	s5,8(sp)
    800048d0:	6121                	addi	sp,sp,64
    800048d2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d4:	85d6                	mv	a1,s5
    800048d6:	8552                	mv	a0,s4
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	372080e7          	jalr	882(ra) # 80004c4a <pipeclose>
    800048e0:	b7cd                	j	800048c2 <fileclose+0xa8>

00000000800048e2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e2:	715d                	addi	sp,sp,-80
    800048e4:	e486                	sd	ra,72(sp)
    800048e6:	e0a2                	sd	s0,64(sp)
    800048e8:	fc26                	sd	s1,56(sp)
    800048ea:	f84a                	sd	s2,48(sp)
    800048ec:	f44e                	sd	s3,40(sp)
    800048ee:	0880                	addi	s0,sp,80
    800048f0:	84aa                	mv	s1,a0
    800048f2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f4:	ffffd097          	auipc	ra,0xffffd
    800048f8:	1fa080e7          	jalr	506(ra) # 80001aee <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048fc:	409c                	lw	a5,0(s1)
    800048fe:	37f9                	addiw	a5,a5,-2
    80004900:	4705                	li	a4,1
    80004902:	04f76763          	bltu	a4,a5,80004950 <filestat+0x6e>
    80004906:	892a                	mv	s2,a0
    ilock(f->ip);
    80004908:	6c88                	ld	a0,24(s1)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	07e080e7          	jalr	126(ra) # 80003988 <ilock>
    stati(f->ip, &st);
    80004912:	fb840593          	addi	a1,s0,-72
    80004916:	6c88                	ld	a0,24(s1)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	2fa080e7          	jalr	762(ra) # 80003c12 <stati>
    iunlock(f->ip);
    80004920:	6c88                	ld	a0,24(s1)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	128080e7          	jalr	296(ra) # 80003a4a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000492a:	46e1                	li	a3,24
    8000492c:	fb840613          	addi	a2,s0,-72
    80004930:	85ce                	mv	a1,s3
    80004932:	05093503          	ld	a0,80(s2)
    80004936:	ffffd097          	auipc	ra,0xffffd
    8000493a:	d74080e7          	jalr	-652(ra) # 800016aa <copyout>
    8000493e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004942:	60a6                	ld	ra,72(sp)
    80004944:	6406                	ld	s0,64(sp)
    80004946:	74e2                	ld	s1,56(sp)
    80004948:	7942                	ld	s2,48(sp)
    8000494a:	79a2                	ld	s3,40(sp)
    8000494c:	6161                	addi	sp,sp,80
    8000494e:	8082                	ret
  return -1;
    80004950:	557d                	li	a0,-1
    80004952:	bfc5                	j	80004942 <filestat+0x60>

0000000080004954 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004954:	7179                	addi	sp,sp,-48
    80004956:	f406                	sd	ra,40(sp)
    80004958:	f022                	sd	s0,32(sp)
    8000495a:	ec26                	sd	s1,24(sp)
    8000495c:	e84a                	sd	s2,16(sp)
    8000495e:	e44e                	sd	s3,8(sp)
    80004960:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004962:	00854783          	lbu	a5,8(a0)
    80004966:	c3d5                	beqz	a5,80004a0a <fileread+0xb6>
    80004968:	84aa                	mv	s1,a0
    8000496a:	89ae                	mv	s3,a1
    8000496c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000496e:	411c                	lw	a5,0(a0)
    80004970:	4705                	li	a4,1
    80004972:	04e78963          	beq	a5,a4,800049c4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004976:	470d                	li	a4,3
    80004978:	04e78d63          	beq	a5,a4,800049d2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000497c:	4709                	li	a4,2
    8000497e:	06e79e63          	bne	a5,a4,800049fa <fileread+0xa6>
    ilock(f->ip);
    80004982:	6d08                	ld	a0,24(a0)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	004080e7          	jalr	4(ra) # 80003988 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000498c:	874a                	mv	a4,s2
    8000498e:	5094                	lw	a3,32(s1)
    80004990:	864e                	mv	a2,s3
    80004992:	4585                	li	a1,1
    80004994:	6c88                	ld	a0,24(s1)
    80004996:	fffff097          	auipc	ra,0xfffff
    8000499a:	2a6080e7          	jalr	678(ra) # 80003c3c <readi>
    8000499e:	892a                	mv	s2,a0
    800049a0:	00a05563          	blez	a0,800049aa <fileread+0x56>
      f->off += r;
    800049a4:	509c                	lw	a5,32(s1)
    800049a6:	9fa9                	addw	a5,a5,a0
    800049a8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	09e080e7          	jalr	158(ra) # 80003a4a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b4:	854a                	mv	a0,s2
    800049b6:	70a2                	ld	ra,40(sp)
    800049b8:	7402                	ld	s0,32(sp)
    800049ba:	64e2                	ld	s1,24(sp)
    800049bc:	6942                	ld	s2,16(sp)
    800049be:	69a2                	ld	s3,8(sp)
    800049c0:	6145                	addi	sp,sp,48
    800049c2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c4:	6908                	ld	a0,16(a0)
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	3f4080e7          	jalr	1012(ra) # 80004dba <piperead>
    800049ce:	892a                	mv	s2,a0
    800049d0:	b7d5                	j	800049b4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d2:	02451783          	lh	a5,36(a0)
    800049d6:	03079693          	slli	a3,a5,0x30
    800049da:	92c1                	srli	a3,a3,0x30
    800049dc:	4725                	li	a4,9
    800049de:	02d76863          	bltu	a4,a3,80004a0e <fileread+0xba>
    800049e2:	0792                	slli	a5,a5,0x4
    800049e4:	0001e717          	auipc	a4,0x1e
    800049e8:	ccc70713          	addi	a4,a4,-820 # 800226b0 <devsw>
    800049ec:	97ba                	add	a5,a5,a4
    800049ee:	639c                	ld	a5,0(a5)
    800049f0:	c38d                	beqz	a5,80004a12 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f2:	4505                	li	a0,1
    800049f4:	9782                	jalr	a5
    800049f6:	892a                	mv	s2,a0
    800049f8:	bf75                	j	800049b4 <fileread+0x60>
    panic("fileread");
    800049fa:	00004517          	auipc	a0,0x4
    800049fe:	cd650513          	addi	a0,a0,-810 # 800086d0 <syscalls+0x258>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3e080e7          	jalr	-1218(ra) # 80000540 <panic>
    return -1;
    80004a0a:	597d                	li	s2,-1
    80004a0c:	b765                	j	800049b4 <fileread+0x60>
      return -1;
    80004a0e:	597d                	li	s2,-1
    80004a10:	b755                	j	800049b4 <fileread+0x60>
    80004a12:	597d                	li	s2,-1
    80004a14:	b745                	j	800049b4 <fileread+0x60>

0000000080004a16 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a16:	00954783          	lbu	a5,9(a0)
    80004a1a:	14078563          	beqz	a5,80004b64 <filewrite+0x14e>
{
    80004a1e:	715d                	addi	sp,sp,-80
    80004a20:	e486                	sd	ra,72(sp)
    80004a22:	e0a2                	sd	s0,64(sp)
    80004a24:	fc26                	sd	s1,56(sp)
    80004a26:	f84a                	sd	s2,48(sp)
    80004a28:	f44e                	sd	s3,40(sp)
    80004a2a:	f052                	sd	s4,32(sp)
    80004a2c:	ec56                	sd	s5,24(sp)
    80004a2e:	e85a                	sd	s6,16(sp)
    80004a30:	e45e                	sd	s7,8(sp)
    80004a32:	e062                	sd	s8,0(sp)
    80004a34:	0880                	addi	s0,sp,80
    80004a36:	892a                	mv	s2,a0
    80004a38:	8aae                	mv	s5,a1
    80004a3a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3c:	411c                	lw	a5,0(a0)
    80004a3e:	4705                	li	a4,1
    80004a40:	02e78263          	beq	a5,a4,80004a64 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a44:	470d                	li	a4,3
    80004a46:	02e78563          	beq	a5,a4,80004a70 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4a:	4709                	li	a4,2
    80004a4c:	10e79463          	bne	a5,a4,80004b54 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a50:	0ec05e63          	blez	a2,80004b4c <filewrite+0x136>
    int i = 0;
    80004a54:	4981                	li	s3,0
    80004a56:	6b05                	lui	s6,0x1
    80004a58:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a5c:	6b85                	lui	s7,0x1
    80004a5e:	c00b8b9b          	addiw	s7,s7,-1024
    80004a62:	a851                	j	80004af6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a64:	6908                	ld	a0,16(a0)
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	254080e7          	jalr	596(ra) # 80004cba <pipewrite>
    80004a6e:	a85d                	j	80004b24 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a70:	02451783          	lh	a5,36(a0)
    80004a74:	03079693          	slli	a3,a5,0x30
    80004a78:	92c1                	srli	a3,a3,0x30
    80004a7a:	4725                	li	a4,9
    80004a7c:	0ed76663          	bltu	a4,a3,80004b68 <filewrite+0x152>
    80004a80:	0792                	slli	a5,a5,0x4
    80004a82:	0001e717          	auipc	a4,0x1e
    80004a86:	c2e70713          	addi	a4,a4,-978 # 800226b0 <devsw>
    80004a8a:	97ba                	add	a5,a5,a4
    80004a8c:	679c                	ld	a5,8(a5)
    80004a8e:	cff9                	beqz	a5,80004b6c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a90:	4505                	li	a0,1
    80004a92:	9782                	jalr	a5
    80004a94:	a841                	j	80004b24 <filewrite+0x10e>
    80004a96:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	8ae080e7          	jalr	-1874(ra) # 80004348 <begin_op>
      ilock(f->ip);
    80004aa2:	01893503          	ld	a0,24(s2)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	ee2080e7          	jalr	-286(ra) # 80003988 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aae:	8762                	mv	a4,s8
    80004ab0:	02092683          	lw	a3,32(s2)
    80004ab4:	01598633          	add	a2,s3,s5
    80004ab8:	4585                	li	a1,1
    80004aba:	01893503          	ld	a0,24(s2)
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	274080e7          	jalr	628(ra) # 80003d32 <writei>
    80004ac6:	84aa                	mv	s1,a0
    80004ac8:	02a05f63          	blez	a0,80004b06 <filewrite+0xf0>
        f->off += r;
    80004acc:	02092783          	lw	a5,32(s2)
    80004ad0:	9fa9                	addw	a5,a5,a0
    80004ad2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad6:	01893503          	ld	a0,24(s2)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	f70080e7          	jalr	-144(ra) # 80003a4a <iunlock>
      end_op();
    80004ae2:	00000097          	auipc	ra,0x0
    80004ae6:	8e6080e7          	jalr	-1818(ra) # 800043c8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aea:	049c1963          	bne	s8,s1,80004b3c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004aee:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af2:	0349d663          	bge	s3,s4,80004b1e <filewrite+0x108>
      int n1 = n - i;
    80004af6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004afa:	84be                	mv	s1,a5
    80004afc:	2781                	sext.w	a5,a5
    80004afe:	f8fb5ce3          	bge	s6,a5,80004a96 <filewrite+0x80>
    80004b02:	84de                	mv	s1,s7
    80004b04:	bf49                	j	80004a96 <filewrite+0x80>
      iunlock(f->ip);
    80004b06:	01893503          	ld	a0,24(s2)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	f40080e7          	jalr	-192(ra) # 80003a4a <iunlock>
      end_op();
    80004b12:	00000097          	auipc	ra,0x0
    80004b16:	8b6080e7          	jalr	-1866(ra) # 800043c8 <end_op>
      if(r < 0)
    80004b1a:	fc04d8e3          	bgez	s1,80004aea <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b1e:	8552                	mv	a0,s4
    80004b20:	033a1863          	bne	s4,s3,80004b50 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b24:	60a6                	ld	ra,72(sp)
    80004b26:	6406                	ld	s0,64(sp)
    80004b28:	74e2                	ld	s1,56(sp)
    80004b2a:	7942                	ld	s2,48(sp)
    80004b2c:	79a2                	ld	s3,40(sp)
    80004b2e:	7a02                	ld	s4,32(sp)
    80004b30:	6ae2                	ld	s5,24(sp)
    80004b32:	6b42                	ld	s6,16(sp)
    80004b34:	6ba2                	ld	s7,8(sp)
    80004b36:	6c02                	ld	s8,0(sp)
    80004b38:	6161                	addi	sp,sp,80
    80004b3a:	8082                	ret
        panic("short filewrite");
    80004b3c:	00004517          	auipc	a0,0x4
    80004b40:	ba450513          	addi	a0,a0,-1116 # 800086e0 <syscalls+0x268>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	9fc080e7          	jalr	-1540(ra) # 80000540 <panic>
    int i = 0;
    80004b4c:	4981                	li	s3,0
    80004b4e:	bfc1                	j	80004b1e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b50:	557d                	li	a0,-1
    80004b52:	bfc9                	j	80004b24 <filewrite+0x10e>
    panic("filewrite");
    80004b54:	00004517          	auipc	a0,0x4
    80004b58:	b9c50513          	addi	a0,a0,-1124 # 800086f0 <syscalls+0x278>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	9e4080e7          	jalr	-1564(ra) # 80000540 <panic>
    return -1;
    80004b64:	557d                	li	a0,-1
}
    80004b66:	8082                	ret
      return -1;
    80004b68:	557d                	li	a0,-1
    80004b6a:	bf6d                	j	80004b24 <filewrite+0x10e>
    80004b6c:	557d                	li	a0,-1
    80004b6e:	bf5d                	j	80004b24 <filewrite+0x10e>

0000000080004b70 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b70:	7179                	addi	sp,sp,-48
    80004b72:	f406                	sd	ra,40(sp)
    80004b74:	f022                	sd	s0,32(sp)
    80004b76:	ec26                	sd	s1,24(sp)
    80004b78:	e84a                	sd	s2,16(sp)
    80004b7a:	e44e                	sd	s3,8(sp)
    80004b7c:	e052                	sd	s4,0(sp)
    80004b7e:	1800                	addi	s0,sp,48
    80004b80:	84aa                	mv	s1,a0
    80004b82:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b84:	0005b023          	sd	zero,0(a1)
    80004b88:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	bd2080e7          	jalr	-1070(ra) # 8000475e <filealloc>
    80004b94:	e088                	sd	a0,0(s1)
    80004b96:	c551                	beqz	a0,80004c22 <pipealloc+0xb2>
    80004b98:	00000097          	auipc	ra,0x0
    80004b9c:	bc6080e7          	jalr	-1082(ra) # 8000475e <filealloc>
    80004ba0:	00aa3023          	sd	a0,0(s4)
    80004ba4:	c92d                	beqz	a0,80004c16 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ba6:	ffffc097          	auipc	ra,0xffffc
    80004baa:	f66080e7          	jalr	-154(ra) # 80000b0c <kalloc>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	c125                	beqz	a0,80004c10 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bb2:	4985                	li	s3,1
    80004bb4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bb8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bbc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bc0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bc4:	00004597          	auipc	a1,0x4
    80004bc8:	b3c58593          	addi	a1,a1,-1220 # 80008700 <syscalls+0x288>
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	fa0080e7          	jalr	-96(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004bd4:	609c                	ld	a5,0(s1)
    80004bd6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bda:	609c                	ld	a5,0(s1)
    80004bdc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004be0:	609c                	ld	a5,0(s1)
    80004be2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004be6:	609c                	ld	a5,0(s1)
    80004be8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bec:	000a3783          	ld	a5,0(s4)
    80004bf0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bf4:	000a3783          	ld	a5,0(s4)
    80004bf8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bfc:	000a3783          	ld	a5,0(s4)
    80004c00:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c04:	000a3783          	ld	a5,0(s4)
    80004c08:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c0c:	4501                	li	a0,0
    80004c0e:	a025                	j	80004c36 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c10:	6088                	ld	a0,0(s1)
    80004c12:	e501                	bnez	a0,80004c1a <pipealloc+0xaa>
    80004c14:	a039                	j	80004c22 <pipealloc+0xb2>
    80004c16:	6088                	ld	a0,0(s1)
    80004c18:	c51d                	beqz	a0,80004c46 <pipealloc+0xd6>
    fileclose(*f0);
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	c00080e7          	jalr	-1024(ra) # 8000481a <fileclose>
  if(*f1)
    80004c22:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c26:	557d                	li	a0,-1
  if(*f1)
    80004c28:	c799                	beqz	a5,80004c36 <pipealloc+0xc6>
    fileclose(*f1);
    80004c2a:	853e                	mv	a0,a5
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	bee080e7          	jalr	-1042(ra) # 8000481a <fileclose>
  return -1;
    80004c34:	557d                	li	a0,-1
}
    80004c36:	70a2                	ld	ra,40(sp)
    80004c38:	7402                	ld	s0,32(sp)
    80004c3a:	64e2                	ld	s1,24(sp)
    80004c3c:	6942                	ld	s2,16(sp)
    80004c3e:	69a2                	ld	s3,8(sp)
    80004c40:	6a02                	ld	s4,0(sp)
    80004c42:	6145                	addi	sp,sp,48
    80004c44:	8082                	ret
  return -1;
    80004c46:	557d                	li	a0,-1
    80004c48:	b7fd                	j	80004c36 <pipealloc+0xc6>

0000000080004c4a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c4a:	1101                	addi	sp,sp,-32
    80004c4c:	ec06                	sd	ra,24(sp)
    80004c4e:	e822                	sd	s0,16(sp)
    80004c50:	e426                	sd	s1,8(sp)
    80004c52:	e04a                	sd	s2,0(sp)
    80004c54:	1000                	addi	s0,sp,32
    80004c56:	84aa                	mv	s1,a0
    80004c58:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	fa2080e7          	jalr	-94(ra) # 80000bfc <acquire>
  if(writable){
    80004c62:	02090d63          	beqz	s2,80004c9c <pipeclose+0x52>
    pi->writeopen = 0;
    80004c66:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c6a:	21848513          	addi	a0,s1,536
    80004c6e:	ffffe097          	auipc	ra,0xffffe
    80004c72:	a48080e7          	jalr	-1464(ra) # 800026b6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c76:	2204b783          	ld	a5,544(s1)
    80004c7a:	eb95                	bnez	a5,80004cae <pipeclose+0x64>
    release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	032080e7          	jalr	50(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	d88080e7          	jalr	-632(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c90:	60e2                	ld	ra,24(sp)
    80004c92:	6442                	ld	s0,16(sp)
    80004c94:	64a2                	ld	s1,8(sp)
    80004c96:	6902                	ld	s2,0(sp)
    80004c98:	6105                	addi	sp,sp,32
    80004c9a:	8082                	ret
    pi->readopen = 0;
    80004c9c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ca0:	21c48513          	addi	a0,s1,540
    80004ca4:	ffffe097          	auipc	ra,0xffffe
    80004ca8:	a12080e7          	jalr	-1518(ra) # 800026b6 <wakeup>
    80004cac:	b7e9                	j	80004c76 <pipeclose+0x2c>
    release(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	000080e7          	jalr	ra # 80000cb0 <release>
}
    80004cb8:	bfe1                	j	80004c90 <pipeclose+0x46>

0000000080004cba <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cba:	711d                	addi	sp,sp,-96
    80004cbc:	ec86                	sd	ra,88(sp)
    80004cbe:	e8a2                	sd	s0,80(sp)
    80004cc0:	e4a6                	sd	s1,72(sp)
    80004cc2:	e0ca                	sd	s2,64(sp)
    80004cc4:	fc4e                	sd	s3,56(sp)
    80004cc6:	f852                	sd	s4,48(sp)
    80004cc8:	f456                	sd	s5,40(sp)
    80004cca:	f05a                	sd	s6,32(sp)
    80004ccc:	ec5e                	sd	s7,24(sp)
    80004cce:	e862                	sd	s8,16(sp)
    80004cd0:	1080                	addi	s0,sp,96
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	8b2e                	mv	s6,a1
    80004cd6:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	e16080e7          	jalr	-490(ra) # 80001aee <myproc>
    80004ce0:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	f18080e7          	jalr	-232(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004cec:	09505763          	blez	s5,80004d7a <pipewrite+0xc0>
    80004cf0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cf2:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cf6:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cfa:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cfc:	2184a783          	lw	a5,536(s1)
    80004d00:	21c4a703          	lw	a4,540(s1)
    80004d04:	2007879b          	addiw	a5,a5,512
    80004d08:	02f71b63          	bne	a4,a5,80004d3e <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d0c:	2204a783          	lw	a5,544(s1)
    80004d10:	c3d1                	beqz	a5,80004d94 <pipewrite+0xda>
    80004d12:	03092783          	lw	a5,48(s2)
    80004d16:	efbd                	bnez	a5,80004d94 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d18:	8552                	mv	a0,s4
    80004d1a:	ffffe097          	auipc	ra,0xffffe
    80004d1e:	99c080e7          	jalr	-1636(ra) # 800026b6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d22:	85a6                	mv	a1,s1
    80004d24:	854e                	mv	a0,s3
    80004d26:	ffffe097          	auipc	ra,0xffffe
    80004d2a:	804080e7          	jalr	-2044(ra) # 8000252a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d2e:	2184a783          	lw	a5,536(s1)
    80004d32:	21c4a703          	lw	a4,540(s1)
    80004d36:	2007879b          	addiw	a5,a5,512
    80004d3a:	fcf709e3          	beq	a4,a5,80004d0c <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3e:	4685                	li	a3,1
    80004d40:	865a                	mv	a2,s6
    80004d42:	faf40593          	addi	a1,s0,-81
    80004d46:	05093503          	ld	a0,80(s2)
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	9ec080e7          	jalr	-1556(ra) # 80001736 <copyin>
    80004d52:	03850563          	beq	a0,s8,80004d7c <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d56:	21c4a783          	lw	a5,540(s1)
    80004d5a:	0017871b          	addiw	a4,a5,1
    80004d5e:	20e4ae23          	sw	a4,540(s1)
    80004d62:	1ff7f793          	andi	a5,a5,511
    80004d66:	97a6                	add	a5,a5,s1
    80004d68:	faf44703          	lbu	a4,-81(s0)
    80004d6c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d70:	2b85                	addiw	s7,s7,1
    80004d72:	0b05                	addi	s6,s6,1
    80004d74:	f97a94e3          	bne	s5,s7,80004cfc <pipewrite+0x42>
    80004d78:	a011                	j	80004d7c <pipewrite+0xc2>
    80004d7a:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d7c:	21848513          	addi	a0,s1,536
    80004d80:	ffffe097          	auipc	ra,0xffffe
    80004d84:	936080e7          	jalr	-1738(ra) # 800026b6 <wakeup>
  release(&pi->lock);
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	f26080e7          	jalr	-218(ra) # 80000cb0 <release>
  return i;
    80004d92:	a039                	j	80004da0 <pipewrite+0xe6>
        release(&pi->lock);
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f1a080e7          	jalr	-230(ra) # 80000cb0 <release>
        return -1;
    80004d9e:	5bfd                	li	s7,-1
}
    80004da0:	855e                	mv	a0,s7
    80004da2:	60e6                	ld	ra,88(sp)
    80004da4:	6446                	ld	s0,80(sp)
    80004da6:	64a6                	ld	s1,72(sp)
    80004da8:	6906                	ld	s2,64(sp)
    80004daa:	79e2                	ld	s3,56(sp)
    80004dac:	7a42                	ld	s4,48(sp)
    80004dae:	7aa2                	ld	s5,40(sp)
    80004db0:	7b02                	ld	s6,32(sp)
    80004db2:	6be2                	ld	s7,24(sp)
    80004db4:	6c42                	ld	s8,16(sp)
    80004db6:	6125                	addi	sp,sp,96
    80004db8:	8082                	ret

0000000080004dba <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dba:	715d                	addi	sp,sp,-80
    80004dbc:	e486                	sd	ra,72(sp)
    80004dbe:	e0a2                	sd	s0,64(sp)
    80004dc0:	fc26                	sd	s1,56(sp)
    80004dc2:	f84a                	sd	s2,48(sp)
    80004dc4:	f44e                	sd	s3,40(sp)
    80004dc6:	f052                	sd	s4,32(sp)
    80004dc8:	ec56                	sd	s5,24(sp)
    80004dca:	e85a                	sd	s6,16(sp)
    80004dcc:	0880                	addi	s0,sp,80
    80004dce:	84aa                	mv	s1,a0
    80004dd0:	892e                	mv	s2,a1
    80004dd2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	d1a080e7          	jalr	-742(ra) # 80001aee <myproc>
    80004ddc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dde:	8526                	mv	a0,s1
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	e1c080e7          	jalr	-484(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de8:	2184a703          	lw	a4,536(s1)
    80004dec:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df4:	02f71463          	bne	a4,a5,80004e1c <piperead+0x62>
    80004df8:	2244a783          	lw	a5,548(s1)
    80004dfc:	c385                	beqz	a5,80004e1c <piperead+0x62>
    if(pr->killed){
    80004dfe:	030a2783          	lw	a5,48(s4)
    80004e02:	ebc1                	bnez	a5,80004e92 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e04:	85a6                	mv	a1,s1
    80004e06:	854e                	mv	a0,s3
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	722080e7          	jalr	1826(ra) # 8000252a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e10:	2184a703          	lw	a4,536(s1)
    80004e14:	21c4a783          	lw	a5,540(s1)
    80004e18:	fef700e3          	beq	a4,a5,80004df8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e1e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e20:	05505363          	blez	s5,80004e66 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e24:	2184a783          	lw	a5,536(s1)
    80004e28:	21c4a703          	lw	a4,540(s1)
    80004e2c:	02f70d63          	beq	a4,a5,80004e66 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e30:	0017871b          	addiw	a4,a5,1
    80004e34:	20e4ac23          	sw	a4,536(s1)
    80004e38:	1ff7f793          	andi	a5,a5,511
    80004e3c:	97a6                	add	a5,a5,s1
    80004e3e:	0187c783          	lbu	a5,24(a5)
    80004e42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e46:	4685                	li	a3,1
    80004e48:	fbf40613          	addi	a2,s0,-65
    80004e4c:	85ca                	mv	a1,s2
    80004e4e:	050a3503          	ld	a0,80(s4)
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	858080e7          	jalr	-1960(ra) # 800016aa <copyout>
    80004e5a:	01650663          	beq	a0,s6,80004e66 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5e:	2985                	addiw	s3,s3,1
    80004e60:	0905                	addi	s2,s2,1
    80004e62:	fd3a91e3          	bne	s5,s3,80004e24 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e66:	21c48513          	addi	a0,s1,540
    80004e6a:	ffffe097          	auipc	ra,0xffffe
    80004e6e:	84c080e7          	jalr	-1972(ra) # 800026b6 <wakeup>
  release(&pi->lock);
    80004e72:	8526                	mv	a0,s1
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	e3c080e7          	jalr	-452(ra) # 80000cb0 <release>
  return i;
}
    80004e7c:	854e                	mv	a0,s3
    80004e7e:	60a6                	ld	ra,72(sp)
    80004e80:	6406                	ld	s0,64(sp)
    80004e82:	74e2                	ld	s1,56(sp)
    80004e84:	7942                	ld	s2,48(sp)
    80004e86:	79a2                	ld	s3,40(sp)
    80004e88:	7a02                	ld	s4,32(sp)
    80004e8a:	6ae2                	ld	s5,24(sp)
    80004e8c:	6b42                	ld	s6,16(sp)
    80004e8e:	6161                	addi	sp,sp,80
    80004e90:	8082                	ret
      release(&pi->lock);
    80004e92:	8526                	mv	a0,s1
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	e1c080e7          	jalr	-484(ra) # 80000cb0 <release>
      return -1;
    80004e9c:	59fd                	li	s3,-1
    80004e9e:	bff9                	j	80004e7c <piperead+0xc2>

0000000080004ea0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ea0:	de010113          	addi	sp,sp,-544
    80004ea4:	20113c23          	sd	ra,536(sp)
    80004ea8:	20813823          	sd	s0,528(sp)
    80004eac:	20913423          	sd	s1,520(sp)
    80004eb0:	21213023          	sd	s2,512(sp)
    80004eb4:	ffce                	sd	s3,504(sp)
    80004eb6:	fbd2                	sd	s4,496(sp)
    80004eb8:	f7d6                	sd	s5,488(sp)
    80004eba:	f3da                	sd	s6,480(sp)
    80004ebc:	efde                	sd	s7,472(sp)
    80004ebe:	ebe2                	sd	s8,464(sp)
    80004ec0:	e7e6                	sd	s9,456(sp)
    80004ec2:	e3ea                	sd	s10,448(sp)
    80004ec4:	ff6e                	sd	s11,440(sp)
    80004ec6:	1400                	addi	s0,sp,544
    80004ec8:	892a                	mv	s2,a0
    80004eca:	dea43423          	sd	a0,-536(s0)
    80004ece:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ed2:	ffffd097          	auipc	ra,0xffffd
    80004ed6:	c1c080e7          	jalr	-996(ra) # 80001aee <myproc>
    80004eda:	84aa                	mv	s1,a0

  begin_op();
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	46c080e7          	jalr	1132(ra) # 80004348 <begin_op>

  if((ip = namei(path)) == 0){
    80004ee4:	854a                	mv	a0,s2
    80004ee6:	fffff097          	auipc	ra,0xfffff
    80004eea:	252080e7          	jalr	594(ra) # 80004138 <namei>
    80004eee:	c93d                	beqz	a0,80004f64 <exec+0xc4>
    80004ef0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	a96080e7          	jalr	-1386(ra) # 80003988 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004efa:	04000713          	li	a4,64
    80004efe:	4681                	li	a3,0
    80004f00:	e4840613          	addi	a2,s0,-440
    80004f04:	4581                	li	a1,0
    80004f06:	8556                	mv	a0,s5
    80004f08:	fffff097          	auipc	ra,0xfffff
    80004f0c:	d34080e7          	jalr	-716(ra) # 80003c3c <readi>
    80004f10:	04000793          	li	a5,64
    80004f14:	00f51a63          	bne	a0,a5,80004f28 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f18:	e4842703          	lw	a4,-440(s0)
    80004f1c:	464c47b7          	lui	a5,0x464c4
    80004f20:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f24:	04f70663          	beq	a4,a5,80004f70 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f28:	8556                	mv	a0,s5
    80004f2a:	fffff097          	auipc	ra,0xfffff
    80004f2e:	cc0080e7          	jalr	-832(ra) # 80003bea <iunlockput>
    end_op();
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	496080e7          	jalr	1174(ra) # 800043c8 <end_op>
  }
  return -1;
    80004f3a:	557d                	li	a0,-1
}
    80004f3c:	21813083          	ld	ra,536(sp)
    80004f40:	21013403          	ld	s0,528(sp)
    80004f44:	20813483          	ld	s1,520(sp)
    80004f48:	20013903          	ld	s2,512(sp)
    80004f4c:	79fe                	ld	s3,504(sp)
    80004f4e:	7a5e                	ld	s4,496(sp)
    80004f50:	7abe                	ld	s5,488(sp)
    80004f52:	7b1e                	ld	s6,480(sp)
    80004f54:	6bfe                	ld	s7,472(sp)
    80004f56:	6c5e                	ld	s8,464(sp)
    80004f58:	6cbe                	ld	s9,456(sp)
    80004f5a:	6d1e                	ld	s10,448(sp)
    80004f5c:	7dfa                	ld	s11,440(sp)
    80004f5e:	22010113          	addi	sp,sp,544
    80004f62:	8082                	ret
    end_op();
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	464080e7          	jalr	1124(ra) # 800043c8 <end_op>
    return -1;
    80004f6c:	557d                	li	a0,-1
    80004f6e:	b7f9                	j	80004f3c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f70:	8526                	mv	a0,s1
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	c42080e7          	jalr	-958(ra) # 80001bb4 <proc_pagetable>
    80004f7a:	8b2a                	mv	s6,a0
    80004f7c:	d555                	beqz	a0,80004f28 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7e:	e6842783          	lw	a5,-408(s0)
    80004f82:	e8045703          	lhu	a4,-384(s0)
    80004f86:	c735                	beqz	a4,80004ff2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f88:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f8a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f8e:	6a05                	lui	s4,0x1
    80004f90:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f94:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f98:	6d85                	lui	s11,0x1
    80004f9a:	7d7d                	lui	s10,0xfffff
    80004f9c:	ac1d                	j	800051d2 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f9e:	00003517          	auipc	a0,0x3
    80004fa2:	76a50513          	addi	a0,a0,1898 # 80008708 <syscalls+0x290>
    80004fa6:	ffffb097          	auipc	ra,0xffffb
    80004faa:	59a080e7          	jalr	1434(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fae:	874a                	mv	a4,s2
    80004fb0:	009c86bb          	addw	a3,s9,s1
    80004fb4:	4581                	li	a1,0
    80004fb6:	8556                	mv	a0,s5
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	c84080e7          	jalr	-892(ra) # 80003c3c <readi>
    80004fc0:	2501                	sext.w	a0,a0
    80004fc2:	1aa91863          	bne	s2,a0,80005172 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fc6:	009d84bb          	addw	s1,s11,s1
    80004fca:	013d09bb          	addw	s3,s10,s3
    80004fce:	1f74f263          	bgeu	s1,s7,800051b2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fd2:	02049593          	slli	a1,s1,0x20
    80004fd6:	9181                	srli	a1,a1,0x20
    80004fd8:	95e2                	add	a1,a1,s8
    80004fda:	855a                	mv	a0,s6
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	09a080e7          	jalr	154(ra) # 80001076 <walkaddr>
    80004fe4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fe6:	dd45                	beqz	a0,80004f9e <exec+0xfe>
      n = PGSIZE;
    80004fe8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fea:	fd49f2e3          	bgeu	s3,s4,80004fae <exec+0x10e>
      n = sz - i;
    80004fee:	894e                	mv	s2,s3
    80004ff0:	bf7d                	j	80004fae <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ff2:	4481                	li	s1,0
  iunlockput(ip);
    80004ff4:	8556                	mv	a0,s5
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	bf4080e7          	jalr	-1036(ra) # 80003bea <iunlockput>
  end_op();
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	3ca080e7          	jalr	970(ra) # 800043c8 <end_op>
  p = myproc();
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	ae8080e7          	jalr	-1304(ra) # 80001aee <myproc>
    8000500e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005010:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005014:	6785                	lui	a5,0x1
    80005016:	17fd                	addi	a5,a5,-1
    80005018:	94be                	add	s1,s1,a5
    8000501a:	77fd                	lui	a5,0xfffff
    8000501c:	8fe5                	and	a5,a5,s1
    8000501e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005022:	6609                	lui	a2,0x2
    80005024:	963e                	add	a2,a2,a5
    80005026:	85be                	mv	a1,a5
    80005028:	855a                	mv	a0,s6
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	430080e7          	jalr	1072(ra) # 8000145a <uvmalloc>
    80005032:	8c2a                	mv	s8,a0
  ip = 0;
    80005034:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005036:	12050e63          	beqz	a0,80005172 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000503a:	75f9                	lui	a1,0xffffe
    8000503c:	95aa                	add	a1,a1,a0
    8000503e:	855a                	mv	a0,s6
    80005040:	ffffc097          	auipc	ra,0xffffc
    80005044:	638080e7          	jalr	1592(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80005048:	7afd                	lui	s5,0xfffff
    8000504a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000504c:	df043783          	ld	a5,-528(s0)
    80005050:	6388                	ld	a0,0(a5)
    80005052:	c925                	beqz	a0,800050c2 <exec+0x222>
    80005054:	e8840993          	addi	s3,s0,-376
    80005058:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000505c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000505e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	e1c080e7          	jalr	-484(ra) # 80000e7c <strlen>
    80005068:	0015079b          	addiw	a5,a0,1
    8000506c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005070:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005074:	13596363          	bltu	s2,s5,8000519a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005078:	df043d83          	ld	s11,-528(s0)
    8000507c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005080:	8552                	mv	a0,s4
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	dfa080e7          	jalr	-518(ra) # 80000e7c <strlen>
    8000508a:	0015069b          	addiw	a3,a0,1
    8000508e:	8652                	mv	a2,s4
    80005090:	85ca                	mv	a1,s2
    80005092:	855a                	mv	a0,s6
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	616080e7          	jalr	1558(ra) # 800016aa <copyout>
    8000509c:	10054363          	bltz	a0,800051a2 <exec+0x302>
    ustack[argc] = sp;
    800050a0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a4:	0485                	addi	s1,s1,1
    800050a6:	008d8793          	addi	a5,s11,8
    800050aa:	def43823          	sd	a5,-528(s0)
    800050ae:	008db503          	ld	a0,8(s11)
    800050b2:	c911                	beqz	a0,800050c6 <exec+0x226>
    if(argc >= MAXARG)
    800050b4:	09a1                	addi	s3,s3,8
    800050b6:	fb3c95e3          	bne	s9,s3,80005060 <exec+0x1c0>
  sz = sz1;
    800050ba:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050be:	4a81                	li	s5,0
    800050c0:	a84d                	j	80005172 <exec+0x2d2>
  sp = sz;
    800050c2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c4:	4481                	li	s1,0
  ustack[argc] = 0;
    800050c6:	00349793          	slli	a5,s1,0x3
    800050ca:	f9040713          	addi	a4,s0,-112
    800050ce:	97ba                	add	a5,a5,a4
    800050d0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050d4:	00148693          	addi	a3,s1,1
    800050d8:	068e                	slli	a3,a3,0x3
    800050da:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050de:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050e2:	01597663          	bgeu	s2,s5,800050ee <exec+0x24e>
  sz = sz1;
    800050e6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ea:	4a81                	li	s5,0
    800050ec:	a059                	j	80005172 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ee:	e8840613          	addi	a2,s0,-376
    800050f2:	85ca                	mv	a1,s2
    800050f4:	855a                	mv	a0,s6
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	5b4080e7          	jalr	1460(ra) # 800016aa <copyout>
    800050fe:	0a054663          	bltz	a0,800051aa <exec+0x30a>
  p->trapframe->a1 = sp;
    80005102:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005106:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000510a:	de843783          	ld	a5,-536(s0)
    8000510e:	0007c703          	lbu	a4,0(a5)
    80005112:	cf11                	beqz	a4,8000512e <exec+0x28e>
    80005114:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005116:	02f00693          	li	a3,47
    8000511a:	a039                	j	80005128 <exec+0x288>
      last = s+1;
    8000511c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005120:	0785                	addi	a5,a5,1
    80005122:	fff7c703          	lbu	a4,-1(a5)
    80005126:	c701                	beqz	a4,8000512e <exec+0x28e>
    if(*s == '/')
    80005128:	fed71ce3          	bne	a4,a3,80005120 <exec+0x280>
    8000512c:	bfc5                	j	8000511c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000512e:	4641                	li	a2,16
    80005130:	de843583          	ld	a1,-536(s0)
    80005134:	158b8513          	addi	a0,s7,344
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	d12080e7          	jalr	-750(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    80005140:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005144:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005148:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000514c:	058bb783          	ld	a5,88(s7)
    80005150:	e6043703          	ld	a4,-416(s0)
    80005154:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005156:	058bb783          	ld	a5,88(s7)
    8000515a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000515e:	85ea                	mv	a1,s10
    80005160:	ffffd097          	auipc	ra,0xffffd
    80005164:	af0080e7          	jalr	-1296(ra) # 80001c50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005168:	0004851b          	sext.w	a0,s1
    8000516c:	bbc1                	j	80004f3c <exec+0x9c>
    8000516e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005172:	df843583          	ld	a1,-520(s0)
    80005176:	855a                	mv	a0,s6
    80005178:	ffffd097          	auipc	ra,0xffffd
    8000517c:	ad8080e7          	jalr	-1320(ra) # 80001c50 <proc_freepagetable>
  if(ip){
    80005180:	da0a94e3          	bnez	s5,80004f28 <exec+0x88>
  return -1;
    80005184:	557d                	li	a0,-1
    80005186:	bb5d                	j	80004f3c <exec+0x9c>
    80005188:	de943c23          	sd	s1,-520(s0)
    8000518c:	b7dd                	j	80005172 <exec+0x2d2>
    8000518e:	de943c23          	sd	s1,-520(s0)
    80005192:	b7c5                	j	80005172 <exec+0x2d2>
    80005194:	de943c23          	sd	s1,-520(s0)
    80005198:	bfe9                	j	80005172 <exec+0x2d2>
  sz = sz1;
    8000519a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000519e:	4a81                	li	s5,0
    800051a0:	bfc9                	j	80005172 <exec+0x2d2>
  sz = sz1;
    800051a2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a6:	4a81                	li	s5,0
    800051a8:	b7e9                	j	80005172 <exec+0x2d2>
  sz = sz1;
    800051aa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ae:	4a81                	li	s5,0
    800051b0:	b7c9                	j	80005172 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b6:	e0843783          	ld	a5,-504(s0)
    800051ba:	0017869b          	addiw	a3,a5,1
    800051be:	e0d43423          	sd	a3,-504(s0)
    800051c2:	e0043783          	ld	a5,-512(s0)
    800051c6:	0387879b          	addiw	a5,a5,56
    800051ca:	e8045703          	lhu	a4,-384(s0)
    800051ce:	e2e6d3e3          	bge	a3,a4,80004ff4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051d2:	2781                	sext.w	a5,a5
    800051d4:	e0f43023          	sd	a5,-512(s0)
    800051d8:	03800713          	li	a4,56
    800051dc:	86be                	mv	a3,a5
    800051de:	e1040613          	addi	a2,s0,-496
    800051e2:	4581                	li	a1,0
    800051e4:	8556                	mv	a0,s5
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	a56080e7          	jalr	-1450(ra) # 80003c3c <readi>
    800051ee:	03800793          	li	a5,56
    800051f2:	f6f51ee3          	bne	a0,a5,8000516e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051f6:	e1042783          	lw	a5,-496(s0)
    800051fa:	4705                	li	a4,1
    800051fc:	fae79de3          	bne	a5,a4,800051b6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005200:	e3843603          	ld	a2,-456(s0)
    80005204:	e3043783          	ld	a5,-464(s0)
    80005208:	f8f660e3          	bltu	a2,a5,80005188 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000520c:	e2043783          	ld	a5,-480(s0)
    80005210:	963e                	add	a2,a2,a5
    80005212:	f6f66ee3          	bltu	a2,a5,8000518e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005216:	85a6                	mv	a1,s1
    80005218:	855a                	mv	a0,s6
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	240080e7          	jalr	576(ra) # 8000145a <uvmalloc>
    80005222:	dea43c23          	sd	a0,-520(s0)
    80005226:	d53d                	beqz	a0,80005194 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005228:	e2043c03          	ld	s8,-480(s0)
    8000522c:	de043783          	ld	a5,-544(s0)
    80005230:	00fc77b3          	and	a5,s8,a5
    80005234:	ff9d                	bnez	a5,80005172 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005236:	e1842c83          	lw	s9,-488(s0)
    8000523a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000523e:	f60b8ae3          	beqz	s7,800051b2 <exec+0x312>
    80005242:	89de                	mv	s3,s7
    80005244:	4481                	li	s1,0
    80005246:	b371                	j	80004fd2 <exec+0x132>

0000000080005248 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005248:	7179                	addi	sp,sp,-48
    8000524a:	f406                	sd	ra,40(sp)
    8000524c:	f022                	sd	s0,32(sp)
    8000524e:	ec26                	sd	s1,24(sp)
    80005250:	e84a                	sd	s2,16(sp)
    80005252:	1800                	addi	s0,sp,48
    80005254:	892e                	mv	s2,a1
    80005256:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005258:	fdc40593          	addi	a1,s0,-36
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	baa080e7          	jalr	-1110(ra) # 80002e06 <argint>
    80005264:	04054063          	bltz	a0,800052a4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005268:	fdc42703          	lw	a4,-36(s0)
    8000526c:	47bd                	li	a5,15
    8000526e:	02e7ed63          	bltu	a5,a4,800052a8 <argfd+0x60>
    80005272:	ffffd097          	auipc	ra,0xffffd
    80005276:	87c080e7          	jalr	-1924(ra) # 80001aee <myproc>
    8000527a:	fdc42703          	lw	a4,-36(s0)
    8000527e:	01a70793          	addi	a5,a4,26
    80005282:	078e                	slli	a5,a5,0x3
    80005284:	953e                	add	a0,a0,a5
    80005286:	611c                	ld	a5,0(a0)
    80005288:	c395                	beqz	a5,800052ac <argfd+0x64>
    return -1;
  if(pfd)
    8000528a:	00090463          	beqz	s2,80005292 <argfd+0x4a>
    *pfd = fd;
    8000528e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005292:	4501                	li	a0,0
  if(pf)
    80005294:	c091                	beqz	s1,80005298 <argfd+0x50>
    *pf = f;
    80005296:	e09c                	sd	a5,0(s1)
}
    80005298:	70a2                	ld	ra,40(sp)
    8000529a:	7402                	ld	s0,32(sp)
    8000529c:	64e2                	ld	s1,24(sp)
    8000529e:	6942                	ld	s2,16(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret
    return -1;
    800052a4:	557d                	li	a0,-1
    800052a6:	bfcd                	j	80005298 <argfd+0x50>
    return -1;
    800052a8:	557d                	li	a0,-1
    800052aa:	b7fd                	j	80005298 <argfd+0x50>
    800052ac:	557d                	li	a0,-1
    800052ae:	b7ed                	j	80005298 <argfd+0x50>

00000000800052b0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b0:	1101                	addi	sp,sp,-32
    800052b2:	ec06                	sd	ra,24(sp)
    800052b4:	e822                	sd	s0,16(sp)
    800052b6:	e426                	sd	s1,8(sp)
    800052b8:	1000                	addi	s0,sp,32
    800052ba:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	832080e7          	jalr	-1998(ra) # 80001aee <myproc>
    800052c4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052c6:	0d050793          	addi	a5,a0,208
    800052ca:	4501                	li	a0,0
    800052cc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ce:	6398                	ld	a4,0(a5)
    800052d0:	cb19                	beqz	a4,800052e6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052d2:	2505                	addiw	a0,a0,1
    800052d4:	07a1                	addi	a5,a5,8
    800052d6:	fed51ce3          	bne	a0,a3,800052ce <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052da:	557d                	li	a0,-1
}
    800052dc:	60e2                	ld	ra,24(sp)
    800052de:	6442                	ld	s0,16(sp)
    800052e0:	64a2                	ld	s1,8(sp)
    800052e2:	6105                	addi	sp,sp,32
    800052e4:	8082                	ret
      p->ofile[fd] = f;
    800052e6:	01a50793          	addi	a5,a0,26
    800052ea:	078e                	slli	a5,a5,0x3
    800052ec:	963e                	add	a2,a2,a5
    800052ee:	e204                	sd	s1,0(a2)
      return fd;
    800052f0:	b7f5                	j	800052dc <fdalloc+0x2c>

00000000800052f2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052f2:	715d                	addi	sp,sp,-80
    800052f4:	e486                	sd	ra,72(sp)
    800052f6:	e0a2                	sd	s0,64(sp)
    800052f8:	fc26                	sd	s1,56(sp)
    800052fa:	f84a                	sd	s2,48(sp)
    800052fc:	f44e                	sd	s3,40(sp)
    800052fe:	f052                	sd	s4,32(sp)
    80005300:	ec56                	sd	s5,24(sp)
    80005302:	0880                	addi	s0,sp,80
    80005304:	89ae                	mv	s3,a1
    80005306:	8ab2                	mv	s5,a2
    80005308:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000530a:	fb040593          	addi	a1,s0,-80
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	e48080e7          	jalr	-440(ra) # 80004156 <nameiparent>
    80005316:	892a                	mv	s2,a0
    80005318:	12050e63          	beqz	a0,80005454 <create+0x162>
    return 0;

  ilock(dp);
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	66c080e7          	jalr	1644(ra) # 80003988 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005324:	4601                	li	a2,0
    80005326:	fb040593          	addi	a1,s0,-80
    8000532a:	854a                	mv	a0,s2
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	b3a080e7          	jalr	-1222(ra) # 80003e66 <dirlookup>
    80005334:	84aa                	mv	s1,a0
    80005336:	c921                	beqz	a0,80005386 <create+0x94>
    iunlockput(dp);
    80005338:	854a                	mv	a0,s2
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	8b0080e7          	jalr	-1872(ra) # 80003bea <iunlockput>
    ilock(ip);
    80005342:	8526                	mv	a0,s1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	644080e7          	jalr	1604(ra) # 80003988 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000534c:	2981                	sext.w	s3,s3
    8000534e:	4789                	li	a5,2
    80005350:	02f99463          	bne	s3,a5,80005378 <create+0x86>
    80005354:	0444d783          	lhu	a5,68(s1)
    80005358:	37f9                	addiw	a5,a5,-2
    8000535a:	17c2                	slli	a5,a5,0x30
    8000535c:	93c1                	srli	a5,a5,0x30
    8000535e:	4705                	li	a4,1
    80005360:	00f76c63          	bltu	a4,a5,80005378 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005364:	8526                	mv	a0,s1
    80005366:	60a6                	ld	ra,72(sp)
    80005368:	6406                	ld	s0,64(sp)
    8000536a:	74e2                	ld	s1,56(sp)
    8000536c:	7942                	ld	s2,48(sp)
    8000536e:	79a2                	ld	s3,40(sp)
    80005370:	7a02                	ld	s4,32(sp)
    80005372:	6ae2                	ld	s5,24(sp)
    80005374:	6161                	addi	sp,sp,80
    80005376:	8082                	ret
    iunlockput(ip);
    80005378:	8526                	mv	a0,s1
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	870080e7          	jalr	-1936(ra) # 80003bea <iunlockput>
    return 0;
    80005382:	4481                	li	s1,0
    80005384:	b7c5                	j	80005364 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005386:	85ce                	mv	a1,s3
    80005388:	00092503          	lw	a0,0(s2)
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	464080e7          	jalr	1124(ra) # 800037f0 <ialloc>
    80005394:	84aa                	mv	s1,a0
    80005396:	c521                	beqz	a0,800053de <create+0xec>
  ilock(ip);
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	5f0080e7          	jalr	1520(ra) # 80003988 <ilock>
  ip->major = major;
    800053a0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053a4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053a8:	4a05                	li	s4,1
    800053aa:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053ae:	8526                	mv	a0,s1
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	50e080e7          	jalr	1294(ra) # 800038be <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053b8:	2981                	sext.w	s3,s3
    800053ba:	03498a63          	beq	s3,s4,800053ee <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053be:	40d0                	lw	a2,4(s1)
    800053c0:	fb040593          	addi	a1,s0,-80
    800053c4:	854a                	mv	a0,s2
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	cb0080e7          	jalr	-848(ra) # 80004076 <dirlink>
    800053ce:	06054b63          	bltz	a0,80005444 <create+0x152>
  iunlockput(dp);
    800053d2:	854a                	mv	a0,s2
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	816080e7          	jalr	-2026(ra) # 80003bea <iunlockput>
  return ip;
    800053dc:	b761                	j	80005364 <create+0x72>
    panic("create: ialloc");
    800053de:	00003517          	auipc	a0,0x3
    800053e2:	34a50513          	addi	a0,a0,842 # 80008728 <syscalls+0x2b0>
    800053e6:	ffffb097          	auipc	ra,0xffffb
    800053ea:	15a080e7          	jalr	346(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053ee:	04a95783          	lhu	a5,74(s2)
    800053f2:	2785                	addiw	a5,a5,1
    800053f4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053f8:	854a                	mv	a0,s2
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	4c4080e7          	jalr	1220(ra) # 800038be <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005402:	40d0                	lw	a2,4(s1)
    80005404:	00003597          	auipc	a1,0x3
    80005408:	33458593          	addi	a1,a1,820 # 80008738 <syscalls+0x2c0>
    8000540c:	8526                	mv	a0,s1
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	c68080e7          	jalr	-920(ra) # 80004076 <dirlink>
    80005416:	00054f63          	bltz	a0,80005434 <create+0x142>
    8000541a:	00492603          	lw	a2,4(s2)
    8000541e:	00003597          	auipc	a1,0x3
    80005422:	32258593          	addi	a1,a1,802 # 80008740 <syscalls+0x2c8>
    80005426:	8526                	mv	a0,s1
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	c4e080e7          	jalr	-946(ra) # 80004076 <dirlink>
    80005430:	f80557e3          	bgez	a0,800053be <create+0xcc>
      panic("create dots");
    80005434:	00003517          	auipc	a0,0x3
    80005438:	31450513          	addi	a0,a0,788 # 80008748 <syscalls+0x2d0>
    8000543c:	ffffb097          	auipc	ra,0xffffb
    80005440:	104080e7          	jalr	260(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005444:	00003517          	auipc	a0,0x3
    80005448:	31450513          	addi	a0,a0,788 # 80008758 <syscalls+0x2e0>
    8000544c:	ffffb097          	auipc	ra,0xffffb
    80005450:	0f4080e7          	jalr	244(ra) # 80000540 <panic>
    return 0;
    80005454:	84aa                	mv	s1,a0
    80005456:	b739                	j	80005364 <create+0x72>

0000000080005458 <sys_dup>:
{
    80005458:	7179                	addi	sp,sp,-48
    8000545a:	f406                	sd	ra,40(sp)
    8000545c:	f022                	sd	s0,32(sp)
    8000545e:	ec26                	sd	s1,24(sp)
    80005460:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005462:	fd840613          	addi	a2,s0,-40
    80005466:	4581                	li	a1,0
    80005468:	4501                	li	a0,0
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	dde080e7          	jalr	-546(ra) # 80005248 <argfd>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005474:	02054363          	bltz	a0,8000549a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005478:	fd843503          	ld	a0,-40(s0)
    8000547c:	00000097          	auipc	ra,0x0
    80005480:	e34080e7          	jalr	-460(ra) # 800052b0 <fdalloc>
    80005484:	84aa                	mv	s1,a0
    return -1;
    80005486:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005488:	00054963          	bltz	a0,8000549a <sys_dup+0x42>
  filedup(f);
    8000548c:	fd843503          	ld	a0,-40(s0)
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	338080e7          	jalr	824(ra) # 800047c8 <filedup>
  return fd;
    80005498:	87a6                	mv	a5,s1
}
    8000549a:	853e                	mv	a0,a5
    8000549c:	70a2                	ld	ra,40(sp)
    8000549e:	7402                	ld	s0,32(sp)
    800054a0:	64e2                	ld	s1,24(sp)
    800054a2:	6145                	addi	sp,sp,48
    800054a4:	8082                	ret

00000000800054a6 <sys_read>:
{
    800054a6:	7179                	addi	sp,sp,-48
    800054a8:	f406                	sd	ra,40(sp)
    800054aa:	f022                	sd	s0,32(sp)
    800054ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ae:	fe840613          	addi	a2,s0,-24
    800054b2:	4581                	li	a1,0
    800054b4:	4501                	li	a0,0
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	d92080e7          	jalr	-622(ra) # 80005248 <argfd>
    return -1;
    800054be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	04054163          	bltz	a0,80005502 <sys_read+0x5c>
    800054c4:	fe440593          	addi	a1,s0,-28
    800054c8:	4509                	li	a0,2
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	93c080e7          	jalr	-1732(ra) # 80002e06 <argint>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d4:	02054763          	bltz	a0,80005502 <sys_read+0x5c>
    800054d8:	fd840593          	addi	a1,s0,-40
    800054dc:	4505                	li	a0,1
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	94a080e7          	jalr	-1718(ra) # 80002e28 <argaddr>
    return -1;
    800054e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e8:	00054d63          	bltz	a0,80005502 <sys_read+0x5c>
  return fileread(f, p, n);
    800054ec:	fe442603          	lw	a2,-28(s0)
    800054f0:	fd843583          	ld	a1,-40(s0)
    800054f4:	fe843503          	ld	a0,-24(s0)
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	45c080e7          	jalr	1116(ra) # 80004954 <fileread>
    80005500:	87aa                	mv	a5,a0
}
    80005502:	853e                	mv	a0,a5
    80005504:	70a2                	ld	ra,40(sp)
    80005506:	7402                	ld	s0,32(sp)
    80005508:	6145                	addi	sp,sp,48
    8000550a:	8082                	ret

000000008000550c <sys_write>:
{
    8000550c:	7179                	addi	sp,sp,-48
    8000550e:	f406                	sd	ra,40(sp)
    80005510:	f022                	sd	s0,32(sp)
    80005512:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005514:	fe840613          	addi	a2,s0,-24
    80005518:	4581                	li	a1,0
    8000551a:	4501                	li	a0,0
    8000551c:	00000097          	auipc	ra,0x0
    80005520:	d2c080e7          	jalr	-724(ra) # 80005248 <argfd>
    return -1;
    80005524:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005526:	04054163          	bltz	a0,80005568 <sys_write+0x5c>
    8000552a:	fe440593          	addi	a1,s0,-28
    8000552e:	4509                	li	a0,2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	8d6080e7          	jalr	-1834(ra) # 80002e06 <argint>
    return -1;
    80005538:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553a:	02054763          	bltz	a0,80005568 <sys_write+0x5c>
    8000553e:	fd840593          	addi	a1,s0,-40
    80005542:	4505                	li	a0,1
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	8e4080e7          	jalr	-1820(ra) # 80002e28 <argaddr>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554e:	00054d63          	bltz	a0,80005568 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005552:	fe442603          	lw	a2,-28(s0)
    80005556:	fd843583          	ld	a1,-40(s0)
    8000555a:	fe843503          	ld	a0,-24(s0)
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	4b8080e7          	jalr	1208(ra) # 80004a16 <filewrite>
    80005566:	87aa                	mv	a5,a0
}
    80005568:	853e                	mv	a0,a5
    8000556a:	70a2                	ld	ra,40(sp)
    8000556c:	7402                	ld	s0,32(sp)
    8000556e:	6145                	addi	sp,sp,48
    80005570:	8082                	ret

0000000080005572 <sys_close>:
{
    80005572:	1101                	addi	sp,sp,-32
    80005574:	ec06                	sd	ra,24(sp)
    80005576:	e822                	sd	s0,16(sp)
    80005578:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000557a:	fe040613          	addi	a2,s0,-32
    8000557e:	fec40593          	addi	a1,s0,-20
    80005582:	4501                	li	a0,0
    80005584:	00000097          	auipc	ra,0x0
    80005588:	cc4080e7          	jalr	-828(ra) # 80005248 <argfd>
    return -1;
    8000558c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000558e:	02054463          	bltz	a0,800055b6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005592:	ffffc097          	auipc	ra,0xffffc
    80005596:	55c080e7          	jalr	1372(ra) # 80001aee <myproc>
    8000559a:	fec42783          	lw	a5,-20(s0)
    8000559e:	07e9                	addi	a5,a5,26
    800055a0:	078e                	slli	a5,a5,0x3
    800055a2:	97aa                	add	a5,a5,a0
    800055a4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055a8:	fe043503          	ld	a0,-32(s0)
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	26e080e7          	jalr	622(ra) # 8000481a <fileclose>
  return 0;
    800055b4:	4781                	li	a5,0
}
    800055b6:	853e                	mv	a0,a5
    800055b8:	60e2                	ld	ra,24(sp)
    800055ba:	6442                	ld	s0,16(sp)
    800055bc:	6105                	addi	sp,sp,32
    800055be:	8082                	ret

00000000800055c0 <sys_fstat>:
{
    800055c0:	1101                	addi	sp,sp,-32
    800055c2:	ec06                	sd	ra,24(sp)
    800055c4:	e822                	sd	s0,16(sp)
    800055c6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c8:	fe840613          	addi	a2,s0,-24
    800055cc:	4581                	li	a1,0
    800055ce:	4501                	li	a0,0
    800055d0:	00000097          	auipc	ra,0x0
    800055d4:	c78080e7          	jalr	-904(ra) # 80005248 <argfd>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055da:	02054563          	bltz	a0,80005604 <sys_fstat+0x44>
    800055de:	fe040593          	addi	a1,s0,-32
    800055e2:	4505                	li	a0,1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	844080e7          	jalr	-1980(ra) # 80002e28 <argaddr>
    return -1;
    800055ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ee:	00054b63          	bltz	a0,80005604 <sys_fstat+0x44>
  return filestat(f, st);
    800055f2:	fe043583          	ld	a1,-32(s0)
    800055f6:	fe843503          	ld	a0,-24(s0)
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	2e8080e7          	jalr	744(ra) # 800048e2 <filestat>
    80005602:	87aa                	mv	a5,a0
}
    80005604:	853e                	mv	a0,a5
    80005606:	60e2                	ld	ra,24(sp)
    80005608:	6442                	ld	s0,16(sp)
    8000560a:	6105                	addi	sp,sp,32
    8000560c:	8082                	ret

000000008000560e <sys_link>:
{
    8000560e:	7169                	addi	sp,sp,-304
    80005610:	f606                	sd	ra,296(sp)
    80005612:	f222                	sd	s0,288(sp)
    80005614:	ee26                	sd	s1,280(sp)
    80005616:	ea4a                	sd	s2,272(sp)
    80005618:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000561a:	08000613          	li	a2,128
    8000561e:	ed040593          	addi	a1,s0,-304
    80005622:	4501                	li	a0,0
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	826080e7          	jalr	-2010(ra) # 80002e4a <argstr>
    return -1;
    8000562c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562e:	10054e63          	bltz	a0,8000574a <sys_link+0x13c>
    80005632:	08000613          	li	a2,128
    80005636:	f5040593          	addi	a1,s0,-176
    8000563a:	4505                	li	a0,1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	80e080e7          	jalr	-2034(ra) # 80002e4a <argstr>
    return -1;
    80005644:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005646:	10054263          	bltz	a0,8000574a <sys_link+0x13c>
  begin_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	cfe080e7          	jalr	-770(ra) # 80004348 <begin_op>
  if((ip = namei(old)) == 0){
    80005652:	ed040513          	addi	a0,s0,-304
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	ae2080e7          	jalr	-1310(ra) # 80004138 <namei>
    8000565e:	84aa                	mv	s1,a0
    80005660:	c551                	beqz	a0,800056ec <sys_link+0xde>
  ilock(ip);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	326080e7          	jalr	806(ra) # 80003988 <ilock>
  if(ip->type == T_DIR){
    8000566a:	04449703          	lh	a4,68(s1)
    8000566e:	4785                	li	a5,1
    80005670:	08f70463          	beq	a4,a5,800056f8 <sys_link+0xea>
  ip->nlink++;
    80005674:	04a4d783          	lhu	a5,74(s1)
    80005678:	2785                	addiw	a5,a5,1
    8000567a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	23e080e7          	jalr	574(ra) # 800038be <iupdate>
  iunlock(ip);
    80005688:	8526                	mv	a0,s1
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	3c0080e7          	jalr	960(ra) # 80003a4a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005692:	fd040593          	addi	a1,s0,-48
    80005696:	f5040513          	addi	a0,s0,-176
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	abc080e7          	jalr	-1348(ra) # 80004156 <nameiparent>
    800056a2:	892a                	mv	s2,a0
    800056a4:	c935                	beqz	a0,80005718 <sys_link+0x10a>
  ilock(dp);
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	2e2080e7          	jalr	738(ra) # 80003988 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ae:	00092703          	lw	a4,0(s2)
    800056b2:	409c                	lw	a5,0(s1)
    800056b4:	04f71d63          	bne	a4,a5,8000570e <sys_link+0x100>
    800056b8:	40d0                	lw	a2,4(s1)
    800056ba:	fd040593          	addi	a1,s0,-48
    800056be:	854a                	mv	a0,s2
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	9b6080e7          	jalr	-1610(ra) # 80004076 <dirlink>
    800056c8:	04054363          	bltz	a0,8000570e <sys_link+0x100>
  iunlockput(dp);
    800056cc:	854a                	mv	a0,s2
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	51c080e7          	jalr	1308(ra) # 80003bea <iunlockput>
  iput(ip);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	46a080e7          	jalr	1130(ra) # 80003b42 <iput>
  end_op();
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	ce8080e7          	jalr	-792(ra) # 800043c8 <end_op>
  return 0;
    800056e8:	4781                	li	a5,0
    800056ea:	a085                	j	8000574a <sys_link+0x13c>
    end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cdc080e7          	jalr	-804(ra) # 800043c8 <end_op>
    return -1;
    800056f4:	57fd                	li	a5,-1
    800056f6:	a891                	j	8000574a <sys_link+0x13c>
    iunlockput(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	4f0080e7          	jalr	1264(ra) # 80003bea <iunlockput>
    end_op();
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	cc6080e7          	jalr	-826(ra) # 800043c8 <end_op>
    return -1;
    8000570a:	57fd                	li	a5,-1
    8000570c:	a83d                	j	8000574a <sys_link+0x13c>
    iunlockput(dp);
    8000570e:	854a                	mv	a0,s2
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	4da080e7          	jalr	1242(ra) # 80003bea <iunlockput>
  ilock(ip);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	26e080e7          	jalr	622(ra) # 80003988 <ilock>
  ip->nlink--;
    80005722:	04a4d783          	lhu	a5,74(s1)
    80005726:	37fd                	addiw	a5,a5,-1
    80005728:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000572c:	8526                	mv	a0,s1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	190080e7          	jalr	400(ra) # 800038be <iupdate>
  iunlockput(ip);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	4b2080e7          	jalr	1202(ra) # 80003bea <iunlockput>
  end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	c88080e7          	jalr	-888(ra) # 800043c8 <end_op>
  return -1;
    80005748:	57fd                	li	a5,-1
}
    8000574a:	853e                	mv	a0,a5
    8000574c:	70b2                	ld	ra,296(sp)
    8000574e:	7412                	ld	s0,288(sp)
    80005750:	64f2                	ld	s1,280(sp)
    80005752:	6952                	ld	s2,272(sp)
    80005754:	6155                	addi	sp,sp,304
    80005756:	8082                	ret

0000000080005758 <sys_unlink>:
{
    80005758:	7151                	addi	sp,sp,-240
    8000575a:	f586                	sd	ra,232(sp)
    8000575c:	f1a2                	sd	s0,224(sp)
    8000575e:	eda6                	sd	s1,216(sp)
    80005760:	e9ca                	sd	s2,208(sp)
    80005762:	e5ce                	sd	s3,200(sp)
    80005764:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005766:	08000613          	li	a2,128
    8000576a:	f3040593          	addi	a1,s0,-208
    8000576e:	4501                	li	a0,0
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	6da080e7          	jalr	1754(ra) # 80002e4a <argstr>
    80005778:	18054163          	bltz	a0,800058fa <sys_unlink+0x1a2>
  begin_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	bcc080e7          	jalr	-1076(ra) # 80004348 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005784:	fb040593          	addi	a1,s0,-80
    80005788:	f3040513          	addi	a0,s0,-208
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9ca080e7          	jalr	-1590(ra) # 80004156 <nameiparent>
    80005794:	84aa                	mv	s1,a0
    80005796:	c979                	beqz	a0,8000586c <sys_unlink+0x114>
  ilock(dp);
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	1f0080e7          	jalr	496(ra) # 80003988 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057a0:	00003597          	auipc	a1,0x3
    800057a4:	f9858593          	addi	a1,a1,-104 # 80008738 <syscalls+0x2c0>
    800057a8:	fb040513          	addi	a0,s0,-80
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	6a0080e7          	jalr	1696(ra) # 80003e4c <namecmp>
    800057b4:	14050a63          	beqz	a0,80005908 <sys_unlink+0x1b0>
    800057b8:	00003597          	auipc	a1,0x3
    800057bc:	f8858593          	addi	a1,a1,-120 # 80008740 <syscalls+0x2c8>
    800057c0:	fb040513          	addi	a0,s0,-80
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	688080e7          	jalr	1672(ra) # 80003e4c <namecmp>
    800057cc:	12050e63          	beqz	a0,80005908 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057d0:	f2c40613          	addi	a2,s0,-212
    800057d4:	fb040593          	addi	a1,s0,-80
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	68c080e7          	jalr	1676(ra) # 80003e66 <dirlookup>
    800057e2:	892a                	mv	s2,a0
    800057e4:	12050263          	beqz	a0,80005908 <sys_unlink+0x1b0>
  ilock(ip);
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	1a0080e7          	jalr	416(ra) # 80003988 <ilock>
  if(ip->nlink < 1)
    800057f0:	04a91783          	lh	a5,74(s2)
    800057f4:	08f05263          	blez	a5,80005878 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057f8:	04491703          	lh	a4,68(s2)
    800057fc:	4785                	li	a5,1
    800057fe:	08f70563          	beq	a4,a5,80005888 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005802:	4641                	li	a2,16
    80005804:	4581                	li	a1,0
    80005806:	fc040513          	addi	a0,s0,-64
    8000580a:	ffffb097          	auipc	ra,0xffffb
    8000580e:	4ee080e7          	jalr	1262(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005812:	4741                	li	a4,16
    80005814:	f2c42683          	lw	a3,-212(s0)
    80005818:	fc040613          	addi	a2,s0,-64
    8000581c:	4581                	li	a1,0
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	512080e7          	jalr	1298(ra) # 80003d32 <writei>
    80005828:	47c1                	li	a5,16
    8000582a:	0af51563          	bne	a0,a5,800058d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000582e:	04491703          	lh	a4,68(s2)
    80005832:	4785                	li	a5,1
    80005834:	0af70863          	beq	a4,a5,800058e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	3b0080e7          	jalr	944(ra) # 80003bea <iunlockput>
  ip->nlink--;
    80005842:	04a95783          	lhu	a5,74(s2)
    80005846:	37fd                	addiw	a5,a5,-1
    80005848:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	070080e7          	jalr	112(ra) # 800038be <iupdate>
  iunlockput(ip);
    80005856:	854a                	mv	a0,s2
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	392080e7          	jalr	914(ra) # 80003bea <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	b68080e7          	jalr	-1176(ra) # 800043c8 <end_op>
  return 0;
    80005868:	4501                	li	a0,0
    8000586a:	a84d                	j	8000591c <sys_unlink+0x1c4>
    end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	b5c080e7          	jalr	-1188(ra) # 800043c8 <end_op>
    return -1;
    80005874:	557d                	li	a0,-1
    80005876:	a05d                	j	8000591c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005878:	00003517          	auipc	a0,0x3
    8000587c:	ef050513          	addi	a0,a0,-272 # 80008768 <syscalls+0x2f0>
    80005880:	ffffb097          	auipc	ra,0xffffb
    80005884:	cc0080e7          	jalr	-832(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005888:	04c92703          	lw	a4,76(s2)
    8000588c:	02000793          	li	a5,32
    80005890:	f6e7f9e3          	bgeu	a5,a4,80005802 <sys_unlink+0xaa>
    80005894:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005898:	4741                	li	a4,16
    8000589a:	86ce                	mv	a3,s3
    8000589c:	f1840613          	addi	a2,s0,-232
    800058a0:	4581                	li	a1,0
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	398080e7          	jalr	920(ra) # 80003c3c <readi>
    800058ac:	47c1                	li	a5,16
    800058ae:	00f51b63          	bne	a0,a5,800058c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058b2:	f1845783          	lhu	a5,-232(s0)
    800058b6:	e7a1                	bnez	a5,800058fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b8:	29c1                	addiw	s3,s3,16
    800058ba:	04c92783          	lw	a5,76(s2)
    800058be:	fcf9ede3          	bltu	s3,a5,80005898 <sys_unlink+0x140>
    800058c2:	b781                	j	80005802 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058c4:	00003517          	auipc	a0,0x3
    800058c8:	ebc50513          	addi	a0,a0,-324 # 80008780 <syscalls+0x308>
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	c74080e7          	jalr	-908(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058d4:	00003517          	auipc	a0,0x3
    800058d8:	ec450513          	addi	a0,a0,-316 # 80008798 <syscalls+0x320>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	c64080e7          	jalr	-924(ra) # 80000540 <panic>
    dp->nlink--;
    800058e4:	04a4d783          	lhu	a5,74(s1)
    800058e8:	37fd                	addiw	a5,a5,-1
    800058ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	fce080e7          	jalr	-50(ra) # 800038be <iupdate>
    800058f8:	b781                	j	80005838 <sys_unlink+0xe0>
    return -1;
    800058fa:	557d                	li	a0,-1
    800058fc:	a005                	j	8000591c <sys_unlink+0x1c4>
    iunlockput(ip);
    800058fe:	854a                	mv	a0,s2
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	2ea080e7          	jalr	746(ra) # 80003bea <iunlockput>
  iunlockput(dp);
    80005908:	8526                	mv	a0,s1
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	2e0080e7          	jalr	736(ra) # 80003bea <iunlockput>
  end_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	ab6080e7          	jalr	-1354(ra) # 800043c8 <end_op>
  return -1;
    8000591a:	557d                	li	a0,-1
}
    8000591c:	70ae                	ld	ra,232(sp)
    8000591e:	740e                	ld	s0,224(sp)
    80005920:	64ee                	ld	s1,216(sp)
    80005922:	694e                	ld	s2,208(sp)
    80005924:	69ae                	ld	s3,200(sp)
    80005926:	616d                	addi	sp,sp,240
    80005928:	8082                	ret

000000008000592a <sys_open>:

uint64
sys_open(void)
{
    8000592a:	7131                	addi	sp,sp,-192
    8000592c:	fd06                	sd	ra,184(sp)
    8000592e:	f922                	sd	s0,176(sp)
    80005930:	f526                	sd	s1,168(sp)
    80005932:	f14a                	sd	s2,160(sp)
    80005934:	ed4e                	sd	s3,152(sp)
    80005936:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005938:	08000613          	li	a2,128
    8000593c:	f5040593          	addi	a1,s0,-176
    80005940:	4501                	li	a0,0
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	508080e7          	jalr	1288(ra) # 80002e4a <argstr>
    return -1;
    8000594a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000594c:	0c054163          	bltz	a0,80005a0e <sys_open+0xe4>
    80005950:	f4c40593          	addi	a1,s0,-180
    80005954:	4505                	li	a0,1
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	4b0080e7          	jalr	1200(ra) # 80002e06 <argint>
    8000595e:	0a054863          	bltz	a0,80005a0e <sys_open+0xe4>

  begin_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	9e6080e7          	jalr	-1562(ra) # 80004348 <begin_op>

  if(omode & O_CREATE){
    8000596a:	f4c42783          	lw	a5,-180(s0)
    8000596e:	2007f793          	andi	a5,a5,512
    80005972:	cbdd                	beqz	a5,80005a28 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005974:	4681                	li	a3,0
    80005976:	4601                	li	a2,0
    80005978:	4589                	li	a1,2
    8000597a:	f5040513          	addi	a0,s0,-176
    8000597e:	00000097          	auipc	ra,0x0
    80005982:	974080e7          	jalr	-1676(ra) # 800052f2 <create>
    80005986:	892a                	mv	s2,a0
    if(ip == 0){
    80005988:	c959                	beqz	a0,80005a1e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	478d                	li	a5,3
    80005990:	00f71763          	bne	a4,a5,8000599e <sys_open+0x74>
    80005994:	04695703          	lhu	a4,70(s2)
    80005998:	47a5                	li	a5,9
    8000599a:	0ce7ec63          	bltu	a5,a4,80005a72 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	dc0080e7          	jalr	-576(ra) # 8000475e <filealloc>
    800059a6:	89aa                	mv	s3,a0
    800059a8:	10050263          	beqz	a0,80005aac <sys_open+0x182>
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	904080e7          	jalr	-1788(ra) # 800052b0 <fdalloc>
    800059b4:	84aa                	mv	s1,a0
    800059b6:	0e054663          	bltz	a0,80005aa2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059ba:	04491703          	lh	a4,68(s2)
    800059be:	478d                	li	a5,3
    800059c0:	0cf70463          	beq	a4,a5,80005a88 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059c4:	4789                	li	a5,2
    800059c6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059ca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059ce:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059d2:	f4c42783          	lw	a5,-180(s0)
    800059d6:	0017c713          	xori	a4,a5,1
    800059da:	8b05                	andi	a4,a4,1
    800059dc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059e0:	0037f713          	andi	a4,a5,3
    800059e4:	00e03733          	snez	a4,a4
    800059e8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059ec:	4007f793          	andi	a5,a5,1024
    800059f0:	c791                	beqz	a5,800059fc <sys_open+0xd2>
    800059f2:	04491703          	lh	a4,68(s2)
    800059f6:	4789                	li	a5,2
    800059f8:	08f70f63          	beq	a4,a5,80005a96 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059fc:	854a                	mv	a0,s2
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	04c080e7          	jalr	76(ra) # 80003a4a <iunlock>
  end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	9c2080e7          	jalr	-1598(ra) # 800043c8 <end_op>

  return fd;
}
    80005a0e:	8526                	mv	a0,s1
    80005a10:	70ea                	ld	ra,184(sp)
    80005a12:	744a                	ld	s0,176(sp)
    80005a14:	74aa                	ld	s1,168(sp)
    80005a16:	790a                	ld	s2,160(sp)
    80005a18:	69ea                	ld	s3,152(sp)
    80005a1a:	6129                	addi	sp,sp,192
    80005a1c:	8082                	ret
      end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	9aa080e7          	jalr	-1622(ra) # 800043c8 <end_op>
      return -1;
    80005a26:	b7e5                	j	80005a0e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a28:	f5040513          	addi	a0,s0,-176
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	70c080e7          	jalr	1804(ra) # 80004138 <namei>
    80005a34:	892a                	mv	s2,a0
    80005a36:	c905                	beqz	a0,80005a66 <sys_open+0x13c>
    ilock(ip);
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	f50080e7          	jalr	-176(ra) # 80003988 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a40:	04491703          	lh	a4,68(s2)
    80005a44:	4785                	li	a5,1
    80005a46:	f4f712e3          	bne	a4,a5,8000598a <sys_open+0x60>
    80005a4a:	f4c42783          	lw	a5,-180(s0)
    80005a4e:	dba1                	beqz	a5,8000599e <sys_open+0x74>
      iunlockput(ip);
    80005a50:	854a                	mv	a0,s2
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	198080e7          	jalr	408(ra) # 80003bea <iunlockput>
      end_op();
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	96e080e7          	jalr	-1682(ra) # 800043c8 <end_op>
      return -1;
    80005a62:	54fd                	li	s1,-1
    80005a64:	b76d                	j	80005a0e <sys_open+0xe4>
      end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	962080e7          	jalr	-1694(ra) # 800043c8 <end_op>
      return -1;
    80005a6e:	54fd                	li	s1,-1
    80005a70:	bf79                	j	80005a0e <sys_open+0xe4>
    iunlockput(ip);
    80005a72:	854a                	mv	a0,s2
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	176080e7          	jalr	374(ra) # 80003bea <iunlockput>
    end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	94c080e7          	jalr	-1716(ra) # 800043c8 <end_op>
    return -1;
    80005a84:	54fd                	li	s1,-1
    80005a86:	b761                	j	80005a0e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a88:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a8c:	04691783          	lh	a5,70(s2)
    80005a90:	02f99223          	sh	a5,36(s3)
    80005a94:	bf2d                	j	800059ce <sys_open+0xa4>
    itrunc(ip);
    80005a96:	854a                	mv	a0,s2
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	ffe080e7          	jalr	-2(ra) # 80003a96 <itrunc>
    80005aa0:	bfb1                	j	800059fc <sys_open+0xd2>
      fileclose(f);
    80005aa2:	854e                	mv	a0,s3
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	d76080e7          	jalr	-650(ra) # 8000481a <fileclose>
    iunlockput(ip);
    80005aac:	854a                	mv	a0,s2
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	13c080e7          	jalr	316(ra) # 80003bea <iunlockput>
    end_op();
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	912080e7          	jalr	-1774(ra) # 800043c8 <end_op>
    return -1;
    80005abe:	54fd                	li	s1,-1
    80005ac0:	b7b9                	j	80005a0e <sys_open+0xe4>

0000000080005ac2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ac2:	7175                	addi	sp,sp,-144
    80005ac4:	e506                	sd	ra,136(sp)
    80005ac6:	e122                	sd	s0,128(sp)
    80005ac8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005aca:	fffff097          	auipc	ra,0xfffff
    80005ace:	87e080e7          	jalr	-1922(ra) # 80004348 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ad2:	08000613          	li	a2,128
    80005ad6:	f7040593          	addi	a1,s0,-144
    80005ada:	4501                	li	a0,0
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	36e080e7          	jalr	878(ra) # 80002e4a <argstr>
    80005ae4:	02054963          	bltz	a0,80005b16 <sys_mkdir+0x54>
    80005ae8:	4681                	li	a3,0
    80005aea:	4601                	li	a2,0
    80005aec:	4585                	li	a1,1
    80005aee:	f7040513          	addi	a0,s0,-144
    80005af2:	00000097          	auipc	ra,0x0
    80005af6:	800080e7          	jalr	-2048(ra) # 800052f2 <create>
    80005afa:	cd11                	beqz	a0,80005b16 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	0ee080e7          	jalr	238(ra) # 80003bea <iunlockput>
  end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	8c4080e7          	jalr	-1852(ra) # 800043c8 <end_op>
  return 0;
    80005b0c:	4501                	li	a0,0
}
    80005b0e:	60aa                	ld	ra,136(sp)
    80005b10:	640a                	ld	s0,128(sp)
    80005b12:	6149                	addi	sp,sp,144
    80005b14:	8082                	ret
    end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	8b2080e7          	jalr	-1870(ra) # 800043c8 <end_op>
    return -1;
    80005b1e:	557d                	li	a0,-1
    80005b20:	b7fd                	j	80005b0e <sys_mkdir+0x4c>

0000000080005b22 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b22:	7135                	addi	sp,sp,-160
    80005b24:	ed06                	sd	ra,152(sp)
    80005b26:	e922                	sd	s0,144(sp)
    80005b28:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	81e080e7          	jalr	-2018(ra) # 80004348 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b32:	08000613          	li	a2,128
    80005b36:	f7040593          	addi	a1,s0,-144
    80005b3a:	4501                	li	a0,0
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	30e080e7          	jalr	782(ra) # 80002e4a <argstr>
    80005b44:	04054a63          	bltz	a0,80005b98 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b48:	f6c40593          	addi	a1,s0,-148
    80005b4c:	4505                	li	a0,1
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	2b8080e7          	jalr	696(ra) # 80002e06 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b56:	04054163          	bltz	a0,80005b98 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b5a:	f6840593          	addi	a1,s0,-152
    80005b5e:	4509                	li	a0,2
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	2a6080e7          	jalr	678(ra) # 80002e06 <argint>
     argint(1, &major) < 0 ||
    80005b68:	02054863          	bltz	a0,80005b98 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b6c:	f6841683          	lh	a3,-152(s0)
    80005b70:	f6c41603          	lh	a2,-148(s0)
    80005b74:	458d                	li	a1,3
    80005b76:	f7040513          	addi	a0,s0,-144
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	778080e7          	jalr	1912(ra) # 800052f2 <create>
     argint(2, &minor) < 0 ||
    80005b82:	c919                	beqz	a0,80005b98 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	066080e7          	jalr	102(ra) # 80003bea <iunlockput>
  end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	83c080e7          	jalr	-1988(ra) # 800043c8 <end_op>
  return 0;
    80005b94:	4501                	li	a0,0
    80005b96:	a031                	j	80005ba2 <sys_mknod+0x80>
    end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	830080e7          	jalr	-2000(ra) # 800043c8 <end_op>
    return -1;
    80005ba0:	557d                	li	a0,-1
}
    80005ba2:	60ea                	ld	ra,152(sp)
    80005ba4:	644a                	ld	s0,144(sp)
    80005ba6:	610d                	addi	sp,sp,160
    80005ba8:	8082                	ret

0000000080005baa <sys_chdir>:

uint64
sys_chdir(void)
{
    80005baa:	7135                	addi	sp,sp,-160
    80005bac:	ed06                	sd	ra,152(sp)
    80005bae:	e922                	sd	s0,144(sp)
    80005bb0:	e526                	sd	s1,136(sp)
    80005bb2:	e14a                	sd	s2,128(sp)
    80005bb4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bb6:	ffffc097          	auipc	ra,0xffffc
    80005bba:	f38080e7          	jalr	-200(ra) # 80001aee <myproc>
    80005bbe:	892a                	mv	s2,a0
  
  begin_op();
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	788080e7          	jalr	1928(ra) # 80004348 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bc8:	08000613          	li	a2,128
    80005bcc:	f6040593          	addi	a1,s0,-160
    80005bd0:	4501                	li	a0,0
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	278080e7          	jalr	632(ra) # 80002e4a <argstr>
    80005bda:	04054b63          	bltz	a0,80005c30 <sys_chdir+0x86>
    80005bde:	f6040513          	addi	a0,s0,-160
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	556080e7          	jalr	1366(ra) # 80004138 <namei>
    80005bea:	84aa                	mv	s1,a0
    80005bec:	c131                	beqz	a0,80005c30 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	d9a080e7          	jalr	-614(ra) # 80003988 <ilock>
  if(ip->type != T_DIR){
    80005bf6:	04449703          	lh	a4,68(s1)
    80005bfa:	4785                	li	a5,1
    80005bfc:	04f71063          	bne	a4,a5,80005c3c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c00:	8526                	mv	a0,s1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	e48080e7          	jalr	-440(ra) # 80003a4a <iunlock>
  iput(p->cwd);
    80005c0a:	15093503          	ld	a0,336(s2)
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	f34080e7          	jalr	-204(ra) # 80003b42 <iput>
  end_op();
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	7b2080e7          	jalr	1970(ra) # 800043c8 <end_op>
  p->cwd = ip;
    80005c1e:	14993823          	sd	s1,336(s2)
  return 0;
    80005c22:	4501                	li	a0,0
}
    80005c24:	60ea                	ld	ra,152(sp)
    80005c26:	644a                	ld	s0,144(sp)
    80005c28:	64aa                	ld	s1,136(sp)
    80005c2a:	690a                	ld	s2,128(sp)
    80005c2c:	610d                	addi	sp,sp,160
    80005c2e:	8082                	ret
    end_op();
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	798080e7          	jalr	1944(ra) # 800043c8 <end_op>
    return -1;
    80005c38:	557d                	li	a0,-1
    80005c3a:	b7ed                	j	80005c24 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c3c:	8526                	mv	a0,s1
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	fac080e7          	jalr	-84(ra) # 80003bea <iunlockput>
    end_op();
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	782080e7          	jalr	1922(ra) # 800043c8 <end_op>
    return -1;
    80005c4e:	557d                	li	a0,-1
    80005c50:	bfd1                	j	80005c24 <sys_chdir+0x7a>

0000000080005c52 <sys_exec>:

uint64
sys_exec(void)
{
    80005c52:	7145                	addi	sp,sp,-464
    80005c54:	e786                	sd	ra,456(sp)
    80005c56:	e3a2                	sd	s0,448(sp)
    80005c58:	ff26                	sd	s1,440(sp)
    80005c5a:	fb4a                	sd	s2,432(sp)
    80005c5c:	f74e                	sd	s3,424(sp)
    80005c5e:	f352                	sd	s4,416(sp)
    80005c60:	ef56                	sd	s5,408(sp)
    80005c62:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c64:	08000613          	li	a2,128
    80005c68:	f4040593          	addi	a1,s0,-192
    80005c6c:	4501                	li	a0,0
    80005c6e:	ffffd097          	auipc	ra,0xffffd
    80005c72:	1dc080e7          	jalr	476(ra) # 80002e4a <argstr>
    return -1;
    80005c76:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c78:	0c054a63          	bltz	a0,80005d4c <sys_exec+0xfa>
    80005c7c:	e3840593          	addi	a1,s0,-456
    80005c80:	4505                	li	a0,1
    80005c82:	ffffd097          	auipc	ra,0xffffd
    80005c86:	1a6080e7          	jalr	422(ra) # 80002e28 <argaddr>
    80005c8a:	0c054163          	bltz	a0,80005d4c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c8e:	10000613          	li	a2,256
    80005c92:	4581                	li	a1,0
    80005c94:	e4040513          	addi	a0,s0,-448
    80005c98:	ffffb097          	auipc	ra,0xffffb
    80005c9c:	060080e7          	jalr	96(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ca0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ca4:	89a6                	mv	s3,s1
    80005ca6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ca8:	02000a13          	li	s4,32
    80005cac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cb0:	00391793          	slli	a5,s2,0x3
    80005cb4:	e3040593          	addi	a1,s0,-464
    80005cb8:	e3843503          	ld	a0,-456(s0)
    80005cbc:	953e                	add	a0,a0,a5
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	0ae080e7          	jalr	174(ra) # 80002d6c <fetchaddr>
    80005cc6:	02054a63          	bltz	a0,80005cfa <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cca:	e3043783          	ld	a5,-464(s0)
    80005cce:	c3b9                	beqz	a5,80005d14 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	e3c080e7          	jalr	-452(ra) # 80000b0c <kalloc>
    80005cd8:	85aa                	mv	a1,a0
    80005cda:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cde:	cd11                	beqz	a0,80005cfa <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ce0:	6605                	lui	a2,0x1
    80005ce2:	e3043503          	ld	a0,-464(s0)
    80005ce6:	ffffd097          	auipc	ra,0xffffd
    80005cea:	0d8080e7          	jalr	216(ra) # 80002dbe <fetchstr>
    80005cee:	00054663          	bltz	a0,80005cfa <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cf2:	0905                	addi	s2,s2,1
    80005cf4:	09a1                	addi	s3,s3,8
    80005cf6:	fb491be3          	bne	s2,s4,80005cac <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfa:	10048913          	addi	s2,s1,256
    80005cfe:	6088                	ld	a0,0(s1)
    80005d00:	c529                	beqz	a0,80005d4a <sys_exec+0xf8>
    kfree(argv[i]);
    80005d02:	ffffb097          	auipc	ra,0xffffb
    80005d06:	d0e080e7          	jalr	-754(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0a:	04a1                	addi	s1,s1,8
    80005d0c:	ff2499e3          	bne	s1,s2,80005cfe <sys_exec+0xac>
  return -1;
    80005d10:	597d                	li	s2,-1
    80005d12:	a82d                	j	80005d4c <sys_exec+0xfa>
      argv[i] = 0;
    80005d14:	0a8e                	slli	s5,s5,0x3
    80005d16:	fc040793          	addi	a5,s0,-64
    80005d1a:	9abe                	add	s5,s5,a5
    80005d1c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005d20:	e4040593          	addi	a1,s0,-448
    80005d24:	f4040513          	addi	a0,s0,-192
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	178080e7          	jalr	376(ra) # 80004ea0 <exec>
    80005d30:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d32:	10048993          	addi	s3,s1,256
    80005d36:	6088                	ld	a0,0(s1)
    80005d38:	c911                	beqz	a0,80005d4c <sys_exec+0xfa>
    kfree(argv[i]);
    80005d3a:	ffffb097          	auipc	ra,0xffffb
    80005d3e:	cd6080e7          	jalr	-810(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d42:	04a1                	addi	s1,s1,8
    80005d44:	ff3499e3          	bne	s1,s3,80005d36 <sys_exec+0xe4>
    80005d48:	a011                	j	80005d4c <sys_exec+0xfa>
  return -1;
    80005d4a:	597d                	li	s2,-1
}
    80005d4c:	854a                	mv	a0,s2
    80005d4e:	60be                	ld	ra,456(sp)
    80005d50:	641e                	ld	s0,448(sp)
    80005d52:	74fa                	ld	s1,440(sp)
    80005d54:	795a                	ld	s2,432(sp)
    80005d56:	79ba                	ld	s3,424(sp)
    80005d58:	7a1a                	ld	s4,416(sp)
    80005d5a:	6afa                	ld	s5,408(sp)
    80005d5c:	6179                	addi	sp,sp,464
    80005d5e:	8082                	ret

0000000080005d60 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d60:	7139                	addi	sp,sp,-64
    80005d62:	fc06                	sd	ra,56(sp)
    80005d64:	f822                	sd	s0,48(sp)
    80005d66:	f426                	sd	s1,40(sp)
    80005d68:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	d84080e7          	jalr	-636(ra) # 80001aee <myproc>
    80005d72:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d74:	fd840593          	addi	a1,s0,-40
    80005d78:	4501                	li	a0,0
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	0ae080e7          	jalr	174(ra) # 80002e28 <argaddr>
    return -1;
    80005d82:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d84:	0e054063          	bltz	a0,80005e64 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d88:	fc840593          	addi	a1,s0,-56
    80005d8c:	fd040513          	addi	a0,s0,-48
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	de0080e7          	jalr	-544(ra) # 80004b70 <pipealloc>
    return -1;
    80005d98:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d9a:	0c054563          	bltz	a0,80005e64 <sys_pipe+0x104>
  fd0 = -1;
    80005d9e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005da2:	fd043503          	ld	a0,-48(s0)
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	50a080e7          	jalr	1290(ra) # 800052b0 <fdalloc>
    80005dae:	fca42223          	sw	a0,-60(s0)
    80005db2:	08054c63          	bltz	a0,80005e4a <sys_pipe+0xea>
    80005db6:	fc843503          	ld	a0,-56(s0)
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	4f6080e7          	jalr	1270(ra) # 800052b0 <fdalloc>
    80005dc2:	fca42023          	sw	a0,-64(s0)
    80005dc6:	06054863          	bltz	a0,80005e36 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dca:	4691                	li	a3,4
    80005dcc:	fc440613          	addi	a2,s0,-60
    80005dd0:	fd843583          	ld	a1,-40(s0)
    80005dd4:	68a8                	ld	a0,80(s1)
    80005dd6:	ffffc097          	auipc	ra,0xffffc
    80005dda:	8d4080e7          	jalr	-1836(ra) # 800016aa <copyout>
    80005dde:	02054063          	bltz	a0,80005dfe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005de2:	4691                	li	a3,4
    80005de4:	fc040613          	addi	a2,s0,-64
    80005de8:	fd843583          	ld	a1,-40(s0)
    80005dec:	0591                	addi	a1,a1,4
    80005dee:	68a8                	ld	a0,80(s1)
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	8ba080e7          	jalr	-1862(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005df8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dfa:	06055563          	bgez	a0,80005e64 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dfe:	fc442783          	lw	a5,-60(s0)
    80005e02:	07e9                	addi	a5,a5,26
    80005e04:	078e                	slli	a5,a5,0x3
    80005e06:	97a6                	add	a5,a5,s1
    80005e08:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e0c:	fc042503          	lw	a0,-64(s0)
    80005e10:	0569                	addi	a0,a0,26
    80005e12:	050e                	slli	a0,a0,0x3
    80005e14:	9526                	add	a0,a0,s1
    80005e16:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e1a:	fd043503          	ld	a0,-48(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	9fc080e7          	jalr	-1540(ra) # 8000481a <fileclose>
    fileclose(wf);
    80005e26:	fc843503          	ld	a0,-56(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	9f0080e7          	jalr	-1552(ra) # 8000481a <fileclose>
    return -1;
    80005e32:	57fd                	li	a5,-1
    80005e34:	a805                	j	80005e64 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e36:	fc442783          	lw	a5,-60(s0)
    80005e3a:	0007c863          	bltz	a5,80005e4a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e3e:	01a78513          	addi	a0,a5,26
    80005e42:	050e                	slli	a0,a0,0x3
    80005e44:	9526                	add	a0,a0,s1
    80005e46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e4a:	fd043503          	ld	a0,-48(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	9cc080e7          	jalr	-1588(ra) # 8000481a <fileclose>
    fileclose(wf);
    80005e56:	fc843503          	ld	a0,-56(s0)
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	9c0080e7          	jalr	-1600(ra) # 8000481a <fileclose>
    return -1;
    80005e62:	57fd                	li	a5,-1
}
    80005e64:	853e                	mv	a0,a5
    80005e66:	70e2                	ld	ra,56(sp)
    80005e68:	7442                	ld	s0,48(sp)
    80005e6a:	74a2                	ld	s1,40(sp)
    80005e6c:	6121                	addi	sp,sp,64
    80005e6e:	8082                	ret

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
    80005eb0:	d71fc0ef          	jal	ra,80002c20 <kerneltrap>
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
    80005f4c:	b7a080e7          	jalr	-1158(ra) # 80001ac2 <cpuid>
  
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
    80005f84:	b42080e7          	jalr	-1214(ra) # 80001ac2 <cpuid>
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
    80005fac:	b1a080e7          	jalr	-1254(ra) # 80001ac2 <cpuid>
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
    8000601c:	69e080e7          	jalr	1694(ra) # 800026b6 <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("virtio_disk_intr 1");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	78050513          	addi	a0,a0,1920 # 800087a8 <syscalls+0x330>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	78850513          	addi	a0,a0,1928 # 800087c0 <syscalls+0x348>
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
    80006056:	78658593          	addi	a1,a1,1926 # 800087d8 <syscalls+0x360>
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
    80006160:	68c50513          	addi	a0,a0,1676 # 800087e8 <syscalls+0x370>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	69c50513          	addi	a0,a0,1692 # 80008808 <syscalls+0x390>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	6ac50513          	addi	a0,a0,1708 # 80008828 <syscalls+0x3b0>
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
    80006242:	2ec080e7          	jalr	748(ra) # 8000252a <sleep>
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
    80006310:	21e080e7          	jalr	542(ra) # 8000252a <sleep>
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
    80006482:	238080e7          	jalr	568(ra) # 800026b6 <wakeup>
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
    800064c8:	38450513          	addi	a0,a0,900 # 80008848 <syscalls+0x3d0>
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

# lab4实验报告

组长

- 虞佳焕 PB17121687

小组成员

- 张博文 PB17000215
- 彭定澜 PB17111607

## 实验要求

1. 编译配置支持 RISC-V 后端的 LLVM;
2. 编译配置 RISC-V GNU Toolchain;
3. 编译配置 Spike RISC-V 模拟器和 Spike-pk;
4. 熟悉 RISC-V 指令及汇编语言;
5. 探究从 IR 生成 RISC-V 汇编的流程;
6. 探究如何使用 Spike 模拟器执行 RISC-V 程序;
7. 阅读 LLVM 源码中的 RegAllocFast 的代码，理解其大概的执行流程，并探究几个特殊变量的作用；
8. 阅读龙书 Code Generation 中关于寄存器的选择与分配的内容，比较其和 LLVM 的实现之间的不同。

## 报告内容 

#### 1. RISC-V 机器代码的生成和运行

##### 1.1 LLVM 8.0.1 适配 RISC-V

```bash
# 下载
$ wget https://github.com/llvm/llvm-project/releases/download/llvmorg-8.0.1/llvm-8.0.1.src.tar.xz
$ wget https://github.com/llvm/llvm-project/releases/download/llvmorg-8.0.1/cfe-8.0.1.src.tar.xz

# 解压缩
$ tar xvf llvm-8.0.1.src.tar.xz
$ mv llvm-8.0.1.src llvm
$ tar xvf cfe-8.0.1.src.tar.xz
$ mv cfe-8.0.1.src llvm/tools/clang

$ mkdir build
$ cd build

# 编译, 安装目录选择 /opt/llvm-8.0.1-release
$ cmake ../llvm-8.0.1.src -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-8.0.1-release -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RISCV -DLLVM_TARGETS_TO_BUILD=X86
$ sudo make install -j64

# 配置环境变量
$ echo 'export LLVM=/opt/llvm-8.0.1-release' >> ~/.zshrc
$ echo 'export PATH=$PATH:$LLVM/bin' >> ~/.zshrc
$ source ~/.zshrc

# 此时配置了 RISCV 后端的 LLVM 即可用
$ clang --target=riscv64 -v
clang version 8.0.1 (tags/RELEASE_801/final)
Target: riscv64
Thread model: posix
InstalledDir: /opt/llvm-8.0.1-release/bin
```

`cmake` 的几个参数：

- `-DCMAKE_BUILD_TYPE=Release`: 在编译过程中加入 `CMAKE_BUILD_TYPE=Release` 这个宏，编译 `Release` 版本的二进制文件.
- `-DCMAKE_INSTALL_PREFIX=/opt/llvm-8.0.1-release`: 指定安装目录为 `/opt/llvm-8.0.1-release`.
- `-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RISCV`: 开启实验性的 RISCV 后端支持.
- `-DLLVM_TARGETS_TO_BUILD=X86`: 开启 x86 后端支持.

##### 1.2 lab3-0 GCD 样例 LLVM IR 生成 RISC-V 源码的过程

1. **首先需要编译 riscv-gnu-toolchain**.

   ```bash
   # 这个 clone 很慢，所以实际上采用了别的手段加速，首先 git clone 到境外 VPS, 然后 scp 到编译服务器上, 完成编译后再 scp 到本地
   $ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain

   # 安装依赖
   $ sudo apt install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

   $ cd riscv-gnu-toolchain

   # 编译, 安装路径为 /opt/riscv, 并根据文档中的要求，添加 --with-abi=lp64 选项
   $ ./configure --prefix=/opt/riscv --with-abi=lp64
   $ sudo make -j64

   # 配置环境变量
   $ echo 'export RISCV=/opt/riscv' >> ~/.zshrc
   $ echo 'export PATH=$PATH:$RISCV/bin' >> ~/.zshrc
   $ source ~/.zshrc

   # 此时 riscv64-unknown-elf-gcc 即可用
   $ riscv64-unknown-elf-gcc  -v
   Using built-in specs.
   COLLECT_GCC=riscv64-unknown-elf-gcc
   COLLECT_LTO_WRAPPER=/opt/riscv/libexec/gcc/riscv64-unknown-elf/9.2.0/lto-wrapper
   Target: riscv64-unknown-elf
   Configured with: /home/user/yjh-llvm/riscv-gnu-toolchain-no-git/riscv-gcc/configure --target=riscv64-unknown-elf --prefix=/opt/riscv --disable-shared --disable-threads --enable-languages=c,c++ --with-system-zlib --enable-tls --with-newlib --with-sysroot=/opt/riscv/riscv64-unknown-elf --with-native-system-header-dir=/include --disable-libmudflap --disable-libssp --disable-libquadmath --disable-libgomp --disable-nls --disable-tm-clone-registry --src=.././riscv-gcc --disable-multilib --with-abi=lp64 --with-arch=rv64imafdc --with-tune=rocket 'CFLAGS_FOR_TARGET=-Os   -mcmodel=medlow' 'CXXFLAGS_FOR_TARGET=-Os   -mcmodel=medlow'
   Thread model: single
   gcc version 9.2.0 (GCC)
   ```

   `./configure` 有两个参数:

   - `--prefix=/opt/riscv`: 指定 riscv-gnu-toolchain 的安装路径.
   - `--with-abi=lp64`: 指定采用的 ABI 类别, ABI 意为 Application Binary Interface, 主要规定了数据类型的宽度以即参数传递时浮点数据的传递方式, 主要取值及含义如下;

   |  ABI   | `sizeof(int)` | `sizeof(long)` | `sizeof(void *)` | 需要 RISCV 浮点扩展 | float 传递方式 | double 传递方式 |
   | :----: | :-----------: | :------------: | :--------------: | :-----------------: | :------------: | :-------------: |
   | ilp32  |      32       |       32       |        32        |         无          |     栈传递     |     栈传递      |
   | ilp32f |      32       |       32       |        32        |          F          |   浮点寄存器   |     栈传递      |
   | ilp32d |      32       |       32       |        32        |        F, D         |   浮点寄存器   |   浮点寄存器    |
   |  lp64  |      32       |       64       |        64        |         无          |     栈传递     |     栈传递      |
   | lp64f  |      32       |       64       |        64        |          F          |   浮点寄存器   |     栈传递      |
   | lp64d  |      32       |       64       |        64        |        F, D         |   浮点寄存器   |   浮点寄存器    |

   由于当前 LLVM 的 RISCV 后端还是实验性的, 需要限定 ABI 为 `lp64` 以保证兼容性.

2. **然后生成 IR**:

   ```bash
   # 转化成 IR
   $ clang -emit-llvm --target=riscv64 -march=rv64gc gcd.c -S -o gcd.ll -I/opt/riscv/riscv64-unknown-elf/include
   ```

   生成的 IR 为:

   ```llvm
   ; ModuleID = 'gcd.c'
   source_filename = "gcd.c"
   target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128" ; 见代码后解释
   target triple = "riscv64"  ; 见代码后解释

   ; Function Attrs: noinline nounwind optnone
   define dso_local signext i32 @gcd(i32 signext, i32 signext) #0 {
     %3 = alloca i32, align 4
     %4 = alloca i32, align 4
     %5 = alloca i32, align 4
     store i32 %0, i32* %4, align 4
     store i32 %1, i32* %5, align 4
     %6 = load i32, i32* %5, align 4
     %7 = icmp eq i32 %6, 0
     br i1 %7, label %8, label %10

   ; <label>:8:                                      ; preds = %2
     %9 = load i32, i32* %4, align 4
     store i32 %9, i32* %3, align 4
     br label %20

   ; <label>:10:                                     ; preds = %2
     %11 = load i32, i32* %5, align 4
     %12 = load i32, i32* %4, align 4
     %13 = load i32, i32* %4, align 4
     %14 = load i32, i32* %5, align 4
     %15 = sdiv i32 %13, %14
     %16 = load i32, i32* %5, align 4
     %17 = mul nsw i32 %15, %16
     %18 = sub nsw i32 %12, %17
     %19 = call signext i32 @gcd(i32 signext %11, i32 signext %18)
     store i32 %19, i32* %3, align 4
     br label %20

   ; <label>:20:                                     ; preds = %10, %8
     %21 = load i32, i32* %3, align 4
     ret i32 %21
   }

   ; Function Attrs: noinline nounwind optnone
   define dso_local signext i32 @main() #0 {
     %1 = alloca i32, align 4
     %2 = alloca i32, align 4
     %3 = alloca i32, align 4
     %4 = alloca i32, align 4
     store i32 0, i32* %1, align 4
     store i32 72, i32* %2, align 4
     store i32 18, i32* %3, align 4
     %5 = load i32, i32* %2, align 4
     %6 = load i32, i32* %3, align 4
     %7 = icmp slt i32 %5, %6
     br i1 %7, label %8, label %12

   ; <label>:8:                                      ; preds = %0
     %9 = load i32, i32* %2, align 4
     store i32 %9, i32* %4, align 4
     %10 = load i32, i32* %3, align 4
     store i32 %10, i32* %2, align 4
     %11 = load i32, i32* %4, align 4
     store i32 %11, i32* %3, align 4
     br label %12

   ; <label>:12:                                     ; preds = %8, %0
     %13 = load i32, i32* %2, align 4
     %14 = load i32, i32* %3, align 4
     %15 = call signext i32 @gcd(i32 signext %13, i32 signext %14)
     ret i32 %15
   }

   attributes #0 = { noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-features"="+a,+c,+d,+f,+m" "unsafe-fp-math"="false" "use-soft-float"="false" } ; 部分内容见代码后解释

   !llvm.module.flags = !{!0}
   !llvm.ident = !{!1}

   !0 = !{i32 1, !"wchar_size", i32 4}
   !1 = !{!"clang version 8.0.1 (tags/RELEASE_801/final)"}
   ```

   IR 中有部分平台相关的内容:

   - `target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"`: 指明内存中的数据布局. 以每个 `-` 为间隔, 含义分别为: 小端, 采用 ELF 命名重整方式 (私有符号加 `.L` 前缀), 64 bit 对齐的 64 bit 指针, i64 使用 64 bit 对齐, i128 使用 128 bit 对齐, CPU 原生支持 64 bit 整数, 栈是 128 bit 自然对齐的.
   - `target triple = "riscv64"`: 通常为一个三元组 `<arch><sub>-<vendor>-<sys>-<abi>`, 指定目标架构及其版本, 制造商, 操作系统, ABI. 最常见的如 `x86_64-unknown-linux-gnu`. 此处仅指定了 `arch` 为 `riscv64`, 忽略了其他信息, 由 `llc` 自动决定.
   - `"target-features"="+a,+c,+d,+f,+m"`: 指明目标 RISCV 体系结构支持 A (原子操作), C (压缩指令), D (双精度浮点数), F (单精度浮点数), M (乘除法) 这些扩展.

3. **然后生成 RISCV 汇编**:

   ```bash
   # 转化成 RISCV 汇编
   $ llc -march=riscv64 gcd.ll -o gcd.s
   ```

   生成的 RISCV 汇编 (**其中加了阅读注释**) 为:

   ```riscv
     .text
     .file	"gcd.c"
     .globl	gcd                     # gcd 函数是全局可见的
     .p2align	2					# 代表指令 2^2 =4 bytes 对齐
     .type	gcd,@function			# 指明 gcd 这个符号是一个函数
   gcd:                                    #@gcd
   # %bb.0:
     addi	sp, sp, -48			# 分配 48 byte 的栈空间
     sd	ra, 40(sp)				# 保存返回地址
     sd	s0, 32(sp)				# 以下 3 句是把 gcd 中要用到的 calling convention 中规定的被调函数保存的寄存器保存
     sd	s1, 24(sp)
     sd	s2, 16(sp)
     addi	s0, sp, 48			# s0 作为帧指针
     sw	a0, -40(s0)				# 保存参数 u,v
     sw	a1, -44(s0)
     lw	a0, -44(s0)
     bnez	a0, .LBB0_2 # if (v==0)
     j	.LBB0_1
   .LBB0_1:
     lw	a0, -40(s0)
     sw	a0, -36(s0)			# 把 u 保存到返回值
     j	.LBB0_3
   .LBB0_2:				# else
     lw	s2, -40(s0)			# 加载 u
     lw	s1, -44(s0)			# 加载 v
     mv	a0, s2
     mv	a1, s1
     call	__divdi3		# 调用软除法计算 u/v
     mv	a1, s1
     call	__muldi3		# 调用软乘法计算 u/v*v
     subw	a1, s2, a0
     mv	a0, s1
     call	gcd				# gcd(v, u - u / v * v)
     sw	a0, -36(s0)			# a0 中是 gcd(v, u - u / v * v) 的返回值,保存到本帧栈的返回值位置
     j	.LBB0_3
   .LBB0_3:					# 返回语句部分
     lw	a0, -36(s0)			# 把返回值放到返回值寄存器 a0
     ld	s2, 16(sp)			# 恢复保存的寄存器
     ld	s1, 24(sp)
     ld	s0, 32(sp)
     ld	ra, 40(sp)			# 加载返回地址
     addi	sp, sp, 48		# 取消栈空间分配
     ret
   .Lfunc_end0:
     .size	gcd, .Lfunc_end0-gcd
                                           # -- End function
     .globl	main                # main 函数是全局可见的
     .p2align	2				# 代表指令 2^2 =4 bytes 对齐
     .type	main,@function		# 指明 main 这个符号是一个函数
   main:                                   # @main
   # %bb.0:
     addi	sp, sp, -32		# 分配栈空间 32 bytes
     sd	ra, 24(sp)			# 保存返回地址
     sd	s0, 16(sp)			# 保存栈指针
     addi	s0, sp, 32		# s0 作为帧指针
     sw	zero, -20(s0)
     addi	a0, zero, 72	# x=72
     sw	a0, -24(s0)			# 保存 x
     addi	a0, zero, 18	# y=18
     sw	a0, -28(s0)			# 保存 y
     lw	a0, -24(s0)			# 加载 x
     lw	a1, -28(s0)			# 加载 y
     bge	a0, a1, .LBB1_2		# if(x<y)
     j	.LBB1_1
   .LBB1_1:
     lw	a0, -24(s0)			# 交换 x y
     sw	a0, -32(s0)
     lw	a0, -28(s0)
     sw	a0, -24(s0)
     lw	a0, -32(s0)
     sw	a0, -28(s0)
     j	.LBB1_2
   .LBB1_2:					# 返回语句部分
     lw	a0, -24(s0)			# 加载 x
     lw	a1, -28(s0)			# 加载 y
     call	gcd				# a0=gcd(x,y)
     ld	s0, 16(sp)			# 加载保存的 s0
     ld	ra, 24(sp)			# 加载保存的返回地址
     addi	sp, sp, 32		# 取消栈分配
     ret
   .Lfunc_end1:
     .size	main, .Lfunc_end1-main
                                           # -- End function

     .ident	"clang version 8.0.1 (tags/RELEASE_801/final)"
     .section	".note.GNU-stack","",@progbits
   ```

##### 1.3 安装 Spike 模拟器并运行上述生成的 RISC-V 源码

首先编译 spike 和 pk:

```bash
$ git clone https://github.com/riscv/riscv-isa-sim.git
# 安装依赖
$ sudo apt install device-tree-compiler
$ cd riscv-isa-sim
$ mkdir build
$ cd build
# 编译, 此时 $RISCV 已配置, 编译过程中会把 spike 安装到 $RISCV/bin
$ ../configure --prefix=$RISCV
$ make -j8
$ sudo make install -j8
# 此时 spike 命令可用

$ git clone https://github.com/riscv/riscv-pk.git
$ cd riscv-pk
$ mkdir build
$ cd build
# 编译
# host 指定为 riscv64-unknown-elf, 是因为 pk 其实是运行在 spike 环境里的"代理", 它执行的也是 RISCV 指令
$ ../configure --prefix=$RISCV --host=riscv64-unknown-elf
$ make -j8
$ make install -j8
# 此时即可使用 spike pk xxx 运行带 IO 系统调用的 RISCV 程序
```

Spike 可以模拟 RISCV 指令的执行, 但并不提供一些 I/O 相关的系统调用的支持. 为了使 spike 中的 RISCV 程序能输出, 需要 pk 这个 "内核代理", 给 RISCV 程序提供一个运行环境, 将其 I/O 相关的系统调用 "代理" 到运行 spike 的 x86 主机上.

最后运行 `gcd.riscv`

```bash
# 编译运行
$ riscv64-unknown-elf-gcc gcd.s -o gcd.riscv
$ spike pk gcd.riscv
bbl loader
$ echo $? # 获得返回值
18
```

可以看到返回值 18 与预期一致.

#### 2. LLVM源码阅读与理解

- RegAllocFast.cpp 中的几个问题

  * *RegAllocFast* 函数的执行流程？

    答：
    - 初始化；
    - 进入每一个基本块进行寄存器分配；
    - 在每一个基本块中，将所有还活跃的寄存器设置为保留状态，之后对每一条机器指令进行寄存器分配；
    - 对每一条机器指令进行寄存器分配时，通过 *allocateInstruction* 的四次扫描（具体功能见下题回答），对所有的定值和引用进行分配，删除失效的定值，对可能的重复引用进行合并；
    - 最后清除所有虚拟寄存器，清除所有保存在栈中的虚拟寄存器的数据，结束分配过程。

  * *allocateInstruction* 函数有几次扫描过程以及每一次扫描的功能？

    答：
    - 4 次扫描过程；
    - 第一次扫描：找到最后一个虚拟寄存器操作数，处理 physreg 的定值和引用，并处理一些特殊情况（例如内联汇编，多重定义或绑定等）；
    - 第二次扫描：对虚拟寄存器的引用进行分配，并且处理未定值的引用，如果存在 EarlyClobbers 和 TiedOps 的情况，则重新标记指令使用的寄存器，在函数调用之前将所有的 dirty virtregs 保存到内存中；
    - 第三次扫描：在对 virtreg 的定值进行分配之前，将所有 physreg 定值的寄存器标记为已经使用；
    - 第四次扫描：对所有定值进行分配，删除失效的定值，并为可能的合并做好准备。

  * *calcSpillCost* 函数的执行流程？

    答：
    1. 如果该物理寄存器必须被使用，则不能将其内容存放在内存中；
    2. 如果该物理寄存器是 free，那么存放的原内容不用被保存到内存中，代价为 0；
    3. 如果该物理寄存器是 reserved，那么这个寄存器是被保留的，不能用作别的用途；
    4. 如果该物理寄存器与虚拟寄存器关联，其代价与虚拟寄存器是否干净有关；
    5. 如果该物理寄存器是 disabled，则对其所有的别名进行上面的 2，3，4 操作，但是有些不同的是，别名的状态如果是 free，则总代价要加 1，别名如果与物理寄存器关联，总代价加与虚拟寄存器是否干净的一个子代价。

  * *hasTiedOps*，*hasPartialRedefs，hasEarlyClobbers* 变量的作用？

    答：
    - *hasTiedOps* 检查操作数是否特定限制（例如：必须绑定使用某些寄存器）；
    - *hasPartialRedefs* 检查是否存在子寄存器，并且对进行子寄存器赋值、读取；
    - *hasEarlyClobbers* 检查是否存在读取所有输入寄存器之前就进行写入目标操作数的情况。

- 书上所讲的算法与LLVM源码中的实现之间的不同点

  答：
  - LLVM 考虑了物理寄存器的显式使用（例如内联汇编）和目标架构中操作数与特定寄存器中的绑定，这样做是因为部分工程项目需要显式使用寄存器（例如内联汇编），这就需要考虑之前分配的物理寄存器与显式使用的物理寄存器之间的冲突，并且部分目标平台存在于特定寄存器绑定的指令（例如 x86 的乘除法），这些都需要在代码生成阶段特殊考虑并处理；
  - LLVM 在计算 spillcost 时，使用的代价计算方法与书中的算法不同，这样做的原因是寄存器有不同的状态，在不同的状态下，将其内容保存到栈中的成本不同，相比书中单调的“得分”（保存指令个数）作为评价标准，这样做更符合实际处理情况；
  - LLVM 的实现在函数调用之前会将所有的虚拟寄存器中的内容保存到栈中，原因是当异常被抛出时，landing pad（处理异常的部分）可以在栈中找到所有虚拟寄存器的内容，这符合异常处理的要求。



## 组内讨论内容

## 讨论1

时间：12 月 18 日 20 时到 22 时

地点：图书馆 205

参与者：彭定澜、张博文

主题：完成任务分配，初步阅读 RegAllocFast 源代码。

## 讨论2

时间：12 月 19 日 19 时到 23 时

地点：图书馆 205

参与者：虞佳焕、彭定澜、张博文

主题：阅读 calcSpillCost 函数以及更多源码细节，并继续初步完成文档撰写。

## 讨论3

时间：12 月 6 日 19 时到 23 时

地点：图书馆 2 楼

参与者：彭定澜、张博文

主题：完成文档撰写。

## 实验总结

- ；
- 初步了解了 LLVM 中的寄存器分配流程和策略；
- 了解了 LLVM 寄存器分配策略与龙书的不同之处。

## 实验反馈

对本次实验的建议（可选 不会评分）
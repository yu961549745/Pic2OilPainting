# STASM Matlab Interface
+ 在 `compile.m` 中配置 OpenCV 和 STASM 的相关路径
+ 确保已经安装了 Matlab 可以识别的 C++ 编译器 （通过 `mex -setup` 进行测试）
+ 运行 `compile.m` 即可编译得到 `mexStasm.mex*`
+ 复制 stasm 源码下的 `data` 文件夹到根目录
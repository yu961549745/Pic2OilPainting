clc,clear,close all;
f=OilGUI();
handles=guihandles(f);
jlog=java.awt.TextArea;
jlog.setEditable(false);
jlog.setBackground(java.awt.Color.WHITE);
hlog=javacomponent(jlog,getpixelposition(handles.log),handles.figure);
setappdata(handles.figure,'hlog',hlog);
clear;
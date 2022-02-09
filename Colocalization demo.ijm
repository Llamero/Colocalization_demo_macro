close("*");
setBatchMode(true);
image_radius = 256;
n_frames = 64;
Dialog.create("Two sphere colocalization demo");
font_size = 16;
Dialog.addMessage("---Image---");
Dialog.addNumber("Width:", image_radius);
Dialog.addNumber("Height:", image_radius);
Dialog.addNumber("Depth:", image_radius);
Dialog.addNumber("Frames:", n_frames);
Dialog.addMessage("---Sphere2---")
Dialog.addNumber("Radius 1:", image_radius/4);
Dialog.addNumber("Radius 2:", image_radius/4);
Dialog.addNumber("Z-overlap:", 20);
Dialog.addCheckbox("Show colocalization", true);
Dialog.addNumber("Font size:", font_size);
Dialog.show();
i_width = Dialog.getNumber();
i_height = Dialog.getNumber();
i_depth = Dialog.getNumber();
n_frames = Dialog.getNumber();
s1_radius = Dialog.getNumber();
s2_radius = Dialog.getNumber();
s_overlap = Dialog.getNumber();
show_coloc = Dialog.getCheckbox();
font_size = Dialog.getNumber();
setFont("Sans Serif", font_size);
//Generate sphere movie
y_center = round(i_height/2);
x_center = i_width;
z_center = round((i_depth/2)-s1_radius+(s_overlap/2));
run("3D Draw Shape", "size="+2*i_width+","+i_height+","+i_depth+" center="+x_center+","+y_center+","+z_center+" radius="+s1_radius+","+s1_radius+","+s1_radius+" vector1=1.0,0.0,0.0 vector2=0.0,1.0,0.0 res_xy=1.000 res_z=1.000 unit=pix value=255 display=[New stack]");
selectWindow("Shape3D");
rename("ref1");
x_center_step = (i_width)/n_frames;
for(a=1; a<=n_frames; a++){
	showProgress(a, n_frames*2);
	selectWindow("ref1");
	x_center = round(a*x_center_step);
	makeRectangle(x_center, 0, i_width, i_height);
	run("Duplicate...", "title=Shape3D duplicate");
	if(isOpen("C1")){
		run("Concatenate...", "  title=C1 open image1=C1 image2=Shape3D");
	}
	else{
		selectWindow("Shape3D");
		rename("C1");
	}
}
close("ref1");

y_center = round(i_height/2);
x_center = i_width;
z_center = round((i_depth/2)+s2_radius-(s_overlap/2));
run("3D Draw Shape", "size="+2*i_width+","+i_height+","+i_depth+" center="+x_center+","+y_center+","+z_center+" radius="+s2_radius+","+s2_radius+","+s2_radius+" vector1=1.0,0.0,0.0 vector2=0.0,1.0,0.0 res_xy=1.000 res_z=1.000 unit=pix value=255 display=[New stack]");
selectWindow("Shape3D");
rename("ref2");
x_center_step = (i_width)/n_frames;
for(a=1; a<=n_frames; a++){
	showProgress(a+n_frames, n_frames*2);
	selectWindow("ref2");
	x_center = round(i_width-a*x_center_step);
	makeRectangle(x_center, 0, i_width, i_height);
	run("Duplicate...", "title=Shape3D duplicate");
	if(isOpen("C2")){
		run("Concatenate...", "  title=C2 open image1=C2 image2=Shape3D");
	}
	else{
		selectWindow("Shape3D");
		rename("C2");
	}
}
close("ref2");

//Generate 3D coloc stack
run("Merge Channels...", "c2=C1 c6=C2 create ignore");
run("Split Channels");
imageCalculator("AND create stack", "C1-Merged","C2-Merged");
selectWindow("Result of C1-Merged");
rename("3D coloc");

//Measure 3D coloc
selectWindow("C1-Merged");
run("Duplicate...", "title=[C1_Volume] duplicate frames=32");
selectWindow("C1_Volume");
Stack.getStatistics(dummy, s1_volume, dummy, dummy, dummy);
close("C1_Volume");
selectWindow("C2-Merged");
run("Duplicate...", "title=[C2_Volume] duplicate frames=32");
selectWindow("C2_Volume");
Stack.getStatistics(dummy, s2_volume, dummy, dummy, dummy);
close("C2_Volume");
coloc_array_3D = newArray(n_frames);
selectWindow("3D coloc");
for(a=1; a<=n_frames; a++){
	selectWindow("3D coloc");
	run("Duplicate...", "title=frame duplicate frames=" + a);
	selectWindow("frame");
	Stack.getStatistics(dummy, coloc_volume, dummy, dummy, dummy);
	coloc_array_3D[a-1] = coloc_volume;
	close("frame");
}

//Measure 2D coloc
selectWindow("C1-Merged");
run("Z Project...", "projection=[Max Intensity] all");
selectWindow("C2-Merged");
run("Z Project...", "projection=[Max Intensity] all");
imageCalculator("AND create stack", "MAX_C1-Merged","MAX_C2-Merged");
selectWindow("Result of MAX_C1-Merged");
rename("2D coloc");
selectWindow("MAX_C1-Merged");
Stack.setFrame(n_frames/2);
getStatistics(dummy, s1_area);
selectWindow("MAX_C2-Merged");
Stack.setFrame(n_frames/2);
getStatistics(dummy, s2_area);
coloc_array_2D = newArray(n_frames);
selectWindow("2D coloc");
for(a=1; a<=n_frames; a++){
	selectWindow("2D coloc");
	Stack.setFrame(a);
	getStatistics(dummy, coloc_area);
	coloc_array_2D[a-1] = coloc_area;
}

//Have C1 obscure C2 in the 3D Projection
selectWindow("MAX_C1-Merged");
run("Duplicate...", "title=ref_mask duplicate");
selectWindow("ref_mask");
run("Invert", "stack");
run("Divide...", "value=255.000 stack");
for(a=0; a<i_depth; a++){
	selectWindow("ref_mask");
	run("Duplicate...", "title=[mask] duplicate");
	if(isOpen("mask stack")){
		run("Concatenate...", "  title=[mask stack] image1=[mask stack] image2=mask image3=[-- None --]");
	}
	else{
		selectWindow("mask");
		rename("mask stack");
	}
}
close("ref_mask");
close("mask");
selectWindow("mask stack");
run("Stack to Hyperstack...", "order=xyctz channels=1 slices=" + i_depth + " frames=" + n_frames + " display=Color");
imageCalculator("Multiply create stack", "C2-Merged","mask stack");
close("mask stack");

//Generate stack projections
selectWindow("C1-Merged");
run("Z Project...", "projection=[Sum Slices] all");
selectWindow("SUM_C1-Merged");
Stack.getStatistics(dummy, dummy, min, max, dummy);
setMinAndMax(min, max);
run("8-bit");
run("Duplicate...", "title=[C1_XY] duplicate");
selectWindow("Result of C2-Merged");
run("Z Project...", "projection=[Sum Slices] all");
selectWindow("SUM_Result of C2-Merged");
Stack.getStatistics(dummy, dummy, min, max, dummy);
setMinAndMax(min, max);
run("8-bit");
run("Merge Channels...", "c1=C1_XY c2=[SUM_Result of C2-Merged] create");
selectWindow("Merged");
rename("SUM_3D XY merge");

selectWindow("C1-Merged");
run("TransformJ Turn", "z-angle=0 y-angle=0 x-angle=270");
selectWindow("C1-Merged turned");
run("Z Project...", "projection=[Sum Slices] all");
selectWindow("SUM_C1-Merged turned");
Stack.getStatistics(dummy, dummy, min, max, dummy);
setMinAndMax(min, max);
run("8-bit");
selectWindow("C2-Merged");
run("TransformJ Turn", "z-angle=0 y-angle=0 x-angle=270");
selectWindow("C2-Merged turned");
run("Z Project...", "projection=[Sum Slices] all");
selectWindow("SUM_C2-Merged turned");
Stack.getStatistics(dummy, dummy, min, max, dummy);
setMinAndMax(min, max);
run("8-bit");
run("Merge Channels...", "c1=[SUM_C1-Merged turned] c2=[SUM_C2-Merged turned] create");
selectWindow("Merged");
rename("SUM_3D merge turned");

//close("3D merge");
close("3D coloc");
close("2D coloc");
close("SUM_C1-Merged");
close("C1-Merged");
close("C2-Merged");
close("C1-Merged turned");
close("C2-Merged turned");
close("Result of C2-Merged");

run("Merge Channels...", "c1=MAX_C1-Merged c2=MAX_C2-Merged create");
selectWindow("Merged");
rename("2D merge");
newImage("blank", "16-bit composite-mode", i_width, i_height, 2, 1, n_frames);
run("Combine...", "stack1=[SUM_3D XY merge] stack2=[SUM_3D merge turned] combine");
selectWindow("Combined Stacks");
rename("1");
run("Combine...", "stack1=[2D merge] stack2=blank combine");
selectWindow("Combined Stacks");
rename("2");
selectWindow("1");
Stack.setChannel(1);
run("Green");
Stack.setChannel(2);
run("Magenta");
run("RGB Color", "frames");
selectWindow("2");
Stack.setChannel(1);
run("Green");
Stack.setChannel(2);
run("Magenta");
run("RGB Color", "frames");
run("Combine...", "stack1=1 stack2=2");
selectWindow("Combined Stacks");
setColor(255, 255, 255);
setForegroundColor(255, 255, 255);
makeLine(i_width, 0, i_width, 2*i_height);
run("Draw", "stack");
makeLine(0, i_height, 2*i_width, i_height);
run("Draw", "stack");
run("Select None");

//Add labels
close("3D XY merge");
if(show_coloc){
	selectWindow("Combined Stacks");
	makeText("3D XY Projection", 0, 0);
	run("Draw", "stack");
	makeText("3D XZ Projection", 0, i_height+1);
	run("Draw", "stack");
	makeText("2D Maximum Intensity Projection", i_width+1, 0);
	run("Draw", "stack");
	run("Select None");
	
	selectWindow("Combined Stacks");
	for(a=1; a<=n_frames; a++){
		selectWindow("Combined Stacks");
		Stack.setSlice(a);
		string = "Frame #" + a + "\n\n2D colocalization:\nGreen:Magenta = " + coloc_array_2D[a-1]/s1_area + "\nMagenta:Green = " + coloc_array_2D[a-1]/s2_area;
		string += "\n\n3D colocalization:\nGreen:Magenta = " + coloc_array_3D[a-1]/s1_volume + "\nMagenta:Green = " + coloc_array_3D[a-1]/s2_volume;
		makeText(string, i_width+1, i_height+1);
		run("Draw", "slice");
	}
	run("Select None");
}
setBatchMode("exit and display");




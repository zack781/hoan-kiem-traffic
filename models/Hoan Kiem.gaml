/**
* Name: HoanKiem
* Based on the internal empty template. 
* Author: zack
* Tags: 
*/


model HoanKiem

global {
    int y_lane1 <- 10;
    int y_lane2 <- 20;
    int y_lane3 <- 30;
    int y_lane4 <- 40;
    int y_lane5 <- 50;
}

grid lane height: lane_height width: lane_width {
	init {
		if {}
	}
}


/***
* Name: traffic
* Author: minhduc0711
* Description: Traffic simulation model including various vehicle types.
* Tags: Tag1, Tag2, TagN
***/

model traffic

global {
	string CAR <- "car";
	string MOTO <- "motorbike";
	string BICYCLE <- "bicycle";
	string CYCLO <- "cyclo";
	string BUS <- "bus";
	string OUT <- "outArea";	
	graph road_network;
	float lane_width <- 0.1;
	int restricted_lane <- 1; // Lane index that is restricted to bicycles and cyclos only
}

species intersection schedules: [] skills: [intersection_skill] {}

species road skills: [road_skill] {
	string type;
	bool oneway;
	bool s1_closed;
	bool s2_closed;
	int num_lanes <- 4;
	bool closed;
	float capacity;
	int nb_vehicles <- length(all_agents) update: length(all_agents);
	float speed_coeff <- 1.0 min: 0.1 update: 1.0 - (nb_vehicles / capacity);
	
	init {
		capacity <- 1 + (num_lanes * shape.perimeter / 3);
	}

	// Function to check if the vehicle can enter a specific lane
	bool can_enter_lane(int lane_index, vehicle v) {
		// If the lane is the restricted one, only allow bicycles and cyclos
		if (lane_index = restricted_lane) {
			return (v.type = BICYCLE or v.type = CYCLO);
		}
		// Otherwise, allow all vehicles
		return true;
	}
}

species vehicle skills: [driving] {
	string type;
	building target;
	point shift_pt <- location;
	bool at_home <- true;
	int lane_index <- 0;
	
	init {
		proba_respect_priorities <- 0.0;
		proba_respect_stops <- [1.0];
		proba_use_linked_road <- 0.0;
		lane_change_limit <- 2;
		linked_lane_limit <- 0;
		location <- one_of(building).location;
	}

	action select_target_path {
		target <- one_of(building);
		location <- (intersection closest_to self).location;
		do compute_path graph: road_network target: target.closest_intersection;
	}
	
	reflex choose_path when: final_target = nil {
		do select_target_path;
	}
	
	reflex move when: final_target != nil {
		// Determine the lane the vehicle is occupying
		lane_index <- get_lane_index();

		// Only move if the vehicle is allowed in the current lane
		if (road(current_road).can_enter_lane(lane_index, self)) {
			do drive;
			if (final_target = nil) {
				do unregister;
				at_home <- true;
				location <- target.location;
			} else {
				shift_pt <- compute_position();
			}
		}
	}

	// Determine which lane the vehicle is occupying
	int get_lane_index {
		if (current_road != nil) {
			return road(current_road).num_lanes - lowest_lane;
		} else {
			return 0;
		}
	}
	
	point compute_position {
		if (current_road != nil) {
			float dist <- (road(current_road).num_lanes - lowest_lane -
				mean(range(num_lanes_occupied - 1)) - 0.5) * lane_width;
			if (violating_oneway) {
				dist <- -dist;
			}
			return location + {cos(heading + 90) * dist / 10, sin(heading + 90) * dist / 10};
		} else {
			return {0, 0};
		}
	}
}

species car parent: vehicle {
	float vehicle_length <- 4.5; 
	int num_lanes_occupied <- 2;
	float max_speed <-rnd(50,70) #km / #h;
	string type <- "Car";
}

species motorbike parent: vehicle {
	float vehicle_length <- 2.8; 
	int num_lanes_occupied <- 1;
	float max_speed <-rnd(40,50) #km / #h;
	string type <- "Motorbike";
}

species cycling parent: vehicle {
	float vehicle_length <- 1.8; 
	int num_lanes_occupied <- 1;
	float max_speed <-rnd(15,25) #km / #h;
	string type <- "Cycling";
}

species bus parent: vehicle {
	float vehicle_length <- 10.0; 
	int num_lanes_occupied <- 3;
	float max_speed <-rnd(30,50) #km / #h;
	string type <- "Bus";
}

species vehicle skills:[driving] {
	string type;
	building target;
	point shift_pt <- location ;	
	bool at_home <- true;
	
	bool is_ev<-false;
	
	init {
		
		proba_respect_priorities <- 0.0;
		proba_respect_stops <- [1.0];
		proba_use_linked_road <- 0.0;

		lane_change_limit <- 2;
		linked_lane_limit <- 0; 
		location <- one_of(building).location;
	}

	action select_target_path {
		target <- one_of(building);
		location <- (intersection closest_to self).location;
		do compute_path graph: road_network target: target.closest_intersection; 
	}
	
	reflex choose_path when: final_target = nil  {
		do select_target_path;
	}
	
	reflex move when: final_target != nil {
		do drive;
		if (final_target = nil) {
			do unregister;
			at_home <- true;
			location <- target.location;
		} else {
			shift_pt <-compute_position();
		}
		
	}
	
	
	point compute_position {
		// Shifts the position of the vehicle perpendicularly to the road,
		// in order to visualize different lanes
		if (current_road != nil) {
			float dist <- (road(current_road).num_lanes - lowest_lane -
				mean(range(num_lanes_occupied - 1)) - 0.5) * lane_width;
			if violating_oneway {
				dist <- -dist;
			}
		 	
			return location + {cos(heading + 90) * dist/10, sin(heading + 90) * dist/10};
		} else {
			return {0, 0};
		}
	}	
	
}

species building schedules: [] {
	intersection closest_intersection <- intersection closest_to self;
	string type;
	geometry pollution_perception <- shape + 50;
	int pollution_index;
}

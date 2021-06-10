#! /bin/bash

# This script is for simulating the enrolling scenario of courses by the user
# mount point binding of courses is the main goal of the script


# Usage:																		
# 	--------------------------------------------------------------------		
#        			./course_mount.sh {-h|-l|-m|-u} [-c COURSE]					
# 	--------------------------------------------------------------------		
#       	./course_mount.sh -h to print this help message						
# 		./course_mount.sh -l to list all the courses							
#        	./course_mount.sh -m -c [course] For mounting a given course		
#        	./course_mount.sh -u -c [course] For unmounting a given course		
#        	If course name is ommited all courses will be (un)mounted 			


set -e

# Create an array which holds list of courses. 
# This should be used to compare if the course name is passed in CLI

BASE_DIR="/data/courses"
MOUNT_BASE_DIR="/home/trainee/courses"
COURSES=$(cat /home/trainee/courses.list)
OPTYPE=
COURSENAME=
ORIGINAL_DIR=
MOUNT_DIR=

# function for usage
usage() {
	cat <<usage-end
	Usage:
	--------------------------------------------------------------------
       			./course_mount.sh {-h|-l|-m|-u} [-c COURSE]
	--------------------------------------------------------------------
      	./course_mount.sh -h to print this help message
       	./course_mount.sh -l to list all the courses
       	./course_mount.sh -m -c [course] For mounting a given course
       	./course_mount.sh -u -c [course] For unmounting a given course
       	If course name is ommited all courses will be (un)mounted 
usage-end
	exit $1
}

# function to list all the courses and display if they are mounted
list_courses() {
	IND=1
	echo "SNo. | COURSE | MOUNTED" > /tmp/trainee_course_mount.list		# headers
	for COURSE in ${COURSES[*]}
	do
		MOUNT_DIR=$MOUNT_BASE_DIR/$COURSE
		ORIGINAL_DIR=$BASE_DIR/$COURSE
		IS_MOUNTED=no
		[[ $(check_mount) -eq 0 ]] && IS_MOUNTED=yes
		# echo ${IND}. $'\t' $COURSE $'\t\t' $IS_MOUNTED
		echo "${IND}. | $COURSE | $IS_MOUNTED" >> /tmp/trainee_course_mount.list
		(( IND=$IND+1 ))
	done
	cat /tmp/trainee_course_mount.list | column -t -s '|'
	exit 0
}

# function to check mount exists
# usage should be as a subshel function only
check_mount() {
    # Return 0 if mount exists 1 if not exists
	[[ $(mount | grep "${ORIGINAL_DIR} on ${MOUNT_DIR} ") ]] && echo 0 || echo 1
}

# function for mount a course
mount_course() {
    # Check if the given course exists in course array
	IS_COURSE=0
	for COURSE in ${COURSES[@]}
	do
		if [[ "$COURSE" == "$COURSENAME" ]] 
		then
			IS_COURSE=1
			break
		fi
	done
	# if not a course exit with 1
	[[ $IS_COURSE -eq 0 ]] && echo "course doen't exist" && exit 1
    # Check if the mount is already exists
	MOUNT_DIR=$MOUNT_BASE_DIR/$COURSENAME
	ORIGINAL_DIR=$BASE_DIR/$COURSENAME
	if [[ $(check_mount) -eq 0 ]]
	then
		echo ${ORIGINAL_DIR} already mounted on ${MOUNT_DIR}
	else
		# Create directory in target
		$(mkdir -p ${MOUNT_DIR})
		# Set permissions
		# Mount the source to target
		$(bindfs -p a-w -u trainee -g ftpaccess ${ORIGINAL_DIR} ${MOUNT_DIR})
		echo 'successfully mounted ' ${ORIGINAL_DIR} ' on ' ${MOUNT_DIR}
	fi
}

# function to mount all courses
mount_all() {
    # Loop through courses array
	for COURSE in ${COURSES[@]} 
	do	
		# call mount_course
		COURSENAME=$COURSE
		mount_course
	done
}

# function for unmount course
unmount_course() {
	# Check if the given course exists in course array
	IS_COURSE=0
	for COURSE in ${COURSES[@]}
	do
		# echo $COURSE $COURSENAME
		if [[ "$COURSE" == "$COURSENAME" ]] 
		then
			IS_COURSE=1
			break
		fi
	done
	# if not a course exit with 1
	[[ $IS_COURSE -eq 0 ]] && echo "course doen't exist" && exit 1
    # Check if mount exists
	MOUNT_DIR=$MOUNT_BASE_DIR/$COURSENAME
	ORIGINAL_DIR=$BASE_DIR/$COURSENAME
	if [[ $(check_mount) -ne 0 ]] 
	then
		echo mount doesnt even exist
	else 
		echo unmounting ${MOUNT_DIR}
		# If mount exists unmount and delete directory in target folder
		$(umount ${MOUNT_DIR})
	fi
}

# function for unmount all courses
unmount_all() {
    # Loop through courses array
	for COURSE in ${COURSES[@]} 
	do	
		# call unmount_course
		COURSENAME=$COURSE
		unmount_course
	done
}

# processing the options and assigning arguments to variables
while getopts "hlmuc:" opt
do
    case $opt in
		"h") [[ -n ${OPTYPE} ]] || usage 0;;
		"l") list_courses ;;
		"m") [[ -n ${OPTYPE} ]] && usage 1 || OPTYPE=m ;;
		"u") [[ -n ${OPTYPE} ]] && usage 1 || OPTYPE=u ;;
		"c") [[ -n ${OPTARG} ]] && COURSENAME=${OPTARG} ||  usage 1;;
        *) usage 1;;
    esac
done

[[ -z ${OPTYPE} ]] && usage 1

# echo enroll -$OPTYPE -c $COURSENAME

if [[ -z $COURSENAME ]]
then
	if [[ $OPTYPE == "m" ]]
	then
		mount_all
	else
		unmount_all
	fi
else
	if [[ $OPTYPE == "m" ]]
	then
		mount_course
	else
        unmount_course
	fi
fi


exit 0

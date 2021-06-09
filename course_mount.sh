#! /bin/bash

# This script is for simulating the enrolling scenario of courses by the user
# mount point binding of courses is the main goal of the script


# Usage:																		#
# 	--------------------------------------------------------------------		#
#        			./course_mount.sh {-h|-l|-m|-u} [-c COURSE]					#
# 	--------------------------------------------------------------------		#
#       	./course_mount.sh -h to print this help message						#
# 		./course_mount.sh -l to list all the courses							#
#        	./course_mount.sh -m -c [course] For mounting a given course		#
#        	./course_mount.sh -u -c [course] For unmounting a given course		#
#        	If course name is ommited all courses will be (un)mounted 			#


set -e

# Create an array which holds list of courses. 
# This should be used to compare if the course name is passed in CLI

BASE_DIR="/data/courses"
MOUNT_BASE_DIR="/home/trainee/courses"
COURSES=$(cat /home/trainee/courses.txt)
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

# function to list all the courses
list_courses() {
	IND=1
	echo SNo. $'\t' COURSE			# headers
	for COURSE in ${COURSES[*]}
	do
		echo ${IND}. $'\t' $COURSE
		(( IND=$IND+1 ))
	done
	exit 0
}

# function to check mount exists
# usage should be as a subshel function only
check_mount() {
    # Return 0 if mount exists 1 if not exists
	if [[ $(mount | grep "${ORIGINAL_DIR} on ${MOUNT_DIR} ") ]]
	then
		echo 0
	else
		echo 1
	fi
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
	# echo $IS_COURSE
	if [[ $IS_COURSE -eq 0 ]]
	then
		echo "course doen't exist"
		exit 1
	fi
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
	# echo $IS_COURSE
	if [[ $IS_COURSE -eq 0 ]]
	then
		echo "course doesn't exist"
		exit 1
	fi
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
		"c") [[ -n ${OPTARG} ]] && COURSENAME=${OPTARG} ||  usage ;;
               	*) usage ;;
       	esac
done

[[ -z ${OPTYPE} ]] && usage

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

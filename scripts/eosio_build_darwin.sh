if [ $1 == 1 ]; then ANSWER=1; else ANSWER=0; fi

OS_VER=$(sw_vers -productVersion)
OS_MAJ=$(echo "${OS_VER}" | cut -d'.' -f1)
OS_MIN=$(echo "${OS_VER}" | cut -d'.' -f2)
OS_PATCH=$(echo "${OS_VER}" | cut -d'.' -f3)
MEM_GIG=$(bc <<< "($(sysctl -in hw.memsize) / 1024000000)")
CPU_SPEED=$(bc <<< "scale=2; ($(sysctl -in hw.cpufrequency) / 10^8) / 10")
CPU_CORE=$( sysctl -in machdep.cpu.core_count )
export JOBS=$(( MEM_GIG > CPU_CORE ? CPU_CORE : MEM_GIG ))

DISK_INSTALL=$(df -h . | tail -1 | tr -s ' ' | cut -d\  -f1 || cut -d' ' -f1)
blksize=$(df . | head -1 | awk '{print $2}' | cut -d- -f1)
gbfactor=$(( 1073741824 / blksize ))
total_blks=$(df . | tail -1 | awk '{print $2}')
avail_blks=$(df . | tail -1 | awk '{print $4}')
DISK_TOTAL=$((total_blks / gbfactor ))
DISK_AVAIL=$((avail_blks / gbfactor ))

export HOMEBREW_NO_AUTO_UPDATE=1

COUNT=1
DISPLAY=""
DEPS=""

printf "\\nOS name: ${OS_NAME}\\n"
printf "OS Version: ${OS_VER}\\n"
printf "CPU speed: ${CPU_SPEED}Mhz\\n"
printf "CPU cores: %s\\n" "${CPU_CORE}"
printf "Physical Memory: ${MEM_GIG} Gbytes\\n"
printf "Disk install: ${DISK_INSTALL}\\n"
printf "Disk space total: ${DISK_TOTAL}G\\n"
printf "Disk space available: ${DISK_AVAIL}G\\n"

if [ "${MEM_GIG}" -lt 7 ]; then
	echo "Your system must have 7 or more Gigabytes of physical memory installed."
	echo "Exiting now."
	exit 1
fi

if [ "${OS_MIN}" -lt 12 ]; then
	echo "You must be running Mac OS 10.12.x or higher to install EOSIO."
	echo "Exiting now."
	exit 1
fi

if [ "${DISK_AVAIL}" -lt "$DISK_MIN" ]; then
	echo "You must have at least ${DISK_MIN}GB of available storage to install EOSIO."
	echo "Exiting now."
	exit 1
fi

printf "\\n"

printf "Checking xcode-select installation...\\n"
if ! XCODESELECT=$( command -v xcode-select)
then
	printf " - XCode must be installed in order to proceed!\\n\\n"
	exit 1
fi
printf " - XCode installation found @ ${XCODESELECT}\\n"

printf "Checking Ruby installation...\\n"
if ! RUBY=$( command -v ruby)
then
	printf " - Ruby must be installed in order to proceed!\\n"
	exit 1
fi
printf " - Ruby installation found @ ${RUBY}\\n"

printf "Checking Home Brew installation...\\n"
if ! BREW=$( command -v brew )
then
	printf "Homebrew must be installed to compile EOS.IO!\\n"
	if [ $ANSWER != 1 ]; then read -p "Do you wish to install HomeBrew? (y/n)? " ANSWER; fi
	case $ANSWER in
		1 | [Yy]* )
			"${XCODESELECT}" --install 2>/dev/null;
			if ! "${RUBY}" -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; then
				echo " - Unable to install homebrew at this time."
				exit 1;
			else
				BREW=$( command -v brew )
			fi
		;;
		[Nn]* ) echo "User aborted homebrew installation. Exiting now."; exit 1;;
		* ) echo "Please type 'y' for yes or 'n' for no."; exit;;
	esac

fi
printf " - Home Brew installation found @ ${BREW}\\n"

printf "\\nChecking dependencies...\\n"
var_ifs="${IFS}"
IFS=","
while read -r name tester testee brewname uri; do
	if [ "${tester}" "${testee}" ]; then
		printf " - %s found\\n" "${name}"
		continue
	fi
	# resolve conflict with homebrew glibtool and apple/gnu installs of libtool
	if [ "${testee}" == "/usr/local/bin/glibtool" ]; then
		if [ "${tester}" "/usr/local/bin/libtool" ]; then
			printf " - %s found\\n" "${name}"
			continue
		fi
	fi
	DEPS=$DEPS"${brewname},"
	DISPLAY="${DISPLAY}${COUNT}. ${name}\\n"
	printf " - %s ${bldred}NOT${txtrst} found.\\n" "${name}"
	(( COUNT++ ))
done < "${REPO_ROOT}/scripts/eosio_build_darwin_deps"
IFS="${var_ifs}"

if [ ! -d /usr/local/Frameworks ]; then
	printf "\\n${bldred}/usr/local/Frameworks is necessary to brew install python@3. Run the following commands as sudo and try again:${txtrst}\\n"
	printf "sudo mkdir /usr/local/Frameworks && sudo chown $(whoami):admin /usr/local/Frameworks\\n\\n"
	exit 1;
fi

if [ $COUNT -gt 1 ]; then
	printf "\\nThe following dependencies are required to install EOSIO:\\n"
	printf "${DISPLAY}\\n\\n"
	if [ $ANSWER != 1 ]; then read -p "Do you wish to install these packages? (y/n) " ANSWER; fi
	case $ANSWER in
		1 | [Yy]* )
			"${XCODESELECT}" --install 2>/dev/null;
			if [ $1 == 0 ]; then read -p "Do you wish to update homebrew packages first? (y/n) " ANSWER; fi
			case $ANSWER in
				1 | [Yy]* )
					if ! brew update; then
						printf " - Brew update failed.\\n"
						exit 1;
					else
						printf " - Brew update complete.\\n"
					fi
				;;
				[Nn]* ) echo "Proceeding without update!";;
				* ) echo "Please type 'y' for yes or 'n' for no."; exit;;
			esac
			brew tap eosio/eosio # Required to install mongo-cxx-driver with static library
			printf "\\nInstalling Dependencies...\\n"
			# Ignore cmake so we don't install a newer version.
			# Build from source to use local cmake; see homebrew-eosio repo for examples
			# DON'T INSTALL llvm@4 WITH --force!
			OIFS="$IFS"
			IFS=$','
			for DEP in $DEPS; do
				# Eval to support string/arguments with $DEP
				if ! eval $BREW install $DEP; then
					printf " - Homebrew exited with the above errors!\\n"
					exit 1;
				fi
			done
			IFS="$OIFS"
		;;
		[Nn]* ) echo "User aborting installation of required dependencies, Exiting now."; exit;;
		* ) echo "Please type 'y' for yes or 'n' for no."; exit;;
	esac
else
	printf "\\n - No required Home Brew dependencies to install.\\n"
fi


printf "\\n"


export CPATH="$(python-config --includes | awk '{print $1}' | cut -dI -f2):$CPATH" # Boost has trouble finding pyconfig.h
printf "Checking Boost library (${BOOST_VERSION}) installation...\\n"
BOOSTVERSION=$( grep "#define BOOST_VERSION" "$HOME/opt/boost/include/boost/version.hpp" 2>/dev/null | tail -1 | tr -s ' ' | cut -d\  -f3 )
if [ "${BOOSTVERSION}" != "${BOOST_VERSION_MAJOR}0${BOOST_VERSION_MINOR}0${BOOST_VERSION_PATCH}" ]; then
	printf "Installing Boost library...\\n"
	curl -LO https://dl.bintray.com/boostorg/release/$BOOST_VERSION_MAJOR.$BOOST_VERSION_MINOR.$BOOST_VERSION_PATCH/source/boost_$BOOST_VERSION.tar.bz2 \
	&& tar -xjf boost_$BOOST_VERSION.tar.bz2 \
	&& cd $BOOST_ROOT \
	&& ./bootstrap.sh --prefix=$BOOST_ROOT \
	&& ./b2 -q -j$(sysctl -in machdep.cpu.core_count) --with-iostreams --with-date_time --with-filesystem \
	                                                  --with-system --with-program_options --with-chrono --with-test install \
	&& cd .. \
	&& rm -f boost_$BOOST_VERSION.tar.bz2 \
	&& rm -rf $BOOST_LINK_LOCATION \
	&& ln -s $BOOST_ROOT $BOOST_LINK_LOCATION \
	|| exit 1
	printf " - Boost library successfully installed @ ${BOOST_ROOT}.\\n"
else
	printf " - Boost library found with correct version @ ${BOOST_ROOT}.\\n"
fi
if [ $? -ne 0 ]; then exit -1; fi


printf "\\n"


printf "Checking MongoDB installation...\\n"
if [ ! -d $MONGODB_ROOT ]; then
	printf "Installing MongoDB into ${MONGODB_ROOT}...\\n"
	curl -OL https://fastdl.mongodb.org/osx/mongodb-osx-ssl-x86_64-$MONGODB_VERSION.tgz \
	&& tar -xzf mongodb-osx-ssl-x86_64-$MONGODB_VERSION.tgz \
	&& mv $SRC_LOCATION/mongodb-osx-x86_64-$MONGODB_VERSION $MONGODB_ROOT \
	&& touch $MONGODB_LOG_LOCATION/mongod.log \
	&& rm -f mongodb-osx-ssl-x86_64-$MONGODB_VERSION.tgz \
	&& cp -f $REPO_ROOT/scripts/mongod.conf $MONGODB_CONF \
	&& mkdir -p $MONGODB_DATA_LOCATION \
	&& rm -rf $MONGODB_LINK_LOCATION \
	&& rm -rf $BIN_LOCATION/mongod \
	&& ln -s $MONGODB_ROOT $MONGODB_LINK_LOCATION \
	&& ln -s $MONGODB_LINK_LOCATION/bin/mongod $BIN_LOCATION/mongod \
	|| exit 1
	printf " - MongoDB successfully installed @ ${MONGODB_ROOT}\\n"
else
	printf " - MongoDB found with correct version @ ${MONGODB_ROOT}.\\n"
fi
if [ $? -ne 0 ]; then exit -1; fi
printf "Checking MongoDB C driver installation...\\n"
if [ ! -d $MONGO_C_DRIVER_ROOT ]; then
	printf "Installing MongoDB C driver...\\n"
	curl -LO https://github.com/mongodb/mongo-c-driver/releases/download/$MONGO_C_DRIVER_VERSION/mongo-c-driver-$MONGO_C_DRIVER_VERSION.tar.gz \
	&& tar -xzf mongo-c-driver-$MONGO_C_DRIVER_VERSION.tar.gz \
	&& cd mongo-c-driver-$MONGO_C_DRIVER_VERSION \
	&& mkdir -p cmake-build \
	&& cd cmake-build \
	&& $CMAKE -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME -DENABLE_BSON=ON -DENABLE_SSL=DARWIN -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -DENABLE_STATIC=ON .. \
	&& make -j"${JOBS}" \
	&& make install \
	&& cd ../.. \
	&& rm mongo-c-driver-$MONGO_C_DRIVER_VERSION.tar.gz \
	|| exit 1
	printf " - MongoDB C driver successfully installed @ ${MONGO_C_DRIVER_ROOT}.\\n"
else
	printf " - MongoDB C driver found with correct version @ ${MONGO_C_DRIVER_ROOT}.\\n"
fi
if [ $? -ne 0 ]; then exit -1; fi
printf "Checking MongoDB C++ driver installation...\\n"
if [ "$(grep "Version:" $HOME/lib/pkgconfig/libmongocxx-static.pc 2>/dev/null | tr -s ' ' | awk '{print $2}')" != $MONGO_CXX_DRIVER_VERSION ]; then
	printf "Installing MongoDB C++ driver...\\n"
	curl -L https://github.com/mongodb/mongo-cxx-driver/archive/r$MONGO_CXX_DRIVER_VERSION.tar.gz -o mongo-cxx-driver-r$MONGO_CXX_DRIVER_VERSION.tar.gz \
	&& tar -xzf mongo-cxx-driver-r${MONGO_CXX_DRIVER_VERSION}.tar.gz \
	&& cd mongo-cxx-driver-r$MONGO_CXX_DRIVER_VERSION/build \
	&& $CMAKE -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME .. \
	&& make -j"${JOBS}" VERBOSE=1 \
	&& make install \
	&& cd ../.. \
	&& rm -f mongo-cxx-driver-r$MONGO_CXX_DRIVER_VERSION.tar.gz \
	|| exit 1
	printf " - MongoDB C++ driver successfully installed @ ${MONGO_CXX_DRIVER_ROOT}.\\n"
else
	printf " - MongoDB C++ driver found with correct version @ ${MONGO_CXX_DRIVER_ROOT}.\\n"
fi
if [ $? -ne 0 ]; then exit -1; fi

printf "\\n"


# We install llvm into /usr/local/opt using brew install llvm@4
printf "Checking LLVM 4 support...\\n"
if [ ! -d $LLVM_ROOT ]; then
	ln -s /usr/local/opt/llvm@4 $LLVM_ROOT \
	|| exit 1
	printf " - LLVM successfully linked from /usr/local/opt/llvm@4 to ${LLVM_ROOT}\\n"
else
	printf " - LLVM found @ ${LLVM_ROOT}.\\n"
fi

printf "\\n\\tChecking for librdkafka with  support.\\n"
RDKAFKA_DIR=/usr/local/include/librdkafka
if [ ! -d "${RDKAFKA_DIR}" ]; then
    # Build librdkafka support:
    printf "\\tInstalling librdkafka\\n"
    if ! cd "${TEMP_DIR}"
    then
        printf "\\n\\tUnable to cd into directory %s.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if [ -d "${TEMP_DIR}/librdkafka" ]; then
        if ! rm -rf "${TEMP_DIR}/librdkafka"
        then
        printf "\\tUnable to remove directory %s. Please remove this directory and run this script %s again. 0\\n" "${TEMP_DIR}/librdkafka/" "${BASH_SOURCE[0]}"
        printf "\\tExiting now.\\n\\n"
        exit 1;
        fi
    fi
    if ! git clone --depth 1 -b v0.11.6 https://github.com/edenhill/librdkafka.git
    then
        printf "\\tUnable to clone librdkafka repo.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cd "${TEMP_DIR}/librdkafka/"
    then
        printf "\\tUnable to enter directory %s/librdkafka/.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cmake -H. -B_cmake_build
    then
        printf "\\tError cmake_build librdkafka.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cmake -DRDKAFKA_BUILD_STATIC=1 --build _cmake_build
    then
        printf "\\tError compiling cmake -DRDKAFKA_BUILD_STATIC=1 --build _cmake_build , librdkafka.1\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cd "${TEMP_DIR}/librdkafka/_cmake_build"
    then
        printf "\\tUnable to enter directory %s/librdkafka/_cmake_build.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! sudo make install
    then
        printf "\\tUnable to make install librdkafka.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    printf "\\n\\tlibrdkafka successffully installed @ %s.\\n\\n" "${RDKAFKA_DIR}"
else
    printf "\\t librdkafka found at %s.\\n" "${RDKAFKA_DIR}"
fi

printf "\\n\\tChecking for cppkafka with  support.\\n"
CPPKAFKA_DIR=/usr/local/include/cppkafka
if [ ! -d "${CPPKAFKA_DIR}" ]; then
    # Build cppkafka support:
    printf "\\tInstalling cppkafka\\n"
    if ! cd "${TEMP_DIR}"
    then
        printf "\\n\\tUnable to cd into directory %s.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if [ -d "${TEMP_DIR}/cppkafka" ]; then
        if ! rm -rf "${TEMP_DIR}/cppkafka"
        then
        printf "\\tUnable to remove directory %s. Please remove this directory and run this script %s again. 0\\n" "${TEMP_DIR}/cppkafka/" "${BASH_SOURCE[0]}"
        printf "\\tExiting now.\\n\\n"
        exit 1;
        fi
    fi
    if ! git clone --depth 1 -b 0.2 https://github.com/mfontanini/cppkafka.git
    then
        printf "\\tUnable to clone cppkafka repo.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cd "${TEMP_DIR}/cppkafka/"
    then
        printf "\\tUnable to enter directory %s/cppkafka/.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! mkdir build
    then
        printf "\\tUnable to remove directory build.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cd "${TEMP_DIR}/cppkafka/build"
    then
        printf "\\tUnable to enter directory  %s/cppkafka/build.\\n" "${TEMP_DIR}"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! cmake -DCPPKAFKA_RDKAFKA_STATIC_LIB=1 -DCPPKAFKA_BUILD_SHARED=0 ..
    then
        printf "\\tError compiling cmake -DCPPKAFKA_RDKAFKA_STATIC_LIB=1 -DCPPKAFKA_BUILD_SHARED=0 ..  , cppkafka.1\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    if ! sudo make install
    then
        printf "\\tUnable to make install cppkafka.\\n"
        printf "\\n\\tExiting now.\\n"
        exit 1;
    fi
    printf "\\n\\tcppkafka successffully installed @ %s.\\n\\n" "${CPPKAFKA_DIR}"
else
    printf "\\t cppkafka found at %s.\\n" "${CPPKAFKA_DIR}"
fi

cd ..
printf "\\n"

function print_instructions() {
	return 0
}

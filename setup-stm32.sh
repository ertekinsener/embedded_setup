#!/bin/bash
set -ex # -e exits on error, -x prints the command being run
echo "Starting setup script as user: $(whoami)"
# ... rest of your script

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

sudo dnf install -y code

INSTALLER_DIR="$PWD"
BASE_DIR="$HOME/Workspace/Embedded"
ST_TOOLS_DIR="$BASE_DIR/Tools/ST"
OTHER_TOOLS_DIR="$BASE_DIR/Tools/Other"
ST_CUBE_REPOS_DIR="$ST_TOOLS_DIR/CubeRepos"
ST_CUBEMX_DIR="$ST_TOOLS_DIR/CubeMX"

ST_SVD_DIR="$ST_TOOLS_DIR/SVD"
ST_CMAKE_DIR="$ST_TOOLS_DIR/CMake"

ADDITIONAL_PACKAGES=(
	git
	unzip
	wget
	gcc
	gcc-c++
	make
    ninja-build
	cmake
    python3
    python3-pip
    libusb1-devel
    libftdi-devel
    arm-none-eabi-gcc-cs
    arm-none-eabi-gcc-cs-c++
    arm-none-eabi-binutils-cs
    arm-none-eabi-newlib
    gdb
    openocd
    stlink
)
sudo dnf install -y "${ADDITIONAL_PACKAGES[@]}"

# Substitute the variable into auto-install.xml
sed -i "s|<installpath>.*</installpath>|<installpath>$ST_CUBEMX_DIR</installpath>|g" ./auto-install.xml

code --install-extension marus25.cortex-debug --force
code --install-extension ms-vscode.cpptools-extension-pack --force
code --install-extension pedrosantos.stm32cubemx-file-opener --force

if [ -f $INSTALLER_DIR/cubemx.zip ]; then
	echo "Installing CubeMX..."

	# Create temp directory and unzip
	mkdir -p $INSTALLER_DIR/cubemx_tmp
	unzip -q -o $INSTALLER_DIR/cubemx.zip -d $INSTALLER_DIR/cubemx_tmp

	# Find the Linux installer binary (names vary slightly by version)
	INSTALLER=$(find $INSTALLER_DIR/cubemx_tmp -name "SetupSTM32CubeMX-*" | head -n 1)

	if [ -n "$INSTALLER" ]; then
		echo "Found installer: $INSTALLER"
		chmod +x "$INSTALLER"

		# Run the installer in headless mode using your XML configuration
		# Ensure auto-install.xml is in the current directory or provide full path

		"$INSTALLER" "$INSTALLER_DIR/auto-install.xml"

		echo "CubeMX installation complete."
	else
		echo "Error: Linux installer binary not found in zip."
	fi
	# Cleanup
	rm -rf ./cubemx_tmp
else
    echo "Cannot find file."
fi

mkdir -p "$ST_CUBE_REPOS_DIR"
cd "$ST_CUBE_REPOS_DIR"
# Clone STM32Cube repositories
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF0.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF1.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF2.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF3.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF4.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeF7.git
git clone --recursive https://github.com/STMicroelectronics/STM32CubeH7.git

cd

mkdir -p "$ST_SVD_DIR"
cd "$ST_SVD_DIR"
git clone https://github.com/stm32duino/stm32_svd.git

cd

mkdir -p "$ST_CMAKE_DIR"
cd "$ST_CMAKE_DIR"
git clone https://github.com/ObKo/stm32-cmake.git

cd "$BASE_DIR"
echo "Setup script completed."

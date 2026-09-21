class ProxmarkFirmwareUltimate < Formula
  desc "RRG/Iceman firmware for Proxmark3 Ultimate"
  homepage "https://github.com/RfidResearchGroup/proxmark3"
  url "https://github.com/RfidResearchGroup/proxmark3/archive/refs/tags/v4.23346.tar.gz"
  sha256 "5d727313d912d8d758365d3528fbf8af7463e5deec23a9bef79f1fab4fd0c66d"
  license "GPL-3.0-or-later"
  head "https://github.com/RfidResearchGroup/proxmark3.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "rfidresearchgroup/proxmark3/arm-none-eabi-gcc" => :build
  depends_on :macos

  def install
    args = %W[
      BREW_PREFIX=#{HOMEBREW_PREFIX}
      CROSS=#{formula_opt_bin("rfidresearchgroup/proxmark3/arm-none-eabi-gcc")}/arm-none-eabi-
      DONT_BUILD_NATIVE=y
      PLATFORM=PM3ULTIMATE
      PREFIX=#{prefix}
      INSTALLFWRELPATH=share/proxmark3/firmware/ultimate
    ]

    system "make", "recovery/all", *args
    system "make", "recovery/install", *args
  end

  def caveats
    firmware = opt_share/"proxmark3/firmware/ultimate"
    <<~EOS
      Firmware for Proxmark3 Ultimate is installed in:
        #{firmware}

      Use pm3-flash from a matching-version Proxmark3 client:
        pm3-flash -b #{firmware}/bootrom.elf
        pm3-flash #{firmware}/fullimage.elf

      recovery.bin is the combined image for JTAG recovery.
    EOS
  end

  test do
    firmware = share/"proxmark3/firmware/ultimate"
    %w[bootrom.elf fullimage.elf].each do |name|
      image = firmware/name
      assert_path_exists image
      header = image.binread(20)
      assert_equal "\x7fELF".b, header.byteslice(0, 4)
      assert_equal 1, header.getbyte(4)
      assert_equal 1, header.getbyte(5)
      assert_equal 40, header.byteslice(18, 2).unpack1("v")
    end

    recovery = firmware/"recovery.bin"
    assert_path_exists recovery
    assert_operator recovery.size, :>, 0
    assert_operator recovery.size, :<=, 512 * 1024
  end
end

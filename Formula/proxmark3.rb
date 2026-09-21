class Proxmark3 < Formula
  desc "RRG/Iceman Proxmark3 client, CDC flasher and firmware bundle"
  homepage "http://www.proxmark.org/"
  url "https://github.com/RfidResearchGroup/proxmark3/archive/refs/tags/v4.23346.tar.gz"
  sha256 "5d727313d912d8d758365d3528fbf8af7463e5deec23a9bef79f1fab4fd0c66d"
  head do
    if ENV.key?("HOMEBREW_TRAVIS_COMMIT")
      url "https://github.com/RfidResearchGroup/proxmark3.git", branch: ENV["HOMEBREW_TRAVIS_BRANCH"].to_s, revision: ENV["HOMEBREW_TRAVIS_COMMIT"].to_s
    else
      url "https://github.com/RfidResearchGroup/proxmark3.git"
    end
  end

  option "with-blueshark", "Enable Blueshark (BT Addon) support"
  option "with-smartcard", "Enable Smartcard support"
  option "with-flash", "Enable Flash support"
  option "with-generic", "Build for generic devices instead of RDV4"
  option "with-small", "Build for 256kB devices"
  option "without-standalone", "Build without standalone mode"

  depends_on "lua" => :build

  depends_on "openssl@3" => :build

  depends_on "pkg-config" => :build

  depends_on "python@3.14" => :build
  depends_on "rfidresearchgroup/proxmark3/arm-none-eabi-gcc" => :build
  depends_on "coreutils"
  depends_on "readline"
  depends_on "gd" => :recommended
  depends_on "openssl" => :recommended
  depends_on "qt@5" => :recommended

  FUNCTIONS = %w[em4x50 felica hfplot hfsniff hitag iclass iso14443a iso14443b iso15693 legicrf lf nfcbarcode
                 zx8211].freeze
  STANDALONE = {
    "lf" => %w[em4100emul em4100rswb em4100rsww em4100rwc hidbrute hidfcbrute icehid multihid nedap_sim nexid
               prox2brute proxbrute prox2brute samyrun tharexde],
    "hf" => %w[14asniff 14bsniff 15sim 15sniff aveful bog cardhopper colin craftbyte doegox_auth0 doegox_commit
               emvpng iceclass legic legic_rdv4 legicsim mattyrun mfcsim msdsal reblay st25_tearoff tcprst
               tmudford unisniff young],
  }.freeze

  FUNCTIONS.each do |func|
    option "without-#{func}", "Build without #{func.upcase} functionality"
  end

  STANDALONE.each do |freq, modes|
    modes.each do |mode|
      option "with-#{freq}-#{mode}", "Build with standalone mode #{freq.upcase}_#{mode.upcase}"
    end
  end

  def install
    ENV.deparallelize

    args = %W[
      BREW_PREFIX=#{HOMEBREW_PREFIX}
      PLATFORM=#{build.with?("generic") ? "PM3GENERIC" : "PM3RDV4"}
    ]

    # Build PLATFORM_EXTRAS based on selected options
    platform_extras = []
    platform_extras << "BTADDON" if build.with? "blueshark"
    platform_extras << "SMARTCARD" if build.with? "smartcard"
    platform_extras << "FLASH" if build.with? "flash"

    args << "PLATFORM_EXTRAS=#{platform_extras.join(" ")}" unless platform_extras.empty?

    if build.with? "small"
      args << '
        PLATFORM_SIZE=256
        STANDALONE=
        SKIP_HITAG=1
        SKIP_LEGICRF=1
        SKIP_EM4x50=1
        SKIP_EM4x70=1
        SKIP_ICLASS=1
        SKIP_FELICA=1
        SKIP_HFPLOT=1
        SKIP_HFSNIFF=1
        SKIP_NFCBARCODE=1
        SKIP_ZX8211=1
        SKIP_LEGICRF=1
        '
    end
    args << "SKIPQT=1" if build.without? "qt5"

    FUNCTIONS.each do |func|
      args << "SKIP_#{func.upcase}=1" if build.without? func
    end

    standalone = build.with?("standalone") ? nil : ""

    STANDALONE.each do |freq, modes|
      modes.each do |mode|
        if build.with? "#{freq}-#{mode}"
          odie "Only one standalone mode may be selected" unless standalone.nil?
          standalone = "#{freq.upcase}_#{mode.upcase}"
        end
      end
    end

    args << "STANDALONE=#{standalone}" unless standalone.nil?

    args << "-j"

    system "make", "clean", *args
    system "make", "all", *args
    system "make", "install", "PREFIX=#{prefix}", *args

    ohai "Install success!"
    ohai "The latest bootloader and firmware binaries are in share/firmware within the Homebrew Cellar."
  end

  test do
    system "proxmark3", "-h"
  end
end

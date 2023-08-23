
import sys
import json
import re
import shutil
import numpy
import struct
import binascii

temp_file_name = "temp.tmp"

subroutine_handles   = {}
directives           = {}

memory_contents_buffer = [[0x10] , []]

source_filename      = ""
output_filename      = ""
description_filename = ""
output_path          = ""
memory_init_filename = ""

processor_description = {}

def find_in_source( source_file , search ):
    source = open( source_file , "r" )
    line = ""
    index = 1

    for line in source:
        if line.find( search ) != -1:
            source.close()
            return str(index)
        else:
            index = index + 1
    source.close()
    return str(-1)

#Handle input arguments to the script
def parse_args():
    #Default argument values
    arguments   = [   ""  ,   ""  ,   ""  ,   ""  ,   ""  , "memory.hex"]
    to_import   = [ False , False , False , False , False , False ]

    for i in range( 1 , len(sys.argv) ):
        match sys.argv[i]:
            case "--help" | "-h":
                return None
            case "--source" | "-s":      
                to_import[0] = True
            case "--output" | "-o":
                to_import[1] = True
            case "--desc" | "-d":
                to_import[2] = True
            case "--hdl" | "-v":
                to_import[3] = True
            case "--wpath" | "-w":
                to_import[4] = True 
            case "--memory" | "-m":
                to_import[5] = True 
            case _:
                arguments[ len(arguments) - 1 - to_import[::-1].index(True) ] = sys.argv[i]
                to_import[ len(arguments) - 1 - to_import[::-1].index(True) ] = False         
    if arguments[0] == "":
        print("No source file provided: provide path to source:")
        arguments[0] = input()
    if arguments[1] == "":
        print("No output provided, enter output file name")
        arguments[1] = input()
    if arguments[2] == "":
        print("No instruction description provided provide path to description:")
        arguments[2] = input()
    return arguments

def process_registers( field : dict ):

    if field == None:
        return None

    ids = ""
    processed_field = {}
    range_identifier = "->"

    for pairs in field:
        if range_identifier in pairs:
            ids = " ".join( pairs.split() ) #Remove duplicate spaces
            ids = ids.replace(" " , "")
            ids = ids.split(range_identifier)
            ids[0] = [ re.sub( r'[0-9]' , '', ids[0]) , "".join( filter( lambda x: x.isnumeric() , ids[0] ) ) ]
            ids[1] = [ re.sub( r'[0-9]' , '', ids[1]) , "".join( filter( lambda x: x.isnumeric() , ids[1] ) ) ]

            #Check that the identifiers match
            if ids[0][0] != ids[1][0]:
                sys.exit( "ERROR: Mismatching identifiers: " + ids[0][0] + " vs " + ids[1][0] + ", line " + find_in_source( description_filename , pairs ) )
            else:
                if len( field[pairs] ) > 2:#If there are more than two numbers that denotes a fixed listing

                    if (1 + int(ids[1][1]) - int(ids[0][1])) != len( field[pairs] ):
                            
                        sys.exit( "ERROR: Mismatching range: " + ids[0][1] + "->" + ids[1][1] + " (" + str(1+int(ids[1][1])-int(ids[0][1])) + ")" +
                                " vs "
                                + str(field[pairs]) + " (" + str(len( field[pairs]) ) + ")" +
                                ", line " + find_in_source( description_filename , pairs )
                                )
                    else:
                        #If we reach this point then we can be pretty certain the register definitions are good
                        for idx in range( 0 , len(field[pairs]) ):
                            processed_field[ ids[0][0] + str(idx) ] = field[pairs][idx]

                else:#If there are two numbers then that denotes a range, 
                    #Check that the ranges of the numbers match
                    if (int(ids[1][1]) - int(ids[0][1])) != (field[pairs][1] - field[pairs][0]) :
                        sys.exit( "ERROR: Mismatching range: " + ids[0][1] + "->" + ids[1][1] + " (" + str(int(ids[1][1])-int(ids[0][1])) + ")" +
                                " vs "
                                + str(field[pairs][0]) + "->" + str(field[pairs][1] ) + " (" + str(int(field[pairs][1])-field[pairs][0]) + ")" +
                                ", line " + find_in_source( description_filename , pairs )
                                )
                    else:
                        #If we reach this point then we can be pretty certain the register definitions are good
                        start = field[pairs][0]
                        
                        for idx in range( int(ids[0][1]) , 1 + int(ids[1][1]) ):
                            #Support the $1 -> $27 stuff etc
                            if len( ids[0][0] ) == 1:
                                processed_field[ ids[0][0] + str(idx) ] = start + idx - 1
                            else :
                                processed_field[ ids[0][0] + str(idx) ] = start + idx

        else:
            processed_field[ pairs ] = field[pairs]

    return processed_field

def determine_value( string : str , size : int ):

    #0b, 0x, 0c7, 0d are the delimiters
    base_determiner = string[0] + string[1]
    literal = string.replace( base_determiner , '' )
    base = 10
    value = 0
    match base_determiner:
        case "0b" | "0B":
            base = 2
        case "0x" | "0X":
            base = 16
        case "0c" | "0C":
            base = 8
        case "0d" | "0D":
            base = 10
        case _:
            sys.exit( "ERROR: Invalid base specifier '" + base_determiner + "', line " , find_in_source( description_filename , base_determiner ) )

    try:
        value = int( literal , base )
    except ValueError:
        sys.exit( "ERROR: Invalid base specifier for integer literal: '" + string + "', line "  + find_in_source( description_filename , base_determiner )  )
    
    return value

def process_instruction_key( key : dict , tag : dict, properties : dict ):

    value = 0
    if key is None:
        value = None
    if isinstance( key , int ):
        value = min( key , 2**properties.get("opcode") - 1 )
    if isinstance( key , str ):
        value  = determine_value( key , 2**properties.get("opcode") - 1 )

    return value

def process_instructions( field : dict , properties ):
    if field == None:
        return None
    
    processed_field = {}
    
    for tag in field:
        key = field[tag]
        if isinstance( key , list ):

            new_key = []
            for idx in range( len(key) ):
                new_key.append( process_instruction_key( key[idx] , tag , properties ) )

            processed_field[ tag.upper() ] = new_key
            
        else:
            processed_field[ tag.upper() ] = [process_instruction_key( key , tag , properties ) , None]

    return processed_field

def process_microcodes( field : dict ):

    if field == None:
        return None
    
    in_block_comment = False
    
    for key in field:
        processed_microcode = []
        replacements = field[key]
#TODO: Microcode multiline comments
        for line in replacements:
            line = line.split("#")[0] # Remove single line comments
            line = " ".join( line.split() ) #Remove duplicate spaces
            line = line.replace(" " , "," ) #Replace all spaces with commas
            #Delete C-style single line comments
            line = re.sub( r'[/*].+[*/]' , '', line )
            #Remove any duplicated commas:
            line = remove_duplicates_of( ',' , line )
            #These two if statements hand multiline C-Style Comments
            if (line != ""):
                line = line[:len(line)-1]
                line = line.replace(",;" , ';' ) + ';'
                processed_microcode.append(line)
        field[key] = processed_microcode

    return field

def process_description( raw_description : json ):

    processed_description = {}

    processed_description["registers"]    = process_registers( raw_description.get("registers") )
    processed_description["instructions"] = process_instructions( raw_description.get("instructions") , raw_description.get("parameters").get("widths") )
    processed_description["microcode"]    = process_microcodes( raw_description.get("microcode") )
    processed_description["widths"]       = raw_description.get("parameters").get("widths")

    return processed_description


    
def load_description( description_file : str ):
    try:
        description = open( description_file , "r" )
    except OSError:
        sys.exit( 'ERROR: Couldnt find description file "' + description_file + '"')
    raw_desc = json.load( description )

    return process_description( raw_desc )

def tidy_source_line( line : str ):

    between_brackets = re.findall( r'[(].+?[)]' , line )

    if between_brackets != []:
        
        for idx in range(0 , len(between_brackets) ):

            to_replace = "".join( between_brackets[idx].split() )
            line = line.replace( between_brackets[idx] , to_replace )

    line = line.split("#")[0] # Remove single line comments
    line = " ".join( line.split() ) #Remove duplicate spaces
    line = line.replace(" " , "," ) #Replace all spaces with commas
    #Delete C-style single line comments
    line = re.sub( r'[/*].+[*/]' , '', line )
    
    #Remove any duplicated commas:
    line = remove_duplicates_of( ',' , line )

    line = line.replace(":," , ":" )

    return line

def format_source_replace_microcode( file , line : str):

    fields = line.split(",")
    
    identifier = fields[0]

    microcodes = processor_description.get("microcode")

    microcoded = microcodes.get(fields[0].upper())

    if microcoded != None:
        line = ""
        for each in microcoded:
            each = each.replace(';','\n')
            for idx in range(1 , len(fields) ):
                each = each.replace('{%' + str(idx) + '}' , str(fields[idx]).replace(';','') )

            line = line + each
    else:
        line = line + '\n'

    return line

def format_source( source_file : str ):
    try:
        source = open( source_file , "r" )
    except OSError:
        sys.exit( 'ERROR: Couldnt find source file "' + source_file + '"')
    copy = open( temp_file_name , "w" )

    in_block_comment = False

    for line in source:

        #First thing to do is find out if there are any quotes as these should be immune to any formatting we do
        between_qoutes = re.search('"(.+?)"', line)

        line = tidy_source_line( line )
        #For same line label + instruction / data
        if (line.find(":") != -1) & (line.endswith(':') == False):
            line = line.replace(':' , ':\n' , 1)

        #These two if statements hand multiline C-Style Comments
        if (line.find("/*") != -1):
            in_block_comment = True
            prev_comment = line.split("/*")[0]
            if( prev_comment != "" ):
                 copy.write(prev_comment )

        if (line.find("*/") != -1) & in_block_comment == True:
            in_block_comment = False
            continue

        if between_qoutes != None:
            between_qoutes = '"' + between_qoutes.group(1) + '"'
 
            line = re.sub( r'["].+["]' , between_qoutes , line )

        if (line != "") & (in_block_comment == False) :
            
            line = line if line.endswith( ';' ) else line + ";"
            line = line.replace(",;" , '' )
            line = line.replace(":;" , ':' )

            line = format_source_replace_microcode( copy , line )

            copy.write( line )

    copy.close()
    source.close()

    return temp_file_name

def remove_duplicates_of( delim : str , string : str ):

    removed = string.split( delim )
    new_str = ""
    for idx in range(0 , len( removed ) ):
        if( removed[idx] != "" ):
            new_str = new_str + removed[idx] + delim
    return new_str

def fetch_next_token( file ):

    line = file.readline()
    line = line.rstrip('\n\r\t')

    return line

def lookup_register( description : dict , search : str , token : str = "" ):
    ret_val = description.get( search )
    if ret_val == None:
        sys.exit("ERROR: Reference to unknown register ID: '" + search + "' in token " + token )
    return ret_val

def process_hi_lo_args( arg ):
    arg = arg.upper()

    ret_val = 0

    if arg in subroutine_handles:
        
        ret_val = 0#directives[ arg ]

    else:
        try:
            ret_val = int(arg)
        except ValueError:
            label = directives.get(arg)
            if( label == None ):
                sys.exit("ERROR reference to unknown label '" + arg + "'")
            else:
                ret_val = label

    return ret_val

def handle_instruction_arg( arg : str , opcode : str ):

    spilt_args = arg.split("(")
    command    = spilt_args[0]
    ret_val = 0

    try:

        ret_val = int(command)

    except ValueError:
        match command:
            case "%literal":
                ret_val = eval( spilt_args[1].split(")")[0] )
            case "%hi":
                #shift 16 bits to discard bottom 16 bits and replace them with the upper 16 bits
                #0xFFFF to keep 16 bits and ditch the rest
                ret_val = 0xFFFF & ( process_hi_lo_args( spilt_args[1].split(")")[0] ) >> 16 )
            case "%lo":
                ret_val = 0xFFFF & process_hi_lo_args( spilt_args[1].split(")")[0] )
            case "%imm_max":
                ret_val = 2**15 - 1
            case "%imm_min":
                ret_val = -(2**15)
            case "%address":

                ret_val = directives[ re.findall( r'[(](.+?)[)]' , arg )[0] ]["Address"]

            case _:
                ret_val = int(arg)

    return ret_val

def directive_string_to_num( arguments : str ):
    strings = arguments.split('"')
    if( len(strings) % 2 == 0 ):
        sys.exit('ERROR: string missing quotation mark: ' + arguments)

    strings = "".join(strings)
    strings = strings.replace( '\\000' , '\0' )
    strings = strings.replace( '\\a' , '\a' )
    strings = strings.replace( '\\b' , '\b' )
    strings = strings.replace( '\\e' , "\x1B" )
    strings = strings.replace( '\\f' , '\f' )
    strings = strings.replace( '\\n' , '\n' )
    strings = strings.replace( '\\r' , '\r' )

    strings = strings.replace( '\\t' , '\t' )
    strings = strings.replace( '\\v' , '\v' )
    strings = strings.replace( '\\' , '\\' )
    strings = strings.replace( "\\'" , '\'' )
    strings = strings.replace( '\\"n' , '\"' )
    strings = strings.replace( '\\?' , '?' )
    strings = strings.replace( '\\"' , '\"' )
    
#Add extra padding to string
#Each address in memory is 32 bits hence 4 bytes

    strings = strings.encode('ascii')

    return strings

def directive_string_to_bytes( strings : str ):

    str_as_list = []

    for char in strings:

        str_as_list = str_as_list + [format( char  , '02x')]

    return str_as_list

def write_directive_to_file( data : list  ):

    first_address = memory_contents_buffer[0][-1]

    memory_contents_buffer[0].append( first_address + len(data) ) 

    

    for each in data:

        memory_contents_buffer[1].append(each)

    return first_address

def format_hex_str_to_list( string : str , list_len : int ):

    return [ string[ idx : idx + list_len ] for idx in range( 0 , len(string) , list_len ) ]


def handle_directives( label : str , fields : dict ):
    #Remove the directive ID

    for each in fields["Value"]:

        full_directive = each.split(',')

        directive = full_directive.pop(0)

        #Rest is whatever the directive's arguements were
        arguments = ",".join(full_directive)

        match directive:
            case ".ascii":

                string = directive_string_to_bytes( directive_string_to_num( arguments ) )

                address = write_directive_to_file( string )

                directives[label].update( { "Address" : min( address , directives[label].get("Address") ) } )


            case ".asciiz" | ".asciz" :

                arguments = arguments.replace( '"' , '' )

                string = directive_string_to_num( arguments ) if arguments.endswith( '\0' ) else directive_string_to_num( arguments + '\0' )
                string = directive_string_to_bytes( string )

                address = write_directive_to_file( string )

                directives[label].update( { "Address" : min( address , directives[label].get("Address") ) } )

            case ".byte" | ".4byte":

                byte = []
                arguments = arguments.split(',')

                for each in arguments:

                    try:

                        value = [format( int(each) & 0xFF  , '02x')]
                        value = format_hex_str_to_list( value , 2 )
                        byte = byte + value

                    except ValueError:
                        print("ERR")
                address = write_directive_to_file( byte )

                directives[label].update( { "Address" : min( address , directives[label].get("Address") ) } )

            case ".float":

                float_as_hex = ""
                arguments = arguments.split(',')

                for each in arguments:

                    try:

                        float_as_hex = float_as_hex + format( struct.unpack('<I', struct.pack('<f', float(each) ))[0]  , '02x')
    
                    except ValueError:
                        print("ERR")

                address = write_directive_to_file( format_hex_str_to_list( float_as_hex , 2 ) )

                directives[label].update( { "Address" : min( address , directives[label].get("Address") ) } )
            
            case ".word":

                str_as_word = ""
                arguments = arguments.split(',')

                for each in arguments:

                    try:

                        str_as_word = str_as_word + format( int(each) & 0xFFFFFFFF  , '08x')

                    except ValueError:
                        print("ERR")

                address = write_directive_to_file( format_hex_str_to_list( str_as_word , 2 ) )

                directives[label].update( { "Address" : min( address , directives[label].get("Address") ) } )

handle_directives.current_program_mode = "instruction_mode"

def token_to_instruction( token : str , line : int ):

    if token == '':
        return ""
    instruction = ""
    fields = token.split(',')

    instruction_opcode = fields[0].upper()
    #Look up in the JSON for the opcode and funct data of the instruction
    #Formatted [opcode,funct]
    description_instructions = processor_description.get("instructions")
    description_registers    = processor_description.get("registers")
    description_widths       = processor_description.get("widths")

    instruction_data = description_instructions.get( instruction_opcode )

    if instruction_data == None:

        if(fields[0].find('.') != -1):
            a = 0
            #handle_directives( fields )
        else:
            sys.exit( "ERROR: Undefined instruction: '" + fields[0] + "', line " + find_in_source( source_filename , fields[0] ) )

    else:
        opcode = instruction_data[0]
        instruction = numpy.binary_repr( opcode , int(description_widths.get("opcode")) )

        #Handling the R-TYPE instructions
        if opcode == 0:#R-type
            #If our instruction is R t-type this it is structured:
            # Op | R1 | R2 | WR | SH | F
            reg_a = ""
            reg_b = ""
            w_reg = ""
            shamt = numpy.binary_repr( 0 , int(description_widths.get("shamt")) )
            funct = numpy.binary_repr( description_instructions.get(instruction_opcode)[1]  , int(description_widths.get("function")) )

            match len(fields):
                #Simplest case, concerns instructions which have 3 registers specified
                case 4:
                    #Special case with the 4 field R instructions
                    w_reg = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                    
                    if ( instruction_opcode == "SLL") | ( instruction_opcode == "SRL") | ( instruction_opcode == "SRA"):
                        reg_a = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                        reg_b = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                        shamt = numpy.binary_repr( int(fields[3]) , int(description_widths.get("shamt")) )
                    else:
                        reg_a = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                        reg_b = numpy.binary_repr( lookup_register( description_registers , fields[3].lower() , token ) , int(description_widths.get("registers")) )
                case 3:
                    #This case concerns MUL/DIV etc and JAL
                    match instruction_opcode:
                        case "MULT" | "MULTU" | "DIV" | "DIVU":
                            reg_a = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                            reg_b = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                            w_reg = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                        case "JALR":
                            reg_a = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                            reg_b = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                            w_reg = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                        case _:
                            sys.exit( "ERROR: Invalid instruction: '" + token + "'" )
                case 2:
                    match instruction_opcode:
                        case "JR" | "JALR" | "MTHI" | "MTLO":
                            reg_a = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                            reg_b = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                            w_reg = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                        case "MFHI" | "MFLO":
                            reg_a = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                            reg_b = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                            w_reg = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token) , int(description_widths.get("registers")) )
                        case _:
                            sys.exit( "ERROR: Invalid instruction: '" + token + "'" )
                case 1:
                    sys.exit( "ERROR: Invalid instruction: '" + token + "'" )
                case _1:
                    sys.exit( "ERROR: Invalid instruction: '" + token + "'" )
            instruction = instruction + reg_a + reg_b + w_reg + shamt +  funct
        else:
            #Handle the J-type and I-type instructions
            if ( instruction_opcode == "J" ) | ( instruction_opcode == "JAL" ):#Only 2 J-types
                if isinstance( fields[1] , int ):
                    instruction = instruction + numpy.binary_repr( int(fields[1]) , 32 - int(description_widths.get("opcode")) )
                if isinstance( fields[1] , str ):

                    address = subroutine_handles.get(fields[1])
                    if address == None:
                        sys.exit("ERROR: Reference to non-existant subroutine: '" + fields[1] + "'" )
                    instruction = instruction + numpy.binary_repr( address , 32 - int(description_widths.get("opcode")) )

            else:
                #Now handle I-Types:
                immediate = ""
                reg_a = ""
                reg_b = ""
                match instruction_opcode:
                    #Make exceptions for the follow 4 branch instructions
                    case "BEQ" | "BNE" :
                        reg_a = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                        reg_b = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                        if isinstance( fields[3] , int ):
                            immediate = numpy.binary_repr( handle_instruction_arg( fields[3] , opcode ) , int(description_widths.get("immediates")) )
                        if isinstance( fields[3] , str ):

                            target = subroutine_handles.get( fields[3] )

                            if target == None:
                                sys.exit("ERROR: Reference to non-existant subroutine: '" + fields[3] + "'" )

                            immediate = numpy.binary_repr( target - line + 1 , int(description_widths.get("immediates")) )

                    case "BLEZ" | "BGTZ":
                        reg_a = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )
                        reg_b = numpy.binary_repr( 0 , int(description_widths.get("registers")) )
                        if isinstance( fields[2] , int ):
                            immediate = numpy.binary_repr(  handle_instruction_arg( fields[2] , opcode ) , int(description_widths.get("immediates")) )
                        if isinstance( fields[2] , str ):

                            target = subroutine_handles.get(  fields[2] )

                            if target == None:
                                sys.exit("ERROR: Reference to non-existant subroutine: '" + fields[2] + "'" )

                            immediate = numpy.binary_repr( target - line + 1 , int(description_widths.get("immediates")) )
                    case _:
                        imm_val = 0
                        reg_b = numpy.binary_repr( lookup_register( description_registers , fields[1].lower() , token ) , int(description_widths.get("registers")) )

                        match len(fields):
                            case 4:
                                reg_a = numpy.binary_repr( lookup_register( description_registers , fields[2].lower() , token ) , int(description_widths.get("registers")) )
                                imm_val    = handle_instruction_arg( fields[3] , opcode )
                            case 3:#SW etc
                                addressing = fields[2].replace(')' , '' ).split('(')
                                #index of -1 denotes end of list
                                reg_a      = numpy.binary_repr( lookup_register( description_registers , addressing[-1].lower() , token ) , int(description_widths.get("registers")) )
                                imm_val    = handle_instruction_arg( addressing[0] + "(" + addressing[1].lower()  + ")" , opcode )
                            case _:
                                sys.exit( "ERROR: Invalid instruction: '" + token + "'" )

                        
                        immediate = numpy.binary_repr( imm_val , int(description_widths.get("immediates")) )

                instruction = instruction + reg_a + reg_b + immediate

    return instruction



#Main meat of the assembler
def process_token( token : str , index : int ): 

    instruction = ""

    if not hasattr( process_token , "mode" ):
        process_token.mode = 0

    if (token.find('.data') != -1):
        process_token.mode = 0

    if (token.find('.text') != -1):
        process_token.mode = 1

    if process_token.mode == 1:
        increment_index = True

        #If we detect this token is a label then we don;t want to increment the instruction index
        if (token.find(':') != -1) | (token == ""):

            increment_index =  False

        else:

            instruction = token_to_instruction( token , index )

        #Index holds the current instruction count
        if increment_index == True:
            index = index + 1

    return [instruction , index]
process_token.mode = 0

#Main function to perform the assembly

def process_data_segments( token : str ):
    if not hasattr( process_data_segments , "last_label" ):
        process_data_segments.last_label = None

    if( token.find(':') != -1 ) & ( token.endswith(':') == True ):
        label = token.split(':')

        label = label[0]

        token = token.replace( label + ":" , '' , 1 )

        process_data_segments.last_label = label

        if directives.get(label):

            directives[label]["Value"].append(token)
            directives[label]["Address"] = 2**33 #32 bit cannot store such a number

        else:
            directives[label] = { "Value" : [token]}
            directives[label]["Address"] = 2**33

    else:

        if( token.find('.') != -1 ):

            if( process_data_segments.last_label == None ):
                sys.exit("ERROR: Directive with no associated label")
            else:
                if directives.get(process_data_segments.last_label):
                    directives[process_data_segments.last_label]["Value"].append(token)
                else:
                    directives[process_data_segments.last_label] = { "Value" : [token]}

process_data_segments.last_label = None

def fetch_subroutines( temp_filename : str ):

    in_instruction_segment = True

    index = 0
    token = " "
    processed_file = open( temp_filename , "r" )
    increment_index = True

    while token != "":

        #If we detect this token is or contains a subroutine name then we store it in the subroutine list.
        token = fetch_next_token( processed_file )

        if ( token.find('.data') != -1 ):
            in_instruction_segment = False
            continue
        if ( token.find('.text') != -1 ):
            in_instruction_segment = True
            continue

        if (token.find(':') != -1) & ( in_instruction_segment == True ):

            subroutine_name = token.split(':')[0]

            #Subroutines are not allowed to be a number as it makes them indistinguishable from a raw address
            if subroutine_name.isnumeric() | (subroutine_name == ""):

                sys.exit("ERROR: Invalid subroutine name: '" + subroutine_name + "' near line " + find_in_source( source_filename , subroutine_name + ":" ) )

            else:

                subroutine_handles[subroutine_name] = index

                increment_index =  False

        else:

            if ( in_instruction_segment == False ) :

                process_data_segments( token )

            if in_instruction_segment == True:
                increment_index = True
            else:
                increment_index = False

        #Index holds the current instruction count
        if increment_index == True:
            index = index + 1
    data_memory_file = open( output_path + memory_init_filename , "w" )

    for each in directives:
        #Remove any empty entries in the list of directives
        directives[each]["Value"] = list( filter( None , directives[each]["Value"] ) )

        handle_directives( each , directives[each] )

    print(directives)

    local_data    = memory_contents_buffer[1]

    local_data = [ local_data[i:i+4] for i in range(0, len(local_data), 4) ]

    memory_contents_address = 0x10

    for each in local_data:

        data_memory_file.write( "0x" + format( memory_contents_address , "08x" ) + " " )

        if( len(each) != 4 ):

            for iter in range( 0 , 4 - len(each) % 4 ):
                each.append('00')

        data_memory_file.write( "0x" + "".join(each) + "\n" )

        memory_contents_address += 4


    processed_file.close()
    data_memory_file.close()

def assemble( temp_filename : str , output_file : str ):

    token = " "
    instruction = " "
    index = 0

    #Go through the file and find all subroutines

    fetch_subroutines( temp_filename )

    processed_file = open( temp_filename , "r" )
    output         = open( output_file , "w" )
    count          = 0

    while token != "":
        token = fetch_next_token( processed_file )
        [instruction , index] = process_token( token , index )

        if (instruction != "") & (instruction != None):
            output.write( instruction + "\t" + str(count) + "\t=> " + '0x%08x' % int(instruction,2) + "\t=> " + token + "\n" )
            count = count + 4

    processed_file.close()
    output.close()


    return instruction

def description_to_vhdl_definition_file( defines_filename ):
    defines_file     = open( defines_filename , "w" )

    defines_file.write("---Autogenerated file by MIPs assembler---\n")

    defines_file.write("library ieee;\n")
    defines_file.write("use ieee.std_logic_1164.all;\n")
    defines_file.write("use IEEE.std_logic_unsigned.all;\n\n")

    defines_file.write("package defines is\n\n")
    defines_file.write("\ttype alu_operations is ( ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU, ALU_MUL, ALU_DIV, ALU_AND, ALU_OR, ALU_NOR, ALU_XOR, ALU_LSL, ALU_RSL, ALU_LSA, ALU_RSA, ALU_LESS_THAN);\n\n")

    defines_file.write("\ttype inst_opcodes is (\n\t\tOp_R_TYPE,\n")

    instructions = processor_description.get("instructions")
    widths       = processor_description.get("widths")

    opcode_max = 0

    for each in instructions:
        if( instructions[each][0] != 0 ):
            defines_file.write("\t\tOp_" + each + ",\n")
        opcode_max = max(instructions[each][0],opcode_max)
    defines_file.write("\t\tOp_ENUM_MAX\n\t);\n\n")

    #defines_file.write("\tattribute op_encoding : std_logic_vector( " + str(widths.get("opcode")-1) + " downto 0 );\n\n")
    defines_file.write("\tattribute op_encoding : std_logic_vector ;\n\n")

    defines_file.write('''\tattribute op_encoding of Op_R_TYPE[return inst_opcodes] : literal is b"000000";\n''')

    for each in instructions:
        if( instructions[each][0] != 0 ):
            defines_file.write("\tattribute op_encoding of Op_" + each + '''[return inst_opcodes] : literal is b"''')
            defines_file.write(numpy.binary_repr(instructions[each][0],widths.get("opcode")) +'''";\n''')
    defines_file.write('''\n''')


    defines_file.write("\ttype inst_funct is (\n")

    for each in instructions:
        if( instructions[each][0] == 0 ):
            defines_file.write("\t\tFu_" + each + ",\n")
    defines_file.write("\t\tFu_ENUM_MAX\n\t);\n\n")


    defines_file.write("\tattribute fu_encoding : std_logic_vector;\n\n")

    for each in instructions:
        if( instructions[each][0] == 0 ):
            defines_file.write("\tattribute fu_encoding of Fu_" + each + '''[return inst_funct] : literal is b"''')
            defines_file.write(numpy.binary_repr(instructions[each][1],widths.get("function")) +'''";\n''')
    defines_file.write('''\n''')

    defines_file.write("---Lookup functions\n")
    defines_file.write("\tfunction lookup_inst_opcode( lookup_val : in integer ) return inst_opcodes;\n")
    defines_file.write("\tfunction lookup_inst_funct( lookup_val : in integer ) return inst_funct;\n\n")

    defines_file.write("end package defines;\npackage body defines is\n\n")

#Opcode lookup function:
    defines_file.write("\tfunction lookup_inst_opcode( lookup_val : in integer) return inst_opcodes is\n")
    defines_file.write("\t\tvariable ret_val : inst_opcodes := Op_R_TYPE;\n")
    defines_file.write("\tbegin\n")
    defines_file.write("\t\tcase( lookup_val ) is\n")

    for each in instructions:
        if( instructions[each][0] != 0 ):
            defines_file.write("\t\t\twhen 2#"+str(numpy.binary_repr( instructions[each][0] , widths.get("opcode") ))+"# =>\n")
            defines_file.write("\t\t\t\tret_val := Op_" + each + ";\n")
    defines_file.write("\t\t\twhen others =>\n")
    defines_file.write("\t\t\t\tret_val := Op_R_TYPE;\n\t\tend case;\n\t\treturn ret_val;\n\tend function;\n\n\n")

#Function block lookup function:
    defines_file.write("\tfunction lookup_inst_funct( lookup_val : in integer) return inst_funct is\n")
    defines_file.write("\t\tvariable ret_val : inst_funct := Fu_SLL;\n")
    defines_file.write("\tbegin\n")
    defines_file.write("\t\tcase( lookup_val ) is\n")

    for each in instructions:
        if( instructions[each][0] == 0 ):
            defines_file.write("\t\t\twhen 2#"+str(numpy.binary_repr( instructions[each][1] , widths.get("function") ))+"# =>\n")
            defines_file.write("\t\t\t\tret_val := Fu_" + each + ";\n")
    defines_file.write("\t\t\twhen others =>\n")
    defines_file.write("\t\t\t\tret_val := Fu_SLL;\n\t\tend case;\n\t\treturn ret_val;\n\tend function;\n\n\n")
#End file

    defines_file.write("end package body defines;\n")
                       
    defines_file.write("---End of file")
    defines_file.close()

def description_to_verilog_definition_file( defines_filename ):
    defines_file     = open( defines_filename , "w" )

    instructions = processor_description.get("instructions")
    widths       = processor_description.get("widths")

    defines_file.write("//Autogenerated file by MIPs assembler\n")

    defines_file.write("\ttypedef enum { ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU, ALU_MUL, ALU_DIV, ALU_AND, ALU_OR, ALU_NOR, ALU_XOR, ALU_LSL, ALU_RSL, ALU_LSA, ALU_RSA , ALU_LESS_THAN} alu_operations;\n\n")

    defines_file.write("\ttypedef enum {\n\t\tOp_R_TYPE = " + numpy.binary_repr(0,widths.get("opcode")) + ",\n")


    for each in instructions:
        if( instructions[each][0] != 0 ):
            defines_file.write("\t\tOp_" + each + "\t= " + str(widths.get("opcode")) + "'b"+ numpy.binary_repr(instructions[each][0],widths.get("opcode")) +",\n")
    defines_file.write("\t} inst_opcodes;\n\n")

    defines_file.write("\ttypedef enum {\n")

    for each in instructions:
        if( instructions[each][0] == 0 ):
            defines_file.write("\t\tFu_" + each + " = " + str(widths.get("function")) + "'b"+ numpy.binary_repr(instructions[each][1],widths.get("function")) +",\n")
    defines_file.write("\tFu_ENUM_MUX\n\t}inst_funct;\n\n")

    defines_file.write("//End of file")
    defines_file.close()

    
if __name__ == "__main__":

    args = parse_args()
    if args == None:
        print("Converts MIPs-Style assembly into machine code based on the provided JSON description file")
        print("args:")
        print("\t--source / -s:\n\t\tFilename of the assembly source file")
        print("\t--desc   / -d:\n\t\tFilename of the processor description file")
        print("\t--output / -o:\n\t\tFilename of the output file")
        print("\t--hdl    / -v:\n\t\tShould the tool produce a VHDL/Verilog file ")
    else:
        #If wanted we can output to a custom path

        source_filename       = args[0]
        output_filename       = args[1]
        description_filename  = args[2]
        defines_hdl_file_type = args[3]
        output_path           = args[4]
        memory_init_filename  = args[5]

        output_filename = output_path + output_filename

        processor_description = load_description( description_filename )
        processed_source_file = format_source( source_filename )

        if args[3].upper() == "VHDL":
            description_to_vhdl_definition_file( output_path + "defines.vhdl")
        if args[3].upper() == "VERILOG":
            description_to_verilog_definition_file( output_path + "defines.v" )

        assemble( processed_source_file , output_filename )

        print("----Processing report----")
        print("-> Microcoded instructions [name , equivalent instruction(s)]:" , "\n")
        print("\t" , processor_description.get("microcode"), "\n")
        print("-> Detected subroutine labels [name , instruction number]:" , "\n")
        print("\t" , subroutine_handles , "\n")
        print("-> Interpreted the following data segment (JSON):" , "\n")
        print("\t" , directives , "\n")

        if (defines_hdl_file_type == "") | (defines_hdl_file_type.lower() == "none") :
            print("-> No HDL file required")
        else:
            print("-> Writing HDL file in " + defines_hdl_file_type )


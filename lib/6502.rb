class Disassembler
    def initialize()
        @result = ""
				@byte_counter = 0
        @operations = generate_operations
    end
    def decode_op(i, byte_arr)
        op = byte_arr[i]
        opcode = @operations[op]
        if opcode then
            bytes = opcode[:bytes]
            bink = ""
            if bytes == 1
              bink << op
            elsif bytes == 2
              bink << op << " " << byte_arr[i+1]
            elsif bytes == 3
              bink << op << " "<< byte_arr[i+1] << " " << byte_arr[i+2]
            end
            @result << "#{sprintf('%#010x',@byte_counter)}: #{bink} #{opcode[:opcode].downcase}"
            
            j = 2
            value = ""
            while j <= bytes
                value << "%02x" % (byte_arr[i+j-1].hex)
                j+=1
            end
            literal = '#' if opcode[:args].include?('#')
            literal = '' unless opcode[:args].include?('#')
            @result << "#{literal}$#{value[2..3] + value[0..1]}\n" if bytes > 2
            @result << "#{literal}$#{value}\n" if bytes == 2
            @result << "\n" if bytes == 1
	    @byte_counter += bytes
            bytes
        else
            1
        end
    end
    def disassemble(input)
        @input = input
        @result = ""
        bytes = input.split("\s")
        i = 0
        while i < bytes.size
            i += decode_op(i, bytes)
        end
        @result
    end
    #generate opcode hash from text file
    def generate_operations(path = './lib/opcodes_6502.txt')
        file = File.open(path, 'r').read
        @operations = {}
        file.each_line do |line|
            out = /\$([0-9a-f]*) "(\w\w\w\d?)\s?(.*)"/.match(line)
            add_opcode(@operations, out)
        end
        @operations
    end
    private
    def get_bytes(args)
        bytes = 2
        bytes = 1 if args == "" || args == "A"
        bytes += 1 if args.include?("?")
        bytes += 1 if args.include?("_")
        bytes
    end
    def add_opcode(operations, out)
        bytes = get_bytes(out[3])
        operations[out[1]] = {opcode: out[2], hex: out[1], bytes: bytes, args: out[3]}
    end
end

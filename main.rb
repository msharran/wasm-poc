require 'wasmer'
require 'json'

class WasmRuntime
  def initialize(wasm_bin_file)
    @store = Wasmer::Store.new
    module_ = Wasmer::Module.new @store, IO.read(wasm_bin_file, mode: 'rb')
    wasi_version = Wasmer::Wasi.get_version module_, true
    wasi_env =
      Wasmer::Wasi::StateBuilder.new('wasi_test_program')
                                .argument('--test')
                                .environment('COLOR', 'true')
                                .environment('APP_SHOULD_LOG', 'true')
                                .map_directory('the_host_current_dir', '.')
                                .finalize

    import_object = wasi_env.generate_import_object @store, wasi_version
    @instance = Wasmer::Instance.new module_, import_object
    @instance.exports._start.call
  end

  def greet(name)
    raise 'Error: Name not a string' unless name.instance_of?(String)

    puts "sending to WASM: #{name}"

    data_bytes = name.bytes.push(0)
    # Load input in memory
    input_mem_ptr = load_to_memory(data_bytes)

    # pass input memory and get output memory
    output_mem_ptr = @instance.exports.Greet.call(input_mem_ptr)

    # read response from output memory
    response = @instance.exports.memory.uint8_view(output_mem_ptr).take_while { |b| b != 0 }.pack('U*')

    puts "recieved from WASM: #{response}"
  end

  def add_foo_tag(msg)
    raise 'Error: msg not a string' unless msg.instance_of?(String)

    puts "sending to WASM: #{msg}"

    data_bytes = msg.bytes.push(0)
    # Load input in memory
    input_mem_ptr = load_to_memory(data_bytes)

    # pass input memory and get output memory
    output_mem_ptr = @instance.exports.AddFooTag.call(input_mem_ptr)

    # read response from output memory
    response = @instance.exports.memory.uint8_view(output_mem_ptr).take_while { |b| b != 0 }.pack('U*')

    puts "recieved from WASM: #{response}"
  end

  private

  def load_to_memory(data_in_bytes)
    # Allocate memory for input
    input_mem_ptr = @instance.exports.GetMemoryBuffer.call(data_in_bytes.length)

    # Write input data into allocated memory
    mem = @instance.exports.memory.uint8_view input_mem_ptr
    (0..data_in_bytes.length - 1).each do |nth|
      mem[nth] = data_in_bytes[nth]
    end

    # return the starting pointer address of the allocated memory
    input_mem_ptr
  end
end

wasm_bin_file = "#{__dir__}/bin/go.wasm"
msg = { name: 'Foo', subject: 'foo bar' }

wasm_runtime = WasmRuntime.new wasm_bin_file
wasm_runtime.add_foo_tag msg.to_json

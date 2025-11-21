#include "cpu_sim.hh"
#include "elf_loader.hh"
#include "instruction.hh"
#include <iomanip>
#include <iostream>

CPUSimulator::CPUSimulator(bool enable_trace)
    : _dut(new Vrv32_cpu), _imem(new Memory(256 * 1024, 0x00000000)),
      _dmem(new Memory(256 * 1024, 0x80000000)), trace_(new ExecutionTrace()),
      _time_counter(0), _cycle_count(0), _inst_count(0), _timeout(1000000),
      verbose_(false), profiling_(false), trace_enabled_(enable_trace) {
#ifdef ENABLE_TRACE
  if (trace_enabled_) {
    Verilated::traceEverOn(true);
    _vcd = std::make_unique<VerilatedVcdC>();
    _dut->trace(_vcd.get(), 99);
    _vcd->open("rv32_cpu.vcd");
  }
#endif
}

CPUSimulator::~CPUSimulator() {
#ifdef ENABLE_TRACE
  if (_vcd) {
    _vcd->close();
  }
#endif
}

bool CPUSimulator::load_bin(const std::string &filename, uint32_t base_addr) {
  return _imem->load_binary(filename, base_addr);
}

bool CPUSimulator::load_elf(const std::string &filename) {
  return ELFLoader::load(filename, *_imem);
}

void CPUSimulator::reset() {
  _dut->reset = 1;
  clock_tick();
  clock_tick();
  _dut->reset = 0;
  clock_tick();

  _cycle_count = 0;
  _inst_count = 0;
  register_values_.clear();
  pc_histogram_.clear();
}

void CPUSimulator::clock_tick() {
  _dut->imem_inst = _imem->read32(_dut->imem_addr);

  _dut->clock = 1;
  _dut->eval();

#ifdef ENABLE_TRACE
  if (_vcd) {
    _vcd->dump(_time_counter++);
  }
#endif

  if (_dut->debug_reg_write) {
    register_values_[_dut->debug_reg_addr] = _dut->debug_reg_data;
    _inst_count++;

    if (trace_enabled_) {
      TraceEntry entry;
      entry.cycle = _cycle_count;
      entry.pc = _dut->debug_pc;
      entry.inst = _dut->debug_inst;
      entry.rd = _dut->debug_reg_addr;
      entry.rd_val = _dut->debug_reg_data;
      entry.rd_written = true;

      Instruction inst(_dut->debug_inst);
      entry.disasm = inst.to_string();

      trace_->add_entry(entry);
    }

    if (profiling_) {
      pc_histogram_[_dut->debug_pc]++;
    }

    if (verbose_) {
      std::cout << "Cycle " << std::dec << std::setw(6) << _cycle_count
                << " | PC=0x" << std::hex << std::setw(8) << std::setfill('0')
                << _dut->debug_pc << " | Inst=0x" << std::setw(8)
                << _dut->debug_inst << " | x" << std::dec
                << (int)_dut->debug_reg_addr << "=0x" << std::hex
                << std::setw(8) << _dut->debug_reg_data << std::dec
                << std::endl;
    }
  }

  _dut->clock = 0;
  _dut->eval();

#ifdef ENABLE_TRACE
  if (_vcd) {
    _vcd->dump(_time_counter++);
  }
#endif

  _cycle_count++;
}

void CPUSimulator::step(int cycles) {
  for (int i = 0; i < cycles; i++) {
    clock_tick();
  }
}

void CPUSimulator::run(uint64_t max_cycles) {
  uint64_t target = max_cycles > 0 ? max_cycles : _timeout;

  while (_cycle_count < target) {
    clock_tick();
    check_termination();
  }

  if (verbose_) {
    std::cout << "\nSimulation completed after " << _cycle_count << " cycles\n";
  }
}

void CPUSimulator::run_until(uint32_t pc) {
  while (_dut->debug_pc != pc && _cycle_count < _timeout) {
    clock_tick();
  }
}

uint32_t CPUSimulator::get_pc() const { return _dut->debug_pc; }

uint32_t CPUSimulator::get_reg(uint8_t reg) const {
  if (reg == 0)
    return 0;
  auto it = register_values_.find(reg);
  return it != register_values_.end() ? it->second : 0;
}

uint32_t CPUSimulator::read_mem(uint32_t addr) const {
  if (addr >= _dmem->base_addr()) {
    return _dmem->read32(addr);
  }
  return _imem->read32(addr);
}

void CPUSimulator::write_mem(uint32_t addr, uint32_t data) {
  if (addr >= _dmem->base_addr()) {
    _dmem->write32(addr, data);
  } else {
    _imem->write32(addr, data);
  }
}

double CPUSimulator::get_ipc() const {
  return _cycle_count > 0 ? (double)_inst_count / _cycle_count : 0.0;
}

void CPUSimulator::dump_registers() const {
  std::cout << "\n========================================\n";
  std::cout << "Register Dump\n";
  std::cout << "========================================\n";

  for (int i = 0; i < 32; i++) {
    std::cout << "x" << std::dec << std::setw(2) << i << " = 0x" << std::hex
              << std::setw(8) << std::setfill('0') << get_reg(i);
    if (i % 4 == 3)
      std::cout << "\n";
    else
      std::cout << "  ";
  }
  std::cout << std::dec << std::endl;
}

void CPUSimulator::dump_memory(uint32_t start, uint32_t size) const {
  std::cout << "\n========================================\n";
  std::cout << "Memory Dump: 0x" << std::hex << start << " - 0x"
            << (start + size) << "\n";
  std::cout << "========================================\n";

  for (uint32_t addr = start; addr < start + size; addr += 16) {
    std::cout << std::hex << std::setw(8) << std::setfill('0') << addr << ": ";
    for (uint32_t i = 0; i < 16 && (addr + i) < (start + size); i++) {
      if (i == 8)
        std::cout << " ";
      std::cout << std::hex << std::setw(2) << std::setfill('0')
                << (int)((read_mem(addr + i) >> ((i % 4) * 8)) & 0xFF) << " ";
    }
    std::cout << std::endl;
  }
  std::cout << std::dec << std::endl;
}

void CPUSimulator::save_trace(const std::string &filename) {
  trace_->save(filename);
}

void CPUSimulator::check_termination() {}

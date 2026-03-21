from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout


class NewEngineConan(ConanFile):
    settings = "os", "compiler", "arch", "build_type"

    options = {
        "with_python_bindings": [True, False],
    }
    default_options = {
        "with_python_bindings": False,
    }

    def requirements(self):
        # Core dependencies (all public)
        self.requires("fmt/11.1.3")
        self.requires("spdlog/1.15.1")
        self.requires("abseil/20240722.0")
        self.requires("protobuf/5.29.3")
        self.requires("rapidjson/cci.20230929")
        self.requires("tsl-robin-map/1.3.0")
        self.requires("zstd/1.5.6")
        self.requires("zlib/1.3.1")

        # Testing
        self.requires("gtest/1.16.0")
        self.requires("benchmark/1.9.1")

        # Optional heavy dependencies — uncomment as needed
        # self.requires("arrow/18.1.0")
        # self.requires("hdf5/1.14.5")

        # Python bindings
        if self.options.with_python_bindings:
            self.requires("nanobind/2.4.0")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()

        tc = CMakeToolchain(self)
        tc.generate()

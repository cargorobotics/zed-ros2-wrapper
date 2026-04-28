#include <iostream>
#include <string>
#include <vector>

#include <sl/Camera.hpp>
#include <sl/CameraOne.hpp>

std::string inferDistortionModel(const sl::CameraParameters& cam) {
    // Align with the calibration logic in opencv_calibration.hpp:
    // if p1/p2 are zero and fisheye-specific terms are populated, treat as fisheye.
    if (cam.disto[2] == 0.0f && cam.disto[3] == 0.0f &&
        cam.disto[4] != 0.0f && cam.disto[5] != 0.0f) {
        return "fisheye";
    }
    return "radial-tangential (pinhole)";
}

void printCameraIntrinsics(const sl::CameraOneInformation& info) {
    const auto& calib = info.camera_configuration.calibration_parameters_raw;
    const auto& cam = calib;

    std::cout << "resolution: "
              << info.camera_configuration.resolution.width << "x"
              << info.camera_configuration.resolution.height << std::endl;

    std::cout << "fx: " << cam.fx << std::endl;
    std::cout << "fy: " << cam.fy << std::endl;
    std::cout << "cx: " << cam.cx << std::endl;
    std::cout << "cy: " << cam.cy << std::endl;
    std::cout << "distortion_model: " << inferDistortionModel(cam) << std::endl;
    std::cout << "disto: ";
    const size_t disto_count = sizeof(cam.disto) / sizeof(cam.disto[0]);
    for (size_t i = 0; i < disto_count; ++i) {
        std::cout << cam.disto[i] << (i + 1 < disto_count ? ", " : "");
    }
    std::cout << std::endl;
}

int main(int argc, char** argv) {
    std::vector<int> serial_numbers = {305932808, 305481469};
    if (argc > 1) {
        serial_numbers.clear();
        for (int i = 1; i < argc; ++i) {
            serial_numbers.push_back(std::stoi(argv[i]));
        }
    }

    for (const int serial : serial_numbers) {
        sl::InitParametersOne init_params;
        init_params.camera_resolution = sl::RESOLUTION::AUTO;
        init_params.camera_fps = 15;
        init_params.input.setFromSerialNumber(serial);

        sl::CameraOne camera;
        const sl::ERROR_CODE status = camera.open(init_params);
        if (status != sl::ERROR_CODE::SUCCESS &&
            status != sl::ERROR_CODE::INVALID_CALIBRATION_FILE) {
            std::cerr << "serial " << serial << ": open failed -> "
                      << sl::toVerbose(status) << std::endl;
            continue;
        }

        const auto info = camera.getCameraInformation();
        std::cout << "\nserial: " << serial << std::endl;
        std::cout << "model: " << sl::toString(info.camera_model) << std::endl;
        printCameraIntrinsics(info);
        camera.close();
    }

    return 0;
}

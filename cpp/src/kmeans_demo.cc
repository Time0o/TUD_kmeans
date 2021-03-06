#include <cstring>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#include <opencv2/opencv.hpp>

#include "kmeans_wrapper.h"

int main(int argc, char **argv)
{
    cv::Mat image;
    int n_clusters;

    if (argc < 4) {
        std::cerr << "Usage: " << argv[0] << " IMAGE CLUSTERS RESULT_OUT\n";
        return -1;
    }

    // load image
    image = cv::imread(argv[1]);
    if (image.empty()) {
        std::cerr << "Failed to load image file '" << argv[1] << "'\n";
        return -1;
    }

    // parse number of clusters
    try {
        size_t idx;
        n_clusters = std::stoi(argv[2], &idx);

        if (idx != strlen(argv[2]))
            throw std::invalid_argument("trailing garbage");

    } catch (std::exception const &e) {
        std::cerr << "Failed to parse number of clusters: " << e.what() << '\n';
        return -1;
    }

    // initialize implementation variants
    std::vector<std::pair<char const *, KmeansWrapper *>> impl;

    KmeansOpenCVWrapper opencv_wrapper;
    impl.push_back(std::make_pair("OpenCV", &opencv_wrapper));

    KmeansPureCWrapper pure_c_wrapper;
    impl.push_back(std::make_pair("Pure C", &pure_c_wrapper));

    KmeansOMPWrapper omp_c_wrapper;
    impl.push_back(std::make_pair("C + OpenMP", &omp_c_wrapper));

    KmeansCUDAWrapper cuda_c_wrapper;
    impl.push_back(std::make_pair("C + CUDA", &cuda_c_wrapper));

    // setup results display window
    const int margin = 10;

    cv::Mat win_mat(
        cv::Size((image.cols + margin) * impl.size(), image.rows + 50),
        CV_8UC3, cv::Scalar(0, 0, 0)
    );

    int offs = margin / 2;
    for (auto const &pane: impl) {
        char const *title = std::get<0>(pane);

        // get result and execution time for each wrapper
        KmeansWrapper *wrapper = std::get<1>(pane);
        wrapper->exec(image, n_clusters);
        cv::Mat result = wrapper->get_result();

        result.copyTo(win_mat(cv::Rect(offs, 0, image.cols, image.rows)));

        // construct subtitles
        std::ostringstream subtext;
        subtext << title;

        cv::putText(win_mat, subtext.str(),
                    cvPoint(offs + margin, image.rows + 30),
                    cv::FONT_HERSHEY_SIMPLEX, 0.6, cv::Scalar(255,255,255),
                    1.0, CV_AA);

        offs += image.cols + margin;
    }

    image.release();

    // display window
    std::string disp_title(argv[1]);
    cv::namedWindow(disp_title, cv::WINDOW_AUTOSIZE);
    cv::imshow(disp_title, win_mat);
    cv::imwrite(argv[3], win_mat);
    try {
        cv::waitKey(0);
        cv::destroyWindow(disp_title);
    } catch (cv::Exception const &e) {
        // demo window was closed externally
    }

    win_mat.release();

    return 0;
}

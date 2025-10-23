#include <print>
#include <format>

#include <vector>
#include <string>
#include <ranges>

#include <unordered_map>

#include <glaze/glaze.hpp>

struct mime_data
{
    std::vector<std::string> extensions;
};

static constexpr auto opts = glz::opts{.error_on_unknown_keys = false};
using mime_source          = std::unordered_map<std::string, mime_data>;

std::string emit(const mime_source::value_type &node)
{
    const auto &[name, data] = node;

    auto extensions = data.extensions                                                               //
                      | std::views::transform([](auto &item) { return std::format("[{}]", item); }) //
                      | std::views::join_with(' ')                                                  //
                      | std::ranges::to<std::string>();

    return std::format("{}: {}", name, extensions);
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        std::println(stderr, "Usage: {} <mime-source>", argv[0]);
        return 1;
    }

    auto parsed = mime_source{};

    if (auto err = glz::read_file_json<opts>(parsed, argv[1], std::string{}); err)
    {
        std::println("Failed to parse source: {}", std::error_code{err.ec}.message());
        return 1;
    }

    auto mimes = parsed                                                                                 //
                 | std::views::filter([](const auto &item) { return !item.second.extensions.empty(); }) //
                 | std::views::transform(emit);

    for (const auto &mime : mimes)
    {
        std::println("{}", mime);
    }

    return 0;
}

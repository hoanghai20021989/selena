#pragma once

#include <cstddef>
#include <cstdlib>
#include <memory>
#include <new>
#include <stdexcept>
#include <type_traits>

namespace engine::core {

/// Non-copyable, non-movable fixed-capacity container.
/// Suitable for types that cannot be relocated (mutexes, pools, etc.).
/// No reallocation. Throws if capacity exceeded.
template <typename T>
class fixed_vector
{
public:
    fixed_vector() = default;

    ~fixed_vector()
    {
        clear();
        if (data_)
        {
            std::free(data_);
        }
    }

    fixed_vector(const fixed_vector&) = delete;
    fixed_vector& operator=(const fixed_vector&) = delete;
    fixed_vector(fixed_vector&&) = delete;
    fixed_vector& operator=(fixed_vector&&) = delete;

    void reserve(size_t n)
    {
        if (data_)
        {
            throw std::logic_error("fixed_vector::reserve called twice");
        }
        capacity_ = n;
        data_ = static_cast<T*>(std::aligned_alloc(64, sizeof(T) * n));
        if (!data_)
        {
            throw std::bad_alloc();
        }
    }

    template <typename... Args>
    T& emplace_back(Args&&... args)
    {
        if (size_ >= capacity_)
        {
            throw std::length_error("fixed_vector capacity exceeded");
        }
        T* ptr = new (data_ + size_) T(std::forward<Args>(args)...);
        ++size_;
        return *ptr;
    }

    void pop_back()
    {
        if (size_ == 0)
        {
            throw std::out_of_range("fixed_vector::pop_back on empty container");
        }
        --size_;
        std::destroy_at(data_ + size_);
    }

    void clear()
    {
        for (size_t i = 0; i < size_; ++i)
        {
            std::destroy_at(data_ + i);
        }
        size_ = 0;
    }

    T& operator[](size_t i) { return data_[i]; }
    const T& operator[](size_t i) const { return data_[i]; }

    T& at(size_t i)
    {
        if (i >= size_)
        {
            throw std::out_of_range("fixed_vector::at");
        }
        return data_[i];
    }

    const T& at(size_t i) const
    {
        if (i >= size_)
        {
            throw std::out_of_range("fixed_vector::at");
        }
        return data_[i];
    }

    T& back() { return data_[size_ - 1]; }
    const T& back() const { return data_[size_ - 1]; }

    T* data() { return data_; }
    const T* data() const { return data_; }

    size_t size() const { return size_; }
    size_t capacity() const { return capacity_; }
    bool empty() const { return size_ == 0; }

    T* begin() { return data_; }
    T* end() { return data_ + size_; }
    const T* begin() const { return data_; }
    const T* end() const { return data_ + size_; }

private:
    T* data_{nullptr};
    size_t size_{0};
    size_t capacity_{0};
};

} // namespace engine::core

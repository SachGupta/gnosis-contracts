pragma solidity 0.4.11;


/// @title Arithmetic library
/// @author Alan Lu <alan.lu@gnosis.pm>
library Arithmetic {

    /*
     *  Public functions
     */
    /// @dev This function takes two unsigned 256-bit integers and multiplies them, returning a 512-bit result split
    ///      into a high 256-bit limb, a middle 128-bit limb, and a low 128-bit limb.
    /// @param a Factor A
    /// @param b Factor B
    /// @return ab32 High bits
    /// @return ab1 Middle bits
    /// @return ab0 Low bits
    function mul256By256(uint a, uint b)
        public
        constant
        returns (uint ab32, uint ab1, uint ab0)
    {
        uint ahi = a >> 128;
        uint alo = a & 2**128-1;
        uint bhi = b >> 128;
        uint blo = b & 2**128-1;
        ab0 = alo * blo;
        ab1 = (ab0 >> 128) + (ahi * blo & 2**128-1) + (alo * bhi & 2**128-1);
        ab32 = (ab1 >> 128) + ahi * bhi + (ahi * blo >> 128) + (alo * bhi >> 128);
        ab1 &= 2**128-1;
        ab0 &= 2**128-1;
    }

    /// @dev This function takes a unsigned 384-bit integer and divides it by a 256-bit integer, returning a high-bits
    ///      truncated 256-bit quotient and a remainder. The 384-bit dividend is represented as a high 256-bit limb and
    ///      a low 128-bit limb.
    /// @notice This code is adapted from Fast Division of Large Integers by Karl Hasselström Algorithm 3.4:
    ///         Divide-and-conquer division (3 by 2) Karl got it from Burnikel and Ziegler and the GMP lib implementation
    /// @param a21 High bits
    /// @param a0 Low bits
    /// @param b Divisor
    /// @return q Quotient
    /// @return r Remainder
    function div256_128By256(uint a21, uint a0, uint b)
        public
        constant
        returns (uint q, uint r)
    {
        uint qhi = (a21 / b) << 128;
        a21 %= b;
        uint shift = 0;
        while (b >> shift > 0)
            shift++;
        shift = 256 - shift;
        a21 = (a21 << shift) + (shift > 128 ? a0 << (shift - 128) : a0 >> (128 - shift));
        a0 = (a0 << shift) & 2**128-1;
        b <<= shift;
        var (b1, b0) = (b >> 128, b & 2**128-1);
        uint rhi;
        if (a21 >> 128 < b1) {
            q = a21 / b1;
            rhi = a21 % b1;
        }
        else {
            q = 2**128-1;
            rhi = a21 - (b1 << 128) + b1;
        }
        uint rsub0 = (q & 2**128-1) * b0;
        uint rsub21 = (q >> 128) * b0 + (rsub0 >> 128);
        rsub0 &= 2**128-1;
        while (rsub21 > rhi || rsub21 == rhi && rsub0 > a0) {
            q--;
            a0 += b0;
            rhi += b1 + (a0 >> 128);
            a0 &= 2**128-1;
        }
        q += qhi;
        r = (((rhi - rsub21) << 128) + a0 - rsub0) >> shift;
    }

    /// @dev This function returns a 256-bit truncated a * b / divisor, where the division is integer division.
    ///      The overflow from a * b is handled in a 512-bit buffer, so this method calculates the expression correctly
    ///      for high values of a and b.
    /// @param a Factor A
    /// @param b Factor B
    /// @param divisor Divisor
    /// @return Fraction
    function overflowResistantFraction(uint a, uint b, uint divisor)
        public
        constant
        returns (uint)
    {
        uint ab32_q1; uint ab1_r1; uint ab0;
        if (b <= 1 || b != 0 && a * b / b == a)
            return a * b / divisor;
        (ab32_q1, ab1_r1, ab0) = mul256By256(a, b);
        (ab32_q1, ab1_r1) = div256_128By256(ab32_q1, ab1_r1, divisor);
        (a, b) = div256_128By256(ab1_r1, ab0, divisor);
        return (ab32_q1 << 128) + a;
    }
}

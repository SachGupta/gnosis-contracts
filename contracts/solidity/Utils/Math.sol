pragma solidity 0.4.11;


/// @title Math library - Allows calculation of logarithmic and exponential functions.
/// @author Alan Lu - <alan.lu@gnosis.pm>
/// @author Stefan George - <stefan@gnosis.pm>
library Math {

    /*
     *  Constants
     */
    // This is equal to 1 in our calculations
    uint public constant ONE = 0x10000000000000000;

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

    /// @dev Returns natural exponential function value of given x.
    /// @param x X.
    /// @return Returns e**x.
    function exp(uint x)
        public
        constant
        returns (uint)
    {
        /* This is equivalent to ln(2) */
        uint ln2 = 0xb17217f7d1cf79ac;
        uint y = x * ONE / ln2;
        uint shift = 2**(y / ONE);
        uint z = y % ONE;
        uint zpow = z;
        uint result = ONE;
        result += 0xb172182739bc0e46 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x3d7f78a624cfb9b5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xe359bcfeb6e4531 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x27601df2fc048dc * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x5808a728816ee8 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x95dedef350bc9 * zpow / ONE;
        result += 0x16aee6e8ef;
        return shift * result;
    }

    /// @dev Returns natural logarithm value of given x.
    /// @param x X.
    /// @return Returns ln(x).
    function ln(uint x)
        public
        constant
        returns (uint)
    {
        uint log2e = 0x171547652b82fe177;
        // binary search for floor(log2(x))
        uint ilog2 = floorLog2(x);
        // lagrange interpolation for log2
        uint z = x / (2**ilog2);
        uint zpow = ONE;
        uint const = ONE * 10;
        uint result = const;
        result -= 0x443b9c5adb08cc45f * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0xf0a52590f17c71a3f * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x2478f22e787502b023 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x48c6de1480526b8d4c * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x70c18cae824656408c * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x883c81ec0ce7abebb2 * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x81814da94fe52ca9f5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x616361924625d1acf5 * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x39f9a16fb9292a608d * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x1b3049a5740b21d65f * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x9ee1408bd5ad96f3e * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x2c465c91703b7a7f4 * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x918d2d5f045a4d63 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x14ca095145f44f78 * zpow / ONE;
        zpow = zpow * z / ONE;
        result -= 0x1d806fc412c1b99 * zpow / ONE;
        zpow = zpow * z / ONE;
        result += 0x13950b4e1e89cc * zpow / ONE;
        return (ilog2 * ONE + result - const) * ONE / log2e;
    }

    /// @dev Returns base 2 logarithm value of given x.
    /// @param x X.
    /// @return Returns logarithmic value.
    function floorLog2(uint x)
        public
        constant
        returns (uint lo)
    {
        lo = 0;
        uint y = x / ONE;
        uint hi = 191;
        uint mid = (hi + lo) / 2;
        while ((lo + 1) != hi) {
            if (y < 2**mid)
                hi = mid;
            else
                lo = mid;
            mid = (hi + lo) / 2;
        }
    }

    /// @dev Returns if an add operation causes an overflow.
    /// @param a First addend.
    /// @param b Second addend.
    /// @return Did an overflow occur?
    function safeToAdd(uint a, uint b)
        public
        returns (bool)
    {
        return (a + b >= a);
    }

    /// @dev Returns if an subtraction operation causes an overflow.
    /// @param a Minuend.
    /// @param b Subtrahend.
    /// @return Did an overflow occur?
    function safeToSubtract(uint a, uint b)
        public
        returns (bool)
    {
        return (b <= a);
    }
}

import { validateAddress } from '../../../src/utils/validation';

describe('Validation Utils', () => {
  describe('validateAddress', () => {
    it('should return true for valid Ethereum addresses', () => {
      const validAddresses = [
        '0x1234567890123456789012345678901234567890',
        '0xabcdef0123456789abcdef0123456789abcdef01',
        '0x0000000000000000000000000000000000000000',
        '0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'
      ];

      validAddresses.forEach(address => {
        expect(validateAddress(address)).toBe(true);
      });
    });

    it('should return false for invalid Ethereum addresses', () => {
      const invalidAddresses = [
        '',
        'not an address',
        '0x123', // too short
        '0x12345678901234567890123456789012345678901', // too long
        '0xghijklmnopqrstuvwxyz1234567890123456789', // invalid characters
        '1234567890123456789012345678901234567890', // missing 0x prefix
        '0x123456789012345678901234567890123456789', // too short
        '0x12345678901234567890123456789012345678901234', // too long
        '0xG234567890123456789012345678901234567890', // invalid hex
        null as any,
        undefined as any,
        123 as any,
        {} as any,
        [] as any,
        true as any,
        false as any,
        (() => {}) as any,
        Symbol('test') as any
      ];

      invalidAddresses.forEach(address => {
        expect(validateAddress(address)).toBe(false);
      });
    });

    it('should handle checksummed addresses', () => {
      const checksummedAddresses = [
        '0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed',
        '0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359',
        '0x52908400098527886E0F7030069857D2E4169EE7',
        '0x8617E340B3D01FA5F11F306F4090FD50E238070D'
      ];

      checksummedAddresses.forEach(address => {
        expect(validateAddress(address)).toBe(true);
      });
    });

    it('should handle lowercase addresses', () => {
      const lowercaseAddresses = [
        '0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed',
        '0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359',
        '0x52908400098527886e0f7030069857d2e4169ee7',
        '0x8617e340b3d01fa5f11f306f4090fd50e238070d'
      ];

      lowercaseAddresses.forEach(address => {
        expect(validateAddress(address)).toBe(true);
      });
    });

    it('should handle mixed case addresses that are invalid checksums', () => {
      const invalidChecksumAddresses = [
        '0x5AAeb6053F3E94C9b9A09f33669435E7Ef1BeAed', // modified first character
        '0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d350', // modified last character
        '0x52908400098527886E0F7030069857D2E4169Ee7', // swapped case
        '0x8617e340B3D01FA5F11F306F4090FD50E238070d' // mixed case
      ];

      invalidChecksumAddresses.forEach(address => {
        expect(validateAddress(address)).toBe(false);
      });
    });

    it('should handle edge cases with special characters', () => {
      const edgeCases = [
        '0x1234567890123456789012345678901234567890\n', // newline
        '0x1234567890123456789012345678901234567890\t', // tab
        '0x1234567890123456789012345678901234567890 ', // space
        ' 0x1234567890123456789012345678901234567890', // leading space
        '\u00000x1234567890123456789012345678901234567890', // null character
        '0x1234567890123456789012345678901234567890\u0000' // null character
      ];

      edgeCases.forEach(address => {
        expect(validateAddress(address)).toBe(false);
      });
    });

    it('should handle addresses with invalid prefixes', () => {
      const invalidPrefixes = [
        '0X1234567890123456789012345678901234567890', // capital X
        '0b1234567890123456789012345678901234567890', // binary prefix
        '0o1234567890123456789012345678901234567890', // octal prefix
        'x01234567890123456789012345678901234567890', // missing 0
        '001234567890123456789012345678901234567890', // wrong prefix
        '#0x1234567890123456789012345678901234567890' // extra character
      ];

      invalidPrefixes.forEach(address => {
        expect(validateAddress(address)).toBe(false);
      });
    });
  });
}); 
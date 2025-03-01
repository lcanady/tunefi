import { isAddress } from '@ethersproject/address';

/**
 * Validates an Ethereum address format
 * @param address The address to validate
 * @returns boolean indicating if the address is valid
 */
export const validateAddress = (address: string | null | undefined): boolean => {
  if (!address || typeof address !== 'string') {
    return false;
  }
  
  // Basic format check
  if (!/^0x[0-9a-fA-F]{40}$/.test(address)) {
    return false;
  }

  try {
    return isAddress(address);
  } catch {
    return false;
  }
}; 
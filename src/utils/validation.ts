import { getAddress } from '@ethersproject/address';

/**
 * Validates an Ethereum address format
 * @param address The address to validate
 * @returns boolean indicating if the address is valid
 */
export function validateAddress(address: string): boolean {
  try {
    // getAddress will throw if the address is invalid
    getAddress(address);
    return true;
  } catch {
    return false;
  }
}

/**
 * Validates a transaction hash
 * @param hash The transaction hash to validate
 * @returns true if the hash is valid, false otherwise
 */
export function validateTransactionHash(hash: string): boolean {
  return /^0x[a-fA-F0-9]{64}$/.test(hash);
}

/**
 * Validates a block hash
 * @param hash The block hash to validate
 * @returns true if the hash is valid, false otherwise
 */
export function validateBlockHash(hash: string): boolean {
  return /^0x[a-fA-F0-9]{64}$/.test(hash);
}

/**
 * Validates a network name
 * @param network The network name to validate
 * @returns true if the network is valid, false otherwise
 */
export function validateNetwork(network: string): boolean {
  const validNetworks = ['ethereum', 'polygon', 'arbitrum', 'optimism', 'base'];
  return validNetworks.includes(network.toLowerCase());
}

/**
 * Validates a contract type
 * @param type The contract type to validate
 * @returns true if the type is valid, false otherwise
 */
export function validateContractType(type: string): boolean {
  return ['ERC721', 'ERC1155'].includes(type);
} 
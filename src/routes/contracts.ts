import express from 'express';
import { Contract, ContractType } from '../models/Contract';
import { validateAddress } from '../utils/validation';

const router = express.Router();

// Create a new contract
router.post('/', async (req, res, next) => {
  try {
    const { address, type, network, name, symbol, startBlock } = req.body;

    if (!validateAddress(address)) {
      return res.status(400).json({ error: 'Invalid Ethereum address' });
    }

    if (!Object.values(ContractType).includes(type)) {
      return res.status(400).json({ error: 'Invalid contract type. Must be ERC721 or ERC1155' });
    }

    const existingContract = await Contract.findOne({
      address: address.toLowerCase(),
      network
    });

    if (existingContract) {
      return res.status(409).json({ error: 'Contract already exists' });
    }

    const contract = await Contract.create({
      address,
      type,
      network,
      name,
      symbol,
      startBlock,
      deployedAt: new Date()
    });

    res.status(201).json(contract);
  } catch (error) {
    next(error);
  }
});

// Get all contracts with optional filters
router.get('/', async (req, res, next) => {
  try {
    const { network, type } = req.query;
    const filter: any = {};

    if (network) filter.network = network;
    if (type) filter.type = type;

    const contracts = await Contract.find(filter);
    res.json(contracts);
  } catch (error) {
    next(error);
  }
});

// Get a specific contract by address
router.get('/:address', async (req, res, next) => {
  try {
    const { address } = req.params;

    if (!validateAddress(address)) {
      return res.status(400).json({ error: 'Invalid Ethereum address' });
    }

    const contract = await Contract.findOne({
      address: address.toLowerCase()
    });

    if (!contract) {
      return res.status(404).json({ error: 'Contract not found' });
    }

    res.json(contract);
  } catch (error) {
    next(error);
  }
});

// Update a contract
router.patch('/:address', async (req, res, next) => {
  try {
    const { address } = req.params;
    const updates = req.body;

    if (!validateAddress(address)) {
      return res.status(400).json({ error: 'Invalid Ethereum address' });
    }

    // Prevent updating critical fields
    delete updates.address;
    delete updates.type;
    delete updates.network;

    const contract = await Contract.findOneAndUpdate(
      { address: address.toLowerCase() },
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!contract) {
      return res.status(404).json({ error: 'Contract not found' });
    }

    res.json(contract);
  } catch (error) {
    next(error);
  }
});

// Delete a contract
router.delete('/:address', async (req, res, next) => {
  try {
    const { address } = req.params;

    if (!validateAddress(address)) {
      return res.status(400).json({ error: 'Invalid Ethereum address' });
    }

    const contract = await Contract.findOneAndDelete({
      address: address.toLowerCase()
    });

    if (!contract) {
      return res.status(404).json({ error: 'Contract not found' });
    }

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router; 
export interface ContractConfig {
  og: {
    owner: string,
    name: string,
    symbol: string,
  }
  auction: {
    owner: string,
    og: string,
  }
}

export enum network {
  bnb_mainnet = 'bnb_mainnet',
  bnb_testnet = 'bnb_testnet',
}
import {ContractConfig} from "./types";

export const bnbTestnetConfig: ContractConfig = {
  og: {
    owner: '0x4Eb6b2cbC3Ad6E4a0156245F9e8880fAAaEfa394',
    name: 'OG SPACESHIP',
    symbol: 'OGS'
  },
  auction: {
    owner: '0x1c45d8f61617D5fE87Ae85A7C045e4f2aAa9102e',
    og: '0x8E0DdeB773BB0734a98ECE12aE3f0Aa5d2fB1aE5',
  }
}

export const bnbMainnetConfig: ContractConfig = {
  og: {
    owner: '0x1c45d8f61617D5fE87Ae85A7C045e4f2aAa9102e',
    name: '0x322C2af3b801714cbDcc24622A3e8A8AeFdC0f9A',
    symbol: ''
  },
  auction: {
    owner: '0xF52738a1Dc7C5f70335680D3D7139b2B8fa5650E',
    og: '0xF52738a1Dc7C5f70335680D3D7139b2B8fa5650E',
  }
}

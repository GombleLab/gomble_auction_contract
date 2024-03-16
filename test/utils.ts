import { ethers } from "hardhat";
import {AbiCoder} from "ethers";

export async function advanceTimeAndBlock(time: number) {
  await advanceTime(time);
  await advanceBlock();
}

export async function advanceTime(time: number) {
  await ethers.provider.send("evm_increaseTime", [time]);
}

export async function advanceBlock(count = 1) {
  for (let i = 0; i < count; i++) {
    await ethers.provider.send("evm_mine", []);
  }
}

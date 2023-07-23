import { Injectable } from '@angular/core';
import Web3 from "web3";

declare const window: any;
const address = '0xA11e73F851C12d8d25a7b88a6121AD365De1838c';
const abi = [{
  "inputs": [
    {
      "internalType": "uint256",
      "name": "startDate",
      "type": "uint256"
    },
    {
      "internalType": "uint256",
      "name": "amount",
      "type": "uint256"
    }
  ],
  "name": "startChallenge",
  "outputs": [],
  "stateMutability": "payable",
  "type": "function"
}]

@Injectable({
  providedIn: 'root'
})
export class ContractService {

  web3js: any;
  provider: any;
  accounts: any;
  uDonate: any;
  

  window:any;
  constructor() { }

  public startChallenge = async () => {
  
          const contract = new window.web3.eth.Contract(
                abi,
                address,);
                const startChallenge = await contract.methods.startChallenge().call();
                return startChallenge;
  }
}

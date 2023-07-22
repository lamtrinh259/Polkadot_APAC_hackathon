import { Component, OnInit } from '@angular/core';
// for navigating to other routes
import { Router } from '@angular/router';

// for making HTTP requests
import axios from 'axios';

import { getDefaultProvider } from 'ethers';

import {
  createClient,
  connect,
  disconnect,
  getAccount,
  signMessage,
  InjectedConnector,
} from '@wagmi/core';

const client = createClient({
  autoConnect: true,
  provider: getDefaultProvider(),
});


import { environment } from '../../../environments/environment';
@Component({
  selector: 'app-signin',
  templateUrl: './signin.component.html',
  styleUrls: ['./signin.component.css']
})
export class SigninComponent implements OnInit {

  constructor(private router: Router) { }

  ngOnInit(): void {}

  async handleAuth() {
    const { isConnected } = getAccount();

    if (isConnected) await disconnect(); //disconnects the web3 provider if it's already active

    const provider = await connect({ connector: new InjectedConnector() }); // enabling the web3 provider metamask

    const userData = {
      address: provider.account,
      chain: provider.chain.id,
      network: 'evm',
    };

    const { data } = await axios.post(
      `${environment.SERVER_URL}/request-message`,
      userData
    );

    const message = data.message;

    const signature = await signMessage({ message });

    await axios.post(
      `${environment.SERVER_URL}/verify`,
      {
        message,
        signature,
      },
      { withCredentials: true } // set cookie from Express server
    );

    console.log('login successful');

    // redirect to /user
    this.router.navigateByUrl('/user');
  }
}

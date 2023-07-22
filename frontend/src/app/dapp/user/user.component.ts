import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

import axios from 'axios';

import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-user',
  templateUrl: './user.component.html',
  styleUrls: ['./user.component.css']
})
export class UserComponent implements OnInit {

  constructor(private router: Router) { }

  session = '';

  async ngOnInit() {
    try {
      const { data } = await axios.get(
        `${environment.SERVER_URL}/authenticate`,
        {
          withCredentials: true,
        }
      );
  
      const { iat, ...authData } = data; // remove unimportant iat value
  
      this.session = JSON.stringify(authData, null, 2); // format to be displayed nicely
    } catch (err) {
      // if user does not have a "session" token, redirect to /signin
      this.router.navigateByUrl('/signin');
    }
  }  
  async signOut() {
    await axios.get(`${environment.SERVER_URL}/logout`, {
      withCredentials: true,
    });
    this.router.navigateByUrl('/signin');
  }}

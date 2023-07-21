import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-dapp-main-page',
  templateUrl: './dapp-main-page.component.html',
  styleUrls: ['./dapp-main-page.component.css']
})
export class DappMainPageComponent implements OnInit {

  constructor(private router: Router) { }

  ngOnInit(): void {
  }

  gotTo(route: string) {
    this.router.navigate([route])
  }
}

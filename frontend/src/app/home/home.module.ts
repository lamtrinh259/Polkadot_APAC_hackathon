import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HomeComponent } from './home.component';
import { NavComponent } from './nav/nav.component';
import { HowTheAppFunctionsComponent } from './how-the-app-functions/how-the-app-functions.component';
import { CurrentPledgesComponent } from './current-pledges/current-pledges.component';
import { RouterModule, Routes } from '@angular/router';
import { FAQComponent } from './faq/faq.component';
import { FooterComponent } from './footer/footer.component';

const routes: Routes = [
  {
    path: '',
    component: HomeComponent,
  },

  {
    path: 'how-the-app-functions',
    component: HowTheAppFunctionsComponent,
  },

  {
    path: 'current-pledges',
    component: CurrentPledgesComponent,
  },

  {
    path: 'faq',
    component: FAQComponent,
  },

  {
    path: 'footer',
    component: FooterComponent,
  }
];

@NgModule({
  declarations: [
    HomeComponent,
    NavComponent, 
    HowTheAppFunctionsComponent,
    CurrentPledgesComponent,
    FAQComponent,
    FooterComponent
  ],
  imports: [
    CommonModule, RouterModule.forChild(routes)
  ]
})
export class HomeModule { }

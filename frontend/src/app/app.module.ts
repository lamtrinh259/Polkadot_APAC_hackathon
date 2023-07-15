import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NavComponent } from './nav/nav.component';
import { HowTheAppFunctionsComponent } from './how-the-app-functions/how-the-app-functions.component';
import { CurrentPledgesComponent } from './current-pledges/current-pledges.component';
import { FAQComponent } from './faq/faq.component';
import { FooterComponent } from './footer/footer.component';

@NgModule({
  declarations: [
    AppComponent,
    NavComponent,
    HowTheAppFunctionsComponent,
    CurrentPledgesComponent,
    FAQComponent,
    FooterComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }

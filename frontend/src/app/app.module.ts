import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { NavComponent } from './nav/nav.component';
import { HowTheAppFunctionsComponent } from './how-the-app-functions/how-the-app-functions.component';

@NgModule({
  declarations: [
    AppComponent,
    NavComponent,
    HowTheAppFunctionsComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }

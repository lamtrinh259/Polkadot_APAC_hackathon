import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DappMainPageComponent } from './dapp-main-page/dapp-main-page.component';
import { NavDappComponent } from './nav-dapp/nav-dapp.component';
import { RouterModule, Routes } from '@angular/router';
import { LeaderboardComponent } from './leaderboard/leaderboard.component';
import { ModalWalletComponent } from './modal-wallet/modal-wallet.component';
import { WelcomeComponent } from './welcome/welcome.component';
import { CreateNewChallengeComponent } from './create-new-challenge/create-new-challenge.component';
import { ChallengeConfirmationComponent } from './challenge-confirmation/challenge-confirmation.component';
import { CongratsOnCheckinComponent } from './congrats-on-checkin/congrats-on-checkin.component';
import { CongratsOnTakingfirststepComponent } from './congrats-on-takingfirststep/congrats-on-takingfirststep.component';
import { BalancesComponent } from './balances/balances.component';
import { SigninComponent } from './signin/signin.component';
import { UserComponent } from './user/user.component';

const routes: Routes = [
  {
    path: '',
    component: DappMainPageComponent,
  },
  {
    path: 'wallet',
    component: ModalWalletComponent,
  },

  {
    path: 'welcome',
    component: WelcomeComponent,
  },
  {
    path: 'congrats-on-checkin',
    component: CongratsOnCheckinComponent,
  },
  {
    path: 'congrats-on-takingfirststep',
    component: CongratsOnTakingfirststepComponent,
  },
  {
    path: 'create',
    component: CreateNewChallengeComponent,
  },

  { 
    path: 'signin', 
  component: SigninComponent 
  },

  { 
    path: 'balances', 
  component: BalancesComponent 
  },

  { 
    path: 'user', 
  component: UserComponent 
  }

];


@NgModule({
  declarations: [
    DappMainPageComponent,
    NavDappComponent,
    LeaderboardComponent,
    ModalWalletComponent,
    WelcomeComponent,
    CreateNewChallengeComponent,
    ChallengeConfirmationComponent,
    CongratsOnCheckinComponent,
    CongratsOnTakingfirststepComponent,
    BalancesComponent,
    SigninComponent,
    UserComponent
  ],
  imports: [
    CommonModule, RouterModule.forChild(routes)
  ]
})
export class DappModule { }

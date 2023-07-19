import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DappMainPageComponent } from './dapp-main-page/dapp-main-page.component';
import { NavDappComponent } from './nav-dapp/nav-dapp.component';
import { RouterModule, Routes } from '@angular/router';
import { LeaderboardComponent } from './leaderboard/leaderboard.component';
import { ModalWalletComponent } from './modal-wallet/modal-wallet.component';
import { WelcomeComponent } from './welcome/welcome.component';
import { CongratulationsComponent } from './congratulations/congratulations.component';
import { CreateNewChallengeComponent } from './create-new-challenge/create-new-challenge.component';
import { ChallengeConfirmationComponent } from './challenge-confirmation/challenge-confirmation.component';

const routes: Routes = [
  {
    path: '',
    component: DappMainPageComponent,
  },

  {
    path: 'wallet',
    component: ModalWalletComponent,
  }
];


@NgModule({
  declarations: [
    DappMainPageComponent,
    NavDappComponent,
    LeaderboardComponent,
    ModalWalletComponent,
    WelcomeComponent,
    CongratulationsComponent,
    CreateNewChallengeComponent,
    ChallengeConfirmationComponent
  ],
  imports: [
    CommonModule, RouterModule.forChild(routes)
  ]
})
export class DappModule { }

import { Component } from '@angular/core';

@Component({
  selector: 'app-faq',
  templateUrl: './faq.component.html',
  styleUrls: ['./faq.component.css']
})
export class FAQComponent {

  questions = [
    {
      title: 'Q: Does it cost money/crypto to participate?',
      answer: 'Ans: We want people to take their goal seriously, so we set a minimum of 5 USDC per challenge/goal in order to motivate them to perform the habit daily thanks to the psychology of loss aversion. If user successfully checks in everyday throughout the whole challenge period , the full pledge amount will be returned to them and user will also be eligible for monthly prize drawing! Users who want to try out the app for free can also use the app on testnet.',
      showAnswer: false
    },
    {
      title: 'Q: Can I pledge with other crypto or fiat?',
      answer: 'Ans: We will add other crypto (USDT, WETH, etc.) in the near future. Regarding fiat, unfortunately, it is not possible at the moment, we will consider implementing the on-ramp (buying crypto with fiat) option in the future if there is a lot of demand.',
      showAnswer: false
    },
    {
      title: 'Q: Can I customize the challenge/goal duration to suit my goal?',
      answer: 'Ans: At the moment, we only allow people to sign up for 21-day challenge/goal. In the future, we will add other durations and may even allow people to customize their own challenge duration, as long as it is a 21-day minimum since we believe that habit needs to be formed over time and anything less than 21-day will not be effective in forming a habit long-term.',
      showAnswer: false
    },
    {
      title: 'Q: Can I challenge the check-in frequency (once/week, or 3x/week)?',
      answer: 'Ans: We will add the feature if we have a lot of requests in the future. Please connect with us on our social media and share with us your goal and the respective frequency.',
      showAnswer: false
    }
  ];

  toggleAnswer(question: any) {
    question.showAnswer = !question.showAnswer;
  }
}







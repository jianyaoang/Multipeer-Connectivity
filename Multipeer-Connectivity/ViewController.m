//
//  ViewController.m
//  Multipeer-Connectivity
//
//  Created by Jian Yao Ang on 7/6/14.
//  Copyright (c) 2014 Jian Yao Ang. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (nonatomic) int secretNumber;
@property (nonatomic) BOOL hasCreatedGame;
@property (nonatomic) BOOL isGameRunning;
@property (strong, nonatomic) IBOutlet UITextField *guessTextField;
@property (strong, nonatomic) IBOutlet UITextView *textViewHistory;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [self toggleSubviewsState:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReceiveDataWithNotification:) name:@"MPC_didChangeState" object:nil];
}

- (IBAction)onStartGameButtonPressed:(id)sender
{
    if (!self.isGameRunning)
    {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Multipeer Connectivity" message:@"Please enter a number between 1 to 10" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Start Game", nil];
        //UIAlertViewStylePlainTextInput adds text field to alertView
        av.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[av textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
        [av show];
    }
    
    //check if input number is 1-10
    if (self.secretNumber >=1 && self.secretNumber <= 10)
    {
        //message players that a new game has started
        //convert the text input into NSData and send it
        NSString *messageToSend = @"New Game";
        NSData *messageAsData = [messageToSend dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        
        //withMode: reliable / unreliable 
        [self.appDelegate.mpcHandler.session sendData:messageAsData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
        
        if (error)
        {
            NSLog(@"%@", [error localizedDescription]);
        }
        else
        {
            self.hasCreatedGame = YES;
            self.isGameRunning = YES;
            
            [self.textViewHistory setText:@""];
        }
    }
    else
    {
        //if user enters number not 1-10
        UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Multipeer Connectivity" message:@"Please enter a number between 1 to 10" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [av show];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //check if player press on Start Game and the style of UIAlertView
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput && buttonIndex == 1)
    {
        UITextField *textField = [alertView textFieldAtIndex:0];
        self.secretNumber = [textField.text intValue];
    }
    else
    {
        //obtain the button's title as answer, change it to NSData, send it to other players
        NSString *selectedAnswer = [alertView buttonTitleAtIndex:buttonIndex];
        NSData *answerData = [selectedAnswer dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        [self.appDelegate.mpcHandler.session sendData:answerData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    
        if (error != nil)
        {
            NSLog(@"clicked button index error:%@", [error localizedDescription]);
        }
        
        //if the answer is correct
        if (buttonIndex == 0)
        {
            self.hasCreatedGame = NO;
            self.isGameRunning = NO;
        }
    }
}

- (IBAction)onSendButtonPressed:(id)sender
{
   //check whether the input is valid or not
    if (self.guessTextField.text.length == 0 || [self.guessTextField.text intValue] < 1 || [self.guessTextField.text intValue] > 10)
    {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Multipeer Connectivity" message:@"Please insert a number from 1-10" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [av show];
    }
    else
    {
        //convert string into data and send
        NSData *guessData = [self.guessTextField.text dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        [self.appDelegate.mpcHandler.session sendData:guessData toPeers:self.appDelegate.mpcHandler.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    
        if (error != nil)
        {
            NSLog(@"sendButtonPressed error:%@", [error localizedDescription]);
        }
        
        //add the number to history text view
        NSString *history = [NSString stringWithFormat:@"Number that have been guessed: %@\n\n", self.guessTextField.text];
        [self.textViewHistory setText:[history stringByAppendingString:self.textViewHistory.text]];
    }
    self.guessTextField.text = @"";
    [self.guessTextField resignFirstResponder];
}

- (IBAction)onCancelButtonPressed:(id)sender
{
    [self.guessTextField resignFirstResponder];
}

-(void)toggleSubviewsState:(BOOL)shouldEnable
{
    self.cancelButton.enabled = shouldEnable;
    self.guessTextField.enabled = shouldEnable;
    self.sendButton.enabled = shouldEnable;
}

-(void)handleReceiveDataWithNotification:(NSNotification*)notification
{
    NSDictionary *userInfoDict = [notification userInfo];
    
    //convert data into NSString object
    NSData *receivedData = [userInfoDict objectForKey:@"data"];
    NSString *message = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    
    //Keep the sender's peerID and obtain its display name
    MCPeerID *senderPeerID = [userInfoDict objectForKey:@"peerID"];
    NSString *senderDisplayName = senderPeerID.displayName;

    if ([message isEqualToString:@"New Game"])
    {
        //check to see if message is regarding a new game, if it is, display that the sender started a new game
        NSString *alertMessage = [NSString stringWithFormat:@"%@ has started a new game.",senderDisplayName];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Multipeer Connectivity" message:alertMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Okay", nil];
        [av show];
        
        self.isGameRunning = YES;
        
        //enable subviews
        [self toggleSubviewsState:YES];
        
        //remove previous history text
        [self.textViewHistory setText:@""];
    }
    else
    {
        //check if the message only contains digits.
        NSCharacterSet *numbersSet = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet *messageSet = [NSCharacterSet characterSetWithCharactersInString:message];
        
        if ([numbersSet isSupersetOfSet:messageSet])
        {
            //convert the guess message from another user into number
            int guess = [message intValue];
            
            NSString *history = [NSString stringWithFormat:@"%@ has guessed %d",senderDisplayName, guess];
            [self.textViewHistory setText:[history stringByAppendingString:self.textViewHistory.text]];
            
            if (self.hasCreatedGame)
            {
                NSString *optionsMessage = [NSString stringWithFormat:@"%@\n\nThe secret number is %d.\n\nWhat's your answer?", history, self.secretNumber];
                UIAlertView *optionsAlert = [[UIAlertView alloc] initWithTitle:@"Multipeer Connectivity" message:optionsMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Correct!",@"Give a greater number",@"Give a lower number" , nil];
                [optionsAlert show];
            }
        }
        else
        {
            NSString *history = [NSString stringWithFormat:@"%@ says:\n%@\n\n",senderDisplayName,message];
            [self.textViewHistory setText:[history stringByAppendingString:self.textViewHistory.text]];
            
            if ([message isEqualToString:@"Correct!"])
            {
                self.isGameRunning = NO;
                [self toggleSubviewsState:NO];
            }
        }
    
    }
}



@end

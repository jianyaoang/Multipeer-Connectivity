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
}

- (IBAction)onSendButtonPressed:(id)sender
{
    
}

- (IBAction)onCancelButtonPressed:(id)sender
{
    
}

-(void)toggleSubviewsState:(BOOL)shouldEnable
{
    self.cancelButton.enabled = shouldEnable;
    self.guessTextField.enabled = shouldEnable;
    self.sendButton.enabled = shouldEnable;
}



@end
